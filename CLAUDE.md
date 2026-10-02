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
- The vault is the exception: edit `repos/vault` in place on `main`. It is
  the memory between sessions and must stay a single live copy.
- The vault is the memory between sessions. Before starting, read
  `repos/vault/projects/<name>.md` and any matching note in
  `repos/vault/specs/`. Before finishing, add a dated line to that project
  note's Log for anything decided or changed, and update its Next actions.
- Machine and network facts that live in no repo (router, VPN, remote
  access) go in `repos/vault/reference/`, not only in Claude's memory —
  the vault is backed up, `~/.claude` is not.
