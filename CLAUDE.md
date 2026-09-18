# workdesk — rules

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
- `projects.yml` is the single manifest of every project this workdesk
  indexes — keep remotes host-agnostic (canonical + mirror fields), never
  hardcode a single provider as load-bearing.
