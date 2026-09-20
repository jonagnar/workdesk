# Tech stack — what's installed, and where it's pinned

[glossary.md](glossary.md) says what each tool *is*. This says where each one
comes from and who decides its version.

## The authoritative sources

Version numbers below are a **snapshot taken 2026-09-20** and will drift. These
four places are the truth:

| layer | pinned in | scope |
| ----- | --------- | ----- |
| System packages | your distro (pacman on CachyOS) | the machine |
| Global dev tools | `~/.config/mise/config.toml` | your user, every directory |
| Per-project tools | each project's `mise.toml` `[tools]` | that project only |
| Container images | `Image=` in each `.container` file | that service |

To read the current state rather than trusting this page:

```bash
cat ~/.config/mise/config.toml                     # global pins
mise ls                                            # what's active here
grep -h '^Image=' repos/servers/hosts/*/quadlet/*.container
```

## System packages

Installed with the distro package manager, not managed by this repo. These are
the things that must exist before anything else works.

| tool | version | role |
| ---- | ------- | ---- |
| git | 2.55.0 | version control — the substrate |
| age | 1.3.2 | encryption keypair; the root of trust |
| sops | 3.13.3 | encrypts values inside YAML/JSON/env files |
| mise | 2026.9.9 | tool versions, tasks, env loading |
| podman | 6.1.2 | rootless containers; provides the Quadlet generator |
| gh | 2.101.0 | GitHub CLI (account: `jonagnar`) |
| rsync | 3.5.0 | used by `servers` deploy |

Why these are system packages rather than mise-managed: they're needed *to
bootstrap*, including in recovery scenarios where mise may not be set up yet.
`docs/recovery.md` depends on being able to run `age` and `sops` on a bare
machine.

## Global dev tools (mise)

`~/.config/mise/config.toml` — available in every directory, installed with
`mise install`.

```toml
[tools]
dotnet = ["10", "8"]
lefthook = "latest"
node = "lts"
"pipx:copier" = "latest"
"pipx:gdtoolkit" = "latest"
restic = "latest"
uv = "latest"

[settings.sops]
age_key_file = "/home/jonnxor/.config/sops/age/keys.txt"
```

| tool | version | role |
| ---- | ------- | ---- |
| restic | 0.19.1 | backups to both repositories |
| lefthook | 2.1.14 | git hooks in every repo |
| copier | 9.18.2 | scaffolding from `templates/project` |
| node / uv / dotnet | lts / latest / 10, 8 | language runtimes used across projects |
| gdtoolkit | latest | Godot linting/formatting (pre-existing, unrelated to the desk) |

`[settings.sops].age_key_file` is the line that lets mise decrypt `*.enc.*`
files. If decryption ever fails, check it first.

These are pinned to `latest` rather than exact versions deliberately: they're
developer tooling where a newer version is nearly always fine, and a broken one
is a one-line rollback. Anything where a surprise upgrade would be *dangerous*
is pinned exactly — see container images below.

## Per-project tools

Set by the copier template from the `language` answer, written into the
project's own `mise.toml`:

| language | pins | fmt / lint / test |
| -------- | ---- | ----------------- |
| python | `python 3.13`, `uv latest` | `ruff format` / `ruff check` / `pytest` |
| node | `node lts` | `prettier --write` / `eslint` / `npm test` |
| rust | `rust stable` | `cargo fmt` / `cargo clippy -D warnings` / `cargo test` |
| go | `go latest` | `gofmt -w` / `go vet` / `go test ./...` |
| dotnet | `dotnet latest` | `dotnet format` / `dotnet build -warnaserror` / `dotnet test` |
| none | — | `echo` placeholders, so the verbs always exist |

Each project carries its own copy. Changing the template does not change
existing projects — that's the copy-not-reference rule.

## Container images

Pinned to **exact tags**, because here a surprise upgrade is a production
incident. The tag is also the deploy and rollback mechanism.

| service | image | role |
| ------- | ----- | ---- |
| Forgejo | `codeberg.org/forgejo/forgejo:16.0.5-rootless` | canonical git remote at git.jonnxor.is |
| Caddy | `docker.io/library/caddy:2.11.4` | reverse proxy, automatic TLS |
| Postgres | `docker.io/library/postgres:17` | *template only* — local dev when `use_database` is on |

All fully qualified, because Podman (unlike Docker) refuses to guess a
registry.

Upgrading: change the tag, commit, `mise run deploy -- home`. Read the
project's release notes first — Forgejo in particular runs database migrations
on start, and migrations are not reversible by changing the tag back.

## External services

| service | used for | if it disappears |
| ------- | -------- | ---------------- |
| Backblaze B2 | offsite restic repository | local repo survives; see [recovery.md](recovery.md#4-one-backup-repository-is-gone) |
| Bitwarden | age private key, restic password, B2 keys | paper copy of the age key is the fallback |
| GitHub (`jonagnar`) | future push-mirror | nothing depends on it, by design |
| Let's Encrypt | TLS certificates via Caddy | Caddy re-requests automatically; mind rate limits |

## Deliberately not in the stack

Reasons are in [architecture.md](architecture.md#what-is-deliberately-absent):
no CI/CD system, no orchestrator, no secrets-manager service, no dotfiles
framework. Each is a reasonable addition *when a specific pain appears*.
