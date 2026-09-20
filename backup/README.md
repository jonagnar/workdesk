# backup

Two restic repositories, same password, both client-side encrypted:

| where | path | covers |
| ----- | ---- | ------ |
| local | `~/Backups/restic` | deleting or mangling something by accident |
| cloud | Backblaze B2 | fire, theft, the disk dying |

Both keep only the **last 3 snapshots** — no long trail. `mise run backup`
writes to both and prunes both.

Local lives on the same NVMe as the data, so it is not protection against
drive failure. That's B2's job.

## What must also be in Bitwarden

- `RESTIC_PASSWORD` — without it *both* repositories are unreadable
- the B2 application key id + key

## What is backed up

`include.txt` minus `exclude.txt` — the whole desk, `repos/` included, plus
the age key and the global mise config. New projects are covered
automatically.

## Quarterly: test the restore

```bash
mise run backup:restore-test
```

Pulls the age key back out of the latest B2 snapshot into a scratch
directory. A backup nobody has restored from is a theory.
