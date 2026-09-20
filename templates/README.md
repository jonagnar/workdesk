# templates

Copier templates. Each feature is a toggle answered at generation time, so a
project only ends up with the files it opted into — and nothing generated
references this directory afterwards.

## project

Scaffold a new standalone project repo:

```bash
mise run new -- repos/<name>
```

(wraps `copier copy --trust templates/project <dest>`; `--trust` lets the
post-copy tasks run: `git init`, `lefthook install`, and encrypting the
initial `.env.enc.yaml`.)

Toggles: `language` (tool pins + fmt/lint/test commands), `use_lefthook`,
`use_claude_md`, `use_sops`, `use_podman` (+ `use_database`), `use_bruno`,
and `kind` (app / library / servers).

To pull later template improvements into an existing project — explicit and
reviewable, never automatic:

```bash
cd ~/Projects/workdesk/workdesk/<name> && copier update --trust
```

`README.md` and `.env.enc.yaml` are project-owned and never touched by
`copier update`.
