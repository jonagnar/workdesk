# workdesk — rules

- The desk is dumb on purpose. It holds conventions (templates), backup
  config, and nothing else. Don't add manifests, indexes, status scripts, or
  anything that has to be kept in sync by hand.
- `repos/` is ignored and holds every project — cloned, scaffolded, or
  throwaway. The desk never tracks their contents. Never remove that guard.
- This repo is the canonical *source* of templates and conventions. Never
  make a project repo reference it at build/run time (no relative imports,
  no symlinks, no `@`-imports outside a project's own root). Propagation is
  copy-once via copier, or a real published package.
- Commit convention: Conventional Commits (`feat:`, `fix:`, `chore:`, …).
- mise task verbs are the common interface across every project:
  `fmt`, `lint`, `test`, `up`, `down`. Add tasks under these names, not
  ad-hoc script names.
- Never commit an unencrypted secret. Anything sensitive goes through `sops`
  first.

## Sessions

- Sessions start in the main checkout (`~/Projects/workdesk`), not an
  app-made worktree. `repos/` is ignored, so a worktree of the desk does
  not contain it and cannot see the vault or any project.
- Changes reach `main` through a pull request on Forgejo — in the desk and
  in every project under `repos/`. Run `git worktree add` in *that* repo on
  a new branch, work there, push the branch and open the PR. The user
  merges PRs; Claude never does.
- Direct pushes to `main` are for hotfixes only: small, minor changes (a
  typo, a one-line fix). Anything larger, or anything in doubt, is a PR.
- Never edit tracked files or switch branches in the user's checkout. It
  stays free for their own work; a hotfix is still made from a worktree.
- The vaults are the memory between sessions. A project's prefix picks its
  vault: `jonnxor-*` in `repos/jonnxor-vault`, `sogin-*` in `repos/sogin`
  (the `sogin-vault` repo; the folder keeps its name until Phase 2 lands),
  everything else in `repos/_vault`, which also holds capture and weekly
  review.
- The vaults are the exception: edit `projects/`, `specs/` and `reference/` in
  place on `main`, each a single live copy. In `sogin-vault`, everything else
  (`.planning/`, `design/`) still goes through a PR.
- Before starting, read that vault's `projects/<name>.md` and any matching
  note in its `specs/`. Before finishing, add a dated line to that project
  note's Log for anything decided or changed, and update its Next actions.
- Links between vaults are plain text (`_vault/projects/servers`);
  `[[wikilinks]]` only work inside one vault.
- Machine and network facts that live in no repo (router, VPN, remote
  access) go in `repos/_vault/reference/`, not only in Claude's memory —
  the vaults are backed up, `~/.claude` is not.
