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

Also `~/Backups/forgejo/forgejo-dump.tar`: each run calls `forgejo dump`
first, because Forgejo's repositories and database live in a Podman volume
outside those paths, and its SQLite file can't be copied safely while the
server is running. The dump is an uncompressed tar on purpose — restic
deduplicates by content, so unchanged repositories cost nothing on the next
snapshot, where a zip would be stored whole every time.

A failed dump is logged loudly and does not abort the rest of the backup:

```bash
journalctl --user -u restic-backup.service | grep forgejo:
```

## Verification — automatic, monthly

`restic-verify.timer` runs `mise run backup:verify` on the 1st of each month.
It is silent on success and raises a desktop notification on failure, via
systemd's `OnFailure=` pointing at `restic-verify-failed.service`.

Four checks, each aimed at a failure that is otherwise **completely silent**:

| check | catches |
| ----- | ------- |
| list snapshots in B2 | revoked application key, deleted bucket, no network |
| restore the age key and compare it to the live one | a repository that lists fine but cannot reconstruct data |
| the Forgejo dump is a readable tar containing `forgejo-db.sql` | dumps that started failing after an upgrade and have been writing garbage |
| newest snapshot is under 3 days old | the nightly timer quietly not firing |

That last one matters most. Repository integrity tells you nothing about
whether anything is still being *put in*.

Run it by hand any time:

```bash
mise run backup:verify
```

The failure path is worth re-testing if you ever change these units — a
notification that never fires is worse than none, because it reads as
"everything is fine". To test it, drop in a failing ExecStart, start the
service, confirm the notification appears, then remove the drop-in:

```bash
mkdir -p ~/.config/systemd/user/restic-verify.service.d
printf '[Service]\nExecStart=\nExecStart=/bin/false\n' > ~/.config/systemd/user/restic-verify.service.d/99-test.conf
systemctl --user daemon-reload && systemctl --user start restic-verify.service
rm -rf ~/.config/systemd/user/restic-verify.service.d && systemctl --user daemon-reload
```

## Deeper checks, by hand

```bash
mise run backup:check         # full integrity verification, slow
mise run backup:restore-test  # pull the age key into a scratch dir and look at it
```

`docs/recovery.md` has the full Forgejo restore procedure, rehearsed
2026-09-20.
