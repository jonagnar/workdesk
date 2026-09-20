# workdesk

A desk, not a dependency. It holds the project template, the backup config,
and the rules — nothing that needs maintaining by hand.

```
~/Projects/workdesk/
├── CHEATSHEET.md        every command you actually type
├── docs/                manuals (below)
├── templates/project/   copier template, every feature a toggle
├── backup/              restic → local disk + Backblaze B2
└── repos/               ignored; every project lives here
    ├── vault/           Obsidian vault (own repo)
    └── servers/         Podman Quadlet units per host (own repo)
```

Projects in `repos/` are standalone: config got there by *copy* (a copier
template) or as a *real published package*, never by reference. Delete the
desk and every project still builds, lints and runs the same.

## Start here

| you are… | read |
| -------- | ---- |
| new to this, or setting up a machine | [docs/onboarding.md](docs/onboarding.md) |
| unsure what a word means | [docs/glossary.md](docs/glossary.md) |
| looking for a command | [CHEATSHEET.md](CHEATSHEET.md) |
| doing something you do rarely | [docs/operations.md](docs/operations.md) |
| wondering *why* it's built this way | [docs/architecture.md](docs/architecture.md) |
| something is broken or stale | [docs/reset.md](docs/reset.md) |
| something is **lost** | [docs/recovery.md](docs/recovery.md) |

## The three rules

1. **Config reaches a project by copy, never by reference.** A project must
   work with nothing on the machine but itself.
2. **Changes every commit → app repo. Changes when you roll out → servers
   repo.** The boundary between them is a container image tag.
3. **The desk stays dumb.** No manifests, indexes or status scripts that have
   to be kept in sync by hand.

## Most used

```bash
mise run new -- repos/<name>     # scaffold a project
mise run backup                  # snapshot to local + B2
mise run backup:snapshots        # what's in each repository
```

## Status

- [x] Root of trust: age keypair, sops, key in Bitwarden + paper
- [x] Copier template with toggles (`mise run new`)
- [x] Obsidian vault (`repos/vault`, GSD structure)
- [x] Backups: local disk + B2, nightly 03:00, last 3 snapshots each,
      restore-tested 2026-09-19
- [x] `servers` repo: host `home` with Forgejo 16.0.5-rootless + Caddy
      Quadlet units, `mise run lint`, `mise run deploy -- home`
- [ ] Box bootstrapped (podman, linger, sysctl, server age key as second
      sops recipient), router + DNS for git.jonnxor.is, first deploy
- [ ] Forgejo up → push remotes + GitHub mirrors
- [ ] **Back up Forgejo's volumes** once it holds anything — see the open gap
      in [docs/recovery.md](docs/recovery.md#5-the-server)

Tools: git, age, sops, mise, podman, gh, rsync (system); restic, lefthook,
copier (via mise).
