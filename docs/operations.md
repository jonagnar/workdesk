# Operations — running the thing

Day-to-day procedures. Commands live in [CHEATSHEET.md](../CHEATSHEET.md);
this is the *how and why* for tasks you do rarely enough to forget.

## Start a new project

```bash
cd ~/Projects/workdesk
mise run new -- repos/myapp
```

Copier asks the toggles. Guidance:

| answer | pick |
| ------ | ---- |
| `kind` | `app` if it builds a deployable artifact, `library` if published, `servers` if it runs things |
| `language` | drives tool pins and what `fmt`/`lint`/`test` actually run |
| `use_sops` | yes unless you're certain there will never be a secret |
| `use_podman` | only if it needs containers for *local development* |
| `use_database` | adds Postgres to the local compose file |

Afterwards:

```bash
cd repos/myapp && mise install && mise run test
```

The project is standalone from this moment. It will keep working if the desk
is deleted.

## Pull template improvements into an existing project

Never automatic. When you've improved the template and want an existing
project to catch up:

```bash
cd repos/myapp
copier update --trust
git diff        # review before committing — it can touch several files
```

`README.md` and `.env.enc.yaml` are never overwritten (`_skip_if_exists`).

**Caveat:** `.copier-answers.yml` records `_src_path` as an absolute path on
this machine. If the desk moves, update that line or `copier update` fails.
Once the desk has a remote, changing it to a git URL makes updates work from
anywhere.

## Add or change a secret

```bash
cd repos/myapp
sops edit .env.enc.yaml      # EDITOR=nano if you don't want vim
```

mise injects the values into the environment for tasks in that project. Never
paste a secret into a tracked file, a commit message, or a chat.

## Give the server access to a secret

Production secrets must decrypt on the box without your personal key ever
being there. Add the box's public key as a second recipient:

1. On the box: `age-keygen -o ~/.config/sops/age/keys.txt` (once), then
   `age-keygen -y ~/.config/sops/age/keys.txt` to read its public half.
2. In the repo's `.sops.yaml`, add it to the `age:` list, comma-separated.
3. Re-encrypt existing files to the new recipient list:

```bash
sops updatekeys .env.enc.yaml
```

Both keys can now decrypt. Removing a recipient works the same way, but
anything already leaked stays leaked — rotate the secret itself if it may have
been exposed.

## Deploy a service

```bash
cd repos/servers
mise run lint                 # generator dry-run — always do this first
mise run deploy -- hades
```

`deploy` rsyncs `hosts/hades/quadlet/` into `~/.config/containers/systemd/`
(with `--delete`, so removing a unit here removes it there), then
`daemon-reload` + `restart`. Because the host directory name matches this
machine's hostname, it installs locally; any other name is treated as an SSH
alias and deployed over the network.

## Release a new version of a service

1. Change `Image=…:<new tag>` in the `.container` file.
2. Commit (`feat:` or `chore:`).
3. `mise run deploy -- hades`.

Rollback is the same three steps with the old tag, and volumes survive
redeploys. **Exception:** Forgejo migrates its database on start across major
versions and migrations do not reverse — take a dump and read the release
notes first.

## Add a service to a host

1. Write `hosts/hades/quadlet/<name>.container` (plus `.volume` files if it
   needs storage — an empty `[Volume]` section is enough).
2. **Publish it to `127.0.0.1:<port>` only**, and put it on the `services`
   network so Caddy can reach it by container name. Don't publish a service's
   own port to `0.0.0.0` — Caddy should be the only thing listening publicly,
   so TLS and access control stay in one place.
3. Add a block to `hosts/hades/caddy/Caddyfile` if it should be reachable:

   ```
   name.jonnxor.is {
   	reverse_proxy <container-name>:<port>
   }
   ```

4. Add a DNS record at ISNIC for the subdomain — a `CNAME` to the router's
   DDNS name, matching how `git` is done. See `repos/servers/dns.md`.
5. `mise run lint`, then deploy.

Three firewalls have to agree before anything is reachable from outside: the
MikroTik dstnat rules, `ufw` on this machine, and nothing else holding the
port. 80 and 443 are already forwarded and allowed, so a service behind Caddy
needs no new firewall work — only one published directly would.

## Add a new host

Copy `hosts/hades/` to `hosts/<name>/`, adjust the units, add a matching `Host
<name>` block to `~/.ssh/config`, and `mise run deploy -- <name>`. The
directory name and the SSH alias must match — that's the whole host registry.

## Backups

Two timers run on their own: `restic-backup.timer` nightly at 03:00, and
`restic-verify.timer` monthly, which proves the backup is actually restorable
and raises a desktop notification if it isn't. Both use `Persistent=true`, so
they catch up after downtime rather than silently skipping.

You don't need to remember to test the backup — that's the verify timer's job.
Things still worth doing by hand:

```bash
mise run backup              # before anything irreversible
mise run backup:snapshots    # after any big change
mise run backup:verify       # same check the monthly timer runs
mise run backup:check        # full integrity — slow, occasional
```

`mise run backup` by hand matters more than it looks: anything pushed to
Forgejo between the nightly dump and a failure exists only in your local
clones. The rehearsal in [recovery.md](recovery.md#5-forgejo) hit exactly
that — 19 commits in the restored instance against 22 live.

**Change what's backed up** by editing `backup/include.txt`. Because it lists
the whole desk, new projects are covered automatically — you only edit it to
add something *outside* `~/Projects/workdesk`.

If you add a path, re-run `mise run backup` and check the snapshot count
didn't unexpectedly grow: changing the path set is exactly what caused the
retention bug described in [architecture.md](architecture.md).

## Check a backup actually ran

```bash
systemctl --user list-timers restic-backup.timer restic-verify.timer
journalctl --user -u restic-backup.service -n 50
journalctl --user -u restic-backup.service | grep forgejo:   # dump ok?
```

`LAST` in the timer output is when it last fired. If it's stale by more than a
day and the machine has been on, something is wrong — start with the journal.

## Rotate the restic password

There is no re-encrypt-everything operation. `restic key add` adds a new
password to a repository and `restic key remove` drops an old one; do it for
both repositories, then update `backup/restic.env.enc.yaml` and Bitwarden.
Verify with `mise run backup:snapshots` before removing the old key.
