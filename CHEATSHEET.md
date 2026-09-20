# Cheatsheet

Everything you actually type. Run from `~/Projects/workdesk` unless stated.

## Daily

```bash
mise run new -- repos/<name>     # scaffold a project (asks the toggles)
mise run backup                  # snapshot to local + B2, prune to last 3
mise run backup:snapshots        # what's in each repository
```

Inside any project (`repos/<name>`):

```bash
mise install                     # install the tools this project pins
mise run fmt                     # format
mise run lint                    # lint
mise run test                    # tests
mise run up / down               # local services (only if podman was enabled)
```

## Secrets

```bash
sops edit .env.enc.yaml                      # edit a project's secrets
sops edit backup/restic.env.enc.yaml         # edit the B2 credentials
sops -d <file>                               # print decrypted (careful)
age-keygen -y ~/.config/sops/age/keys.txt    # show YOUR PUBLIC key (safe)
sops updatekeys <file>                       # re-encrypt after adding a recipient
```

`EDITOR=nano sops edit …` if you don't want vim.

## Backups

```bash
mise run backup                  # forgejo dump, then both repositories + prune
mise run backup:verify           # prove B2 is restorable (runs monthly on its own)
mise run backup:snapshots        # list
mise run backup:check            # full integrity check (slow, occasional)
mise run backup:restore-test     # pull the age key into a scratch dir
mise run backup:init             # create missing repositories (safe to re-run)
mise run backup:install          # (re)install both timers

systemctl --user list-timers restic-backup.timer restic-verify.timer
systemctl --user start restic-backup.service       # run the nightly job now
journalctl --user -u restic-backup.service -n 50   # what happened last night
journalctl --user -u restic-backup.service | grep forgejo:   # did the dump work?
```

## Servers (`repos/servers`)

Forgejo runs on this machine at **https://git.jonnxor.is**, behind Caddy.
Git over SSH on port 2222. `http://localhost:3000` still works locally.

```bash
mise run lint                    # dry-run the Quadlet generator — before every deploy
mise run deploy -- hades         # install units + Caddyfile, restart services

systemctl --user status forgejo caddy
journalctl --user -u forgejo -n 50
journalctl --user -u caddy -f     # watch certificate activity
podman ps
```

Deploy a new version: change `Image=…:<tag>` in the `.container` file, commit,
`mise run deploy -- hades`. Roll back the same way — but **not across a major
version**, since Forgejo's database migrations don't reverse.

Remote URL form: `ssh://git@git.jonnxor.is:2222/WAAAGH/<repo>.git`

## Git

Conventional Commits are enforced by lefthook:

```
feat: …   fix: …   chore: …   docs: …   refactor: …   test: …   perf: …   ci: …   build: …
```

## When something is "not trusted"

```bash
mise trust                       # after moving or first cloning a repo
lefthook install                 # reinstall git hooks
```

See [docs/reset.md](docs/reset.md).

## Paths worth knowing

| what | where |
| ---- | ----- |
| desk | `~/Projects/workdesk` |
| projects | `~/Projects/workdesk/repos/` |
| age key (private) | `~/.config/sops/age/keys.txt` |
| local backup repo | `~/Backups/restic` |
| systemd units | `~/.config/systemd/user/restic-{backup,verify}.{service,timer}` |
| global tool pins | `~/.config/mise/config.toml` |
