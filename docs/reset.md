# Reset — returning to a known state

Different from [recovery.md](recovery.md): nothing is lost here, something is
just *wrong* or stale. Start at the top and stop as soon as it works.

## Soft reset — re-establish the machine-local state

Nothing in git changes. This fixes the majority of "it worked yesterday"
problems, and is **always safe to run**.

```bash
cd ~/Projects/workdesk
mise trust                  # mise trust is keyed to the config's PATH
mise install                # reinstall pinned tools
lefthook install            # reinstall git hooks

for d in repos/*/; do
  ( cd "$d" && mise trust && mise install && lefthook install )
done

mise run backup:install     # rewrite + re-enable the systemd units
```

### What it fixes

| symptom | cause |
| ------- | ----- |
| `Config files in … are not trusted` | the repo moved; trust is path-keyed |
| Commits skip the Conventional Commits check | hooks not installed in that clone |
| `command not found` for restic/copier/lefthook | mise not activated, or tools not installed |
| Backup hasn't run since a move | the unit's `WorkingDirectory` is stale |
| `sops` can't decrypt | `mise settings get sops.age_key_file` points nowhere |
| `git.jonnxor.is` refuses connections from this machine | the split-DNS pieces are missing — see below |

### If it's the DNS one

Machine-local, not in git, and easy to lose on a reinstall:

```bash
grep git.jonnxor.is /etc/hosts            # should pin it to 192.168.50.33
cat /etc/systemd/resolved.conf.d/no-fallback.conf   # should set FallbackDNS=
```

Both are needed and both are explained in `repos/servers/dns.md`. Test what
SSH actually resolves, not what `getent` says — they can disagree:

```bash
python3 -c "import socket;print(socket.getaddrinfo('git.jonnxor.is',2222)[0][4][0])"
```

### Verify

```bash
mise run backup:snapshots                 # both repositories respond
mise run backup:verify                    # backup is provably restorable
cd repos/servers && mise run lint         # units generate
```

## Medium reset — the backup pipeline only

When backups are misbehaving but nothing is lost.

```bash
cd ~/Projects/workdesk

systemctl --user disable --now restic-backup.timer
rm ~/.config/systemd/user/restic-backup.{service,timer}
systemctl --user daemon-reload

mise run backup:install
systemctl --user start restic-backup.service
journalctl --user -u restic-backup.service -n 30
```

If a repository itself is suspect:

```bash
mise run backup:check      # slow; verifies stored data reconstructs
```

If `check` reports damage, do **not** delete the repository — restic can often
repair. Start with `restic repair index`, then `restic repair snapshots`, and
only rebuild from scratch if those fail. The other repository is your safety
net while you work on the broken one.

## Hard reset — throw the machine state away

Only when the local state is beyond untangling. **Everything committed and
pushed survives; anything else does not.** Check first:

```bash
cd ~/Projects/workdesk
git status --short                       # desk
for d in repos/*/; do echo "== $d"; git -C "$d" status --short; done
for d in repos/*/; do echo "== $d"; git -C "$d" log --branches --not --remotes --oneline; done
```

The last command lists commits that exist **only on this machine**. If it
prints anything, push it or accept losing it. With no remotes configured yet,
*everything* is only on this machine — so take a snapshot before continuing:

```bash
mise run backup
```

Then:

```bash
cd ~
mv Projects/workdesk Projects/workdesk.old      # move aside, never delete first
```

Re-clone or restore per [onboarding.md](onboarding.md) / [recovery.md](recovery.md),
verify it works, and only then remove `workdesk.old`.

## Factory reset — a project back to template defaults

To discard local changes to template-managed files in one project:

```bash
cd repos/myapp
git status --short          # commit or stash anything you want to keep
copier recopy --trust       # re-render the template with your recorded answers
git diff                    # review everything it changed
```

`recopy` overwrites template files (except `README.md` and `.env.enc.yaml`,
which are `_skip_if_exists`). Your source code is untouched — the template only
owns the scaffolding.

## What a reset never touches

- `~/.config/sops/age/keys.txt` — the age key. Losing it is
  [recovery](recovery.md), not reset.
- `~/Backups/restic` and the B2 repository — resetting the desk does not touch
  the backups.
- Bitwarden.
- The server. Resetting your laptop changes nothing about the box; redeploying
  is [operations.md](operations.md).
