# workdesk

This is the meta repo — the **workdesk**, not a dependency. It holds the
canonical templates, conventions, and manifest for every other project. No
project repo ever references this one at build or run time: everything
reaches a project by *copy* (via a copier template) or as a *real published
package*. Delete this repo and every project still builds, lints, and runs
exactly the same.

## Layers

1. **Root of trust** — Bitwarden (vault) + age (keypair) + sops (encrypts
   secrets so they can live committed in any repo).
2. **This repo** — canonical hooks, lint/format config, `mise.toml` and
   `CLAUDE.md` templates, and `projects.yml`, the manifest of every project
   (name, canonical remote, mirror).
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

1. Restore the age private key (Bitwarden secure note, or the restic/B2
   backup, or the paper copy).
2. `sops` can now decrypt anything in any project repo that was encrypted
   to that key.
3. Clone this repo, then clone each project from `projects.yml`.
4. Restore the Obsidian vault from the restic/B2 backup.
5. Everything else (lint configs, hooks, mise tasks) is plain text already
   sitting in each project repo — nothing else to reconstruct.

## Status

- [x] Root of trust: age + sops present on this machine
- [x] Age keypair in place (`~/.config/sops/age/keys.txt`, public key in
      `.sops.yaml`)
- [x] Age private key in Bitwarden
- [x] Age private key also in B2 (restic snapshot, restore-tested 2026-09-19)
- [ ] Age private key paper copy
- [x] workdesk repo created (`~/projects/workdesk`)
- [x] `gh auth login` done (GitHub account: `jonagnar`)
- [ ] Forgejo self-hosted (part of the `servers` repo), then canonical
      remotes + GitHub push-mirror wired up
- [x] `projects.yml` populated (remotes pending Forgejo)
- [x] Copier template (`templates/project`): lefthook, mise.toml, CLAUDE.md,
      sops, optional podman compose / db service / bruno — all toggleable.
      `mise run new -- ~/projects/<name>`
- [x] mise decrypts sops secrets with the shared key
      (`mise settings sops.age_key_file`)
- [x] Obsidian vault created (`~/projects/vault`, GSD structure, own git
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
