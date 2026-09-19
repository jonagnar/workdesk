# workdesk

`~/Projects/workdesk` **is** the desk — a desk, not a dependency. Its own
files sit at the top level; every project is a subdirectory that is its own
standalone git repo, ignored by this one.

```
~/Projects/              ← ordinary space; anything not a desk project lives here
└── workdesk/            ← this repo: CLAUDE.md, projects.yml, templates/, backup/, scripts/
    ├── vault/           ← own repo, ignored here
    ├── servers/         ← own repo, ignored here
    └── <new project>/   ← same
```

The desk is deliberately bounded. Clone a stranger's repo or start a scratch
experiment in `~/Projects` and the desk neither tracks it, backs it up, nor
reports it as drift.

No project ever references the desk at build or run time: config reaches a
project by *copy* (a copier template) or as a *real published package*.
Delete everything but a project's own folder and it still builds, lints and
runs exactly the same.

| verb                    | does                                              |
| ----------------------- | ------------------------------------------------- |
| `mise run desk:status`  | what's on the desk, its state, drift vs manifest  |
| `mise run desk:clone`   | clone missing manifest projects (fresh machine)   |
| `mise run new -- <dir>` | scaffold a new standalone project                 |
| `mise run backup`       | restic snapshot → B2 + retention                  |

## Layers

1. **Root of trust** — Bitwarden (vault) + age (keypair) + sops (encrypts
   secrets so they can live committed in any repo).
2. **The desk (this repo)** — canonical hooks, lint/format config,
   `mise.toml` and `CLAUDE.md` templates, and `projects.yml`, the manifest
   that `desk:status` and `desk:clone` read.
3. **Per-project environment** — mise owns the task verbs (`fmt`, `lint`,
   `test`, `up`, `down`) so every project speaks the same commands regardless
   of language. Lefthook + a commit convention, copied in per project.
4. **Knowledge & tasks** — Obsidian vault, GSD-structured (capture → clarify
   → organize → review → do). Specs get written there before code exists.
5. **Build loop** — SDD (spec → repo) + TDD (failing test → implement →
   iterate), executed with Claude Code, governed by each repo's `CLAUDE.md`.
6. **Code vs servers** — app repos own *build* (source, tests, Containerfile,
   local dev compose). A separate `servers` repo owns *run* (Podman Quadlet
   units, reverse proxy, prod secrets under a **different** age recipient,
   prod backups). The boundary between them is an immutable container image,
   never source code.
7. **Backups** — restic → Backblaze B2, client-side encrypted, 3-2-1
   (working copy, local external, offsite). Nightly job, retention policy,
   quarterly restore test.

## Rebuild runbook

Assume whoever reads this (you, in five years, with no memory of any of
this) has only: this repo, the age private key backup, and the Bitwarden
vault.

1. Restore the age private key (Bitwarden secure note, or the paper copy)
   to `~/.config/sops/age/keys.txt`.
2. `sops` can now decrypt anything encrypted to that key — including
   `backup/restic.env.enc.yaml`, which holds the B2 credentials.
3. Clone this repo to `~/Projects/workdesk`, then `mise run desk:clone` to
   pull every project in `projects.yml` back onto the desk.
4. `mise run backup:restore-test`, or a full `restic restore`, brings back
   anything not in git (the vault's untracked state, local-only work).
5. Everything else (lint configs, hooks, mise tasks) is plain text already
   sitting in each project repo — nothing else to reconstruct.

## Status

- [x] Root of trust: age + sops present on this machine
- [x] Age keypair in place (`~/.config/sops/age/keys.txt`, public key in
      `.sops.yaml`)
- [x] Age private key in Bitwarden
- [x] Age private key also in B2 (restic snapshot, restore-tested 2026-09-19)
- [ ] Age private key paper copy
- [x] Desk is `~/Projects/workdesk`, bounded; projects are ignored
      subdirectories inside it
- [x] `gh auth login` done (GitHub account: `jonagnar`)
- [ ] Forgejo self-hosted (part of the `servers` repo), then canonical
      remotes + GitHub push-mirror wired up
- [x] `projects.yml` drives `desk:status` / `desk:clone` (remotes pending
      Forgejo)
- [x] Copier template (`templates/project`): lefthook, mise.toml, CLAUDE.md,
      sops, optional podman compose / db service / bruno — all toggleable.
      `mise run new -- ~/Projects/workdesk/<name>`
- [x] mise decrypts sops secrets with the shared key
      (`mise settings sops.age_key_file`)
- [x] Obsidian vault created (`~/Projects/workdesk/vault`, GSD structure, own git
      repo), opened in Obsidian with Templates enabled
- [x] restic scaffold: `backup/` + `mise run backup*` tasks + systemd timer
- [x] Backblaze B2: repo initialised, first snapshot taken, nightly timer
      enabled (03:00), restore test passed. Next restore test due 2026-12-19.
- [x] `servers` repo scaffolded from the template: host `home` with Forgejo
      16.0.5 (rootless) + Caddy Quadlet units, `mise run lint` dry-runs the
      generator, `mise run deploy -- home`
- [ ] Box bootstrapped (podman, linger, sysctl, server age key added as
      second sops recipient), router + DNS for git.jonnxor.is, first deploy

Tools on this machine: git, age, sops, mise, podman, gh (system packages);
restic, lefthook, copier (installed globally via mise — see
`~/.config/mise/config.toml`).
