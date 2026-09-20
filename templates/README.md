# templates

Copier template. Each feature is a toggle answered at generation time, so a
project only ends up with the files it opted into — and nothing generated
references this directory afterwards.

The questions live in `copier.yml` **at the repo root**, not here. Copier
requires that for a template consumed by git URL; `_subdirectory` points back
at `templates/project/template`, which holds the files that get rendered.
One consequence: this repo can carry exactly one template. A second one needs
its own repository.

## project

Scaffold a new standalone project repo:

```bash
mise run new -- repos/<name>
```

That wraps `copier copy --trust ssh://git@git.jonnxor.is:2222/WAAAGH/workdesk.git`
— the git URL rather than a local path, because copier records the source in
the generated `.copier-answers.yml`, and an absolute local path there only
works on the machine that created it. `--trust` lets the post-copy tasks run:
`git init`, `lefthook install`, and encrypting the initial `.env.enc.yaml`.

Toggles: `language` (tool pins + fmt/lint/test commands), `use_lefthook`,
`use_claude_md`, `use_sops`, `use_podman` (+ `use_database`), `use_bruno`,
and `kind` (app / library / servers).

## Versioning

The template is **not tagged**, so `copier update` follows whatever is on
`main`. That's deliberate: with tags, copier updates only as far as the
latest tag, so forgetting to tag makes updates silently do nothing — a worse
failure than picking up a change slightly early. If the template ever gets
enough traffic that half-finished work on `main` becomes a hazard, start
tagging and this trade flips.

`.copier-answers.yml` in each project records `_commit`, the template version
it was generated from. A project generated before this repo had a remote may
be missing it — copier then refuses to update, and the fix is to add the line
by hand pointing at the commit whose rendered output matches.

## Updating a project

To pull later template improvements into an existing project — explicit and
reviewable, never automatic:

```bash
cd ~/Projects/workdesk/repos/<name> && copier update --trust
```

`README.md` and `.env.enc.yaml` are project-owned and never touched by
`copier update`.
