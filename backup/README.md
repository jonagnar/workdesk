# backup

restic → Backblaze B2, client-side encrypted, nightly via a systemd user
timer. Credentials live in `restic.env.enc.yaml` (sops + age) and are loaded
into the environment by mise for every `backup*` task.

## What must also be in Bitwarden

- `RESTIC_PASSWORD` — without it the repository is unreadable, full stop
- the B2 application key id + key

`restic.env.enc.yaml` needs the age key to decrypt. If the laptop is gone,
you restore from Bitwarden + B2 directly; the sops file is a convenience for
this machine, not the only copy.

## First-time setup

1. Create a B2 bucket and an application key scoped to it.
2. `sops edit backup/restic.env.enc.yaml` — fill in the four values.
3. `mise run backup:init` — creates the restic repository in the bucket.
4. `mise run backup` — first (full) snapshot.
5. `mise run backup:install` — installs and enables the nightly timer.

## What is backed up

`include.txt` (paths, one per line) minus `exclude.txt`. Add the Obsidian
vault path once it exists. Git remotes are not a backup of *this* machine's
uncommitted work, notes, or keys — that is what this is for.

Retention (`mise run backup` runs it after each snapshot):
7 daily · 4 weekly · 6 monthly.

## Quarterly: test the restore

```bash
mise run backup:restore-test
```

Restores the age key from the latest snapshot into a scratch directory and
lists it. A backup nobody has restored from is a theory.
