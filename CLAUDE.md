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
