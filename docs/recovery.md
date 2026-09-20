# Recovery — when something is lost

Find your situation, do that section. If you are setting up a healthy machine
instead, go to [onboarding.md](onboarding.md).

> **Steps marked (untested)** are correct per restic's documented behaviour but
> have not been exercised on this system. The restore of the age key
> (`backup:restore-test`) *has* been exercised and works.

## Triage

| what's gone | recoverable? | go to |
| ----------- | ------------ | ----- |
| A file you deleted | yes | [1](#1-a-deleted-or-mangled-file) |
| The laptop | yes | [2](#2-the-machine-is-gone) |
| The desk folder | yes | [2](#2-the-machine-is-gone) |
| The age **private** key | only from Bitwarden or paper | [3](#3-the-age-key) |
| The restic password | **no** — backups are permanently unreadable | [3](#3-the-age-key) |
| The B2 account | yes, local repo survives | [4](#4-one-backup-repository-is-gone) |
| The home box | yes | [5](#5-the-server) |
| A git remote | yes, local clones are complete | [6](#6-a-remote) |

## 1. A deleted or mangled file

Try git first — if the file was committed, `git checkout -- <path>` or
`git restore --source=HEAD~1 <path>` is faster than any backup.

Otherwise, from the local restic repository:

```bash
cd ~/Projects/workdesk
sops exec-env backup/restic.env.enc.yaml 'restic -r "$RESTIC_LOCAL" snapshots'
sops exec-env backup/restic.env.enc.yaml \
  'restic -r "$RESTIC_LOCAL" restore <snapshot-id> --target /tmp/restore --include <absolute/path>'
```

Then copy what you need out of `/tmp/restore`. Restoring to a scratch directory
and copying is always safer than restoring in place.

Remember only the **last 3 snapshots** exist. If the mistake is older than
that, the backup will not have it — git will.

## 2. The machine is gone

You need the age key and the restic password (see section 3 if you don't have
them).

1. Install the system packages and mise — [onboarding.md](onboarding.md) steps
   1–2, including restoring the age key.
2. Install restic. Easiest without the desk:

```bash
mise use -g restic@latest
```

3. Point restic at B2. You cannot use the encrypted credentials file yet —
   it's inside the backup. Set the four values by hand from Bitwarden:

```bash
export RESTIC_REPOSITORY='s3:s3.eu-central-003.backblazeb2.com/<bucket>'
export RESTIC_PASSWORD='<from Bitwarden>'
export AWS_ACCESS_KEY_ID='<from Bitwarden>'
export AWS_SECRET_ACCESS_KEY='<from Bitwarden>'
restic snapshots
```

4. Restore everything (untested):

```bash
restic restore latest --target /tmp/restore
```

The archive stores absolute paths, so the desk appears at
`/tmp/restore/home/jonnxor/Projects/workdesk`. Move it into place:

```bash
mkdir -p ~/Projects
cp -a /tmp/restore/home/jonnxor/Projects/workdesk ~/Projects/
cp -a /tmp/restore/home/jonnxor/.config/mise/config.toml ~/.config/mise/
```

Restoring to `--target /` directly would work but overwrites live files; the
scratch-directory route is safer and barely slower.

5. Finish as in onboarding: `mise trust`, `mise install`, `lefthook install`,
   `mise run backup:install`, and re-open the vault in Obsidian.

This brings back `repos/` too, since it's inside the desk — including any
project whose changes were never pushed anywhere.

## 3. The age key

**If you have it in Bitwarden or on paper:** restore it to
`~/.config/sops/age/keys.txt`, `chmod 600`, and everything decrypts again.

**If it is truly gone**, then permanently lost:

- every `*.enc.*` file in every repo (the B2 credentials among them)
- nothing else — all other content is plaintext in git

Recovery is: create a new keypair, back it up properly this time, update every
`.sops.yaml` to the new recipient, and re-enter every secret by hand from
Bitwarden or from the upstream service.

**If the restic password is gone**, both backup repositories are
cryptographically unreadable. There is no recovery path, by design. The data
that also lives in git is fine; anything that existed only in a backup is gone.

## 4. One backup repository is gone

They are independent. If B2 is lost (account closed, bucket deleted), the local
repository still holds the last 3 snapshots, and vice versa. Recreate the
missing one and refill it:

```bash
mise run backup:init     # creates whichever is missing
mise run backup
```

Only the last 3 snapshots are ever kept, so nothing historical is lost that
wasn't already being discarded.

## 5. The server

The box holds no unique source — units and config are in `repos/servers`, so
rebuilding is: reinstall the OS, redo the bootstrap in
`repos/servers/README.md`, generate a **new** age key for it, add that public
key as a recipient (see [operations.md](operations.md)), then
`mise run deploy -- home`.

What is *not* in git: the container **volumes** — Forgejo's database and
repositories, Caddy's certificates. Those are not currently backed up. If the
box dies today, hosted repositories are lost unless they also exist as clones
on your laptop.

> **Open gap.** Before Forgejo holds anything you care about, add a backup of
> its volume — a `pg_dump`/`tar` on the box pushed to the same B2 repository,
> or restic running on the box itself. This is the one known hole in the
> system.

Caddy's certificate volume is not worth backing up — Let's Encrypt will just
issue again — but be aware of their rate limits if you rebuild repeatedly.

## 6. A remote

Local clones are complete copies. Create a new empty repository, then:

```bash
git remote set-url origin <new url>
git push --all && git push --tags
```

Nothing is lost as long as one clone exists anywhere.

## Prevention

- `mise run backup:restore-test` quarterly. It is the only thing that proves
  the chain works end to end.
- Keep the age key in three places: Bitwarden, the backup, paper.
- Keep the restic password in Bitwarden. It is the one secret with **no**
  recovery path.
