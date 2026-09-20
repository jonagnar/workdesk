# workdesk

A desk, not a dependency. It holds the project template, the backup config,
and the rules — nothing that needs maintaining by hand.

```
~/Projects/workdesk/
├── templates/project/   copier template, every feature a toggle
├── backup/              restic → local disk + Backblaze B2
└── repos/               ignored; every project lives here
    ├── vault/           Obsidian vault (own repo)
    └── servers/         Podman Quadlet units per host (own repo)
```

| verb                        | does                                    |
| --------------------------- | --------------------------------------- |
| `mise run new -- repos/<n>` | scaffold a standalone project           |
| `mise run backup`           | snapshot to local disk **and** B2       |
| `mise run backup:snapshots` | what's in each repository               |

Projects in `repos/` are standalone: config got there by *copy* (a copier
template) or as a *real published package*, never by reference. Delete the
desk and every project still builds, lints and runs the same.

## Layers

1. **Root of trust** — Bitwarden (vault) + age (keypair) + sops (encrypts
   secrets so they can live committed in any repo).
2. **The desk** — the copier template: mise task verbs, lefthook, sops
   wiring, optional Containerfile/compose/Bruno, all toggleable.
3. **Per-project environment** — mise owns the verbs (`fmt`, `lint`, `test`,
   `up`, `down`) so every project speaks the same commands regardless of
   language.
4. **Knowledge & tasks** — the Obsidian vault, GSD-structured (capture →
   clarify → organize → review → do). Specs are written there before code.
5. **Build loop** — SDD (spec → repo) + TDD (failing test → implement →
   iterate), executed with Claude Code, governed by each repo's `CLAUDE.md`.
6. **Code vs servers** — app repos own *build* (source, tests, Containerfile).
   `servers` owns *run* (Quadlet units, reverse proxy, prod secrets under a
   **different** age recipient). The boundary is an immutable container
   image, never source code.
7. **Backups** — restic to two repositories, client-side encrypted, last 3
   snapshots each. Local disk covers accidents; B2 covers fire.

## Rebuild runbook

Assume whoever reads this has only: the age private key backup and the
Bitwarden vault.

1. Restore the age private key (Bitwarden secure note, or the paper copy)
   to `~/.config/sops/age/keys.txt`.
2. `sops` can now decrypt `backup/restic.env.enc.yaml`, which holds the B2
   credentials and the restic password.
3. `restic restore latest` from B2 brings back the whole desk, `repos/` and
   all.
4. Everything else (lint configs, hooks, mise tasks) is plain text already
   sitting in each project repo — nothing to reconstruct.

## Status

- [x] Root of trust: age keypair, sops, key in Bitwarden
- [ ] Age private key paper copy
- [x] Copier template with toggles (`mise run new`)
- [x] Obsidian vault (`repos/vault`, GSD structure)
- [x] Backups: local disk + B2, nightly 03:00, last 3 snapshots each,
      restore-tested 2026-09-19
- [x] `servers` repo: host `home` with Forgejo 16.0.5-rootless + Caddy
      Quadlet units, `mise run lint`, `mise run deploy -- home`
- [ ] Box bootstrapped (podman, linger, sysctl, server age key as second
      sops recipient), router + DNS for git.jonnxor.is, first deploy
- [ ] Forgejo up → push remotes + GitHub mirrors

Tools: git, age, sops, mise, podman, gh (system); restic, lefthook, copier,
yq (via mise).
