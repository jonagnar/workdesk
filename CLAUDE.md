# workdesk — rules

- `~/Projects/workdesk` **is** the desk: this repo's files sit at its top
  level, and every project is a subdirectory that is its own standalone git
  repo. The desk never tracks a project's contents — `.gitignore` denies
  every top-level directory and allows back only `backup/`, `scripts/`,
  `templates/`. Never remove that guard.
- The desk is bounded: `~/Projects` outside it is ordinary, untracked space
  for anything that isn't a desk project. Don't widen the desk to cover it.
- This repo is the canonical *source* of templates and conventions. Never
  make a project repo reference it at build/run time (no relative imports,
  no symlinks, no `@`-imports outside a project's own root). Propagation is
  copy-once via copier, or a real published package.
- Commit convention: Conventional Commits (`feat:`, `fix:`, `chore:`, …).
- mise task verbs are the common interface across every project:
  `fmt`, `lint`, `test`, `up`, `down`. Add tasks under these names, not
  ad-hoc script names.
- Never commit an unencrypted secret. Anything sensitive in this repo goes
  through `sops` first.
- `projects.yml` is the single manifest of every project on the desk, read by
  `mise run desk:status` and `desk:clone`. Add an entry whenever a project is
  scaffolded or cloned, and keep remotes host-agnostic (canonical + mirror),
  never hardcoding a single provider as load-bearing.
