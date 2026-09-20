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

| tool | version | role | docs |
| ---- | ------- | ---- | ---- |
| git | 2.55.0 | version control — the substrate | [git-scm.com/doc](https://git-scm.com/doc) |
| age | 1.3.2 | encryption keypair; the root of trust | [github.com/FiloSottile/age](https://github.com/FiloSottile/age) |
| sops | 3.13.3 | encrypts values inside YAML/JSON/env files | [github.com/getsops/sops](https://github.com/getsops/sops) |
| mise | 2026.9.9 | tool versions, tasks, env loading | [mise.jdx.dev](https://mise.jdx.dev) |
| podman | 6.1.2 | rootless containers; provides the Quadlet generator | [docs.podman.io](https://docs.podman.io) |
| gh | 2.101.0 | GitHub CLI — installed, not currently used by anything here | [cli.github.com/manual](https://cli.github.com/manual/) |
| rsync | 3.5.0 | used by `servers` deploy | [rsync.samba.org](https://rsync.samba.org/documentation.html) |

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

| tool | version | role | docs |
| ---- | ------- | ---- | ---- |
| restic | 0.19.1 | backups to both repositories | [restic.readthedocs.io](https://restic.readthedocs.io) |
| lefthook | 2.1.14 | git hooks in every repo | [lefthook.dev](https://lefthook.dev) |
| copier | 9.18.2 | scaffolding from `templates/project` | [copier.readthedocs.io](https://copier.readthedocs.io) |
| uv | latest | Python packaging/runner | [docs.astral.sh/uv](https://docs.astral.sh/uv/) |
| node / dotnet | lts / 10, 8 | language runtimes used across projects | — |
| gdtoolkit | latest | Godot linting/formatting (pre-existing, unrelated to the desk) | — |

`[settings.sops].age_key_file` is the line that lets mise decrypt `*.enc.*`
files. If decryption ever fails, check it first.

These are pinned to `latest` rather than exact versions deliberately: they're
developer tooling where a newer version is nearly always fine, and a broken one
is a one-line rollback. Anything where a surprise upgrade would be *dangerous*
is pinned exactly — see container images below.

## Per-project tools

Set by the copier template from the `language` answer, written into the
project's own `mise.toml`:

| language | pins | fmt / lint / test | tool docs |
| -------- | ---- | ----------------- | --------- |
| python | `python 3.13`, `uv latest` | `ruff format` / `ruff check` / `pytest` | [ruff](https://docs.astral.sh/ruff/), [pytest](https://docs.pytest.org) |
| node | `node lts` | `prettier --write` / `eslint` / `npm test` | [prettier](https://prettier.io/docs/), [eslint](https://eslint.org/docs/latest/) |
| rust | `rust stable` | `cargo fmt` / `cargo clippy -D warnings` / `cargo test` | [cargo](https://doc.rust-lang.org/cargo/), [clippy](https://doc.rust-lang.org/clippy/) |
| go | `go latest` | `gofmt -w` / `go vet` / `go test ./...` | [go.dev/doc](https://go.dev/doc/) |
| dotnet | `dotnet latest` | `dotnet format` / `dotnet build -warnaserror` / `dotnet test` | [learn.microsoft.com/dotnet](https://learn.microsoft.com/dotnet/) |
| none | — | `echo` placeholders, so the verbs always exist | — |

Each project carries its own copy. Changing the template does not change
existing projects — that's the copy-not-reference rule.

## Container images

Pinned to **exact tags**, because here a surprise upgrade is a production
incident. The tag is also the deploy and rollback mechanism.

| service | image | role | docs |
| ------- | ----- | ---- | ---- |
| Forgejo | `codeberg.org/forgejo/forgejo:16.0.5-rootless` | the forge at git.jonnxor.is; web on `127.0.0.1:3000`, git SSH public on 2222 | [forgejo.org/docs](https://forgejo.org/docs/latest/) |
| Caddy | `docker.io/library/caddy:2.11.4` | reverse proxy, automatic Let's Encrypt TLS | [caddyserver.com/docs](https://caddyserver.com/docs/) |
| Postgres | `docker.io/library/postgres:17` | *template only* — local dev when `use_database` is on | [postgresql.org/docs](https://www.postgresql.org/docs/) |

Forgejo's web port is published to loopback only — Caddy reaches it over the
`services` container network, and `127.0.0.1:3000` stays available for local
debugging without DNS.

All fully qualified, because Podman (unlike Docker) refuses to guess a
registry.

Upgrading: change the tag, commit, `mise run deploy -- hades`. Read the
project's release notes first — Forgejo in particular runs database migrations
on start, and migrations are not reversible by changing the tag back.

## External services

| service | used for | if it disappears | docs |
| ------- | -------- | ---------------- | ---- |
| Backblaze B2 | offsite restic repository | local repo survives; see [recovery.md](recovery.md#4-one-backup-repository-is-gone) | [backblaze.com/docs](https://www.backblaze.com/docs/cloud-storage) |
| Bitwarden | age private key, restic password, B2 keys | paper copy of the age key is the fallback | [bitwarden.com/help](https://bitwarden.com/help/) |
| ISNIC | DNS for jonnxor.is | nothing resolves — see `repos/servers/dns.md` | [isnic.is](https://www.isnic.is/en) |
| Let's Encrypt | TLS certificate for git.jonnxor.is, via Caddy | Caddy retries; needs port 80 reachable at renewal | [letsencrypt.org/docs](https://letsencrypt.org/docs/) |
| MikroTik DDNS | `git` is a CNAME to the router's `sn.mynetname.net` name, so a PPPoE reconnect doesn't strand the domain | the CNAME goes stale; replace with an `A` record | — |

Git hosting is self-hosted; there is no mirror and no CI service. Note that
DNS resolution, certificate issuance and the dynamic address are three
external dependencies the forge acquired when it went public — the price of
being reachable.

## Reference pages worth bookmarking

The specific pages you'll actually need when editing this system:

| when you're editing | read |
| ------------------- | ---- |
| `.container` / `.volume` / `.network` files | [podman-systemd.unit(5)](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html) — the Quadlet reference |
| `backup/restic-backup.timer` | [systemd.timer(5)](https://man7.org/linux/man-pages/man5/systemd.timer.5.html) |
| a reverse proxy, if you ever expose a service | [Caddyfile concepts](https://caddyserver.com/docs/caddyfile/concepts) |
| `templates/project/copier.yml` | [Copier configuring](https://copier.readthedocs.io/en/stable/configuring/) |
| any `lefthook.yml` | [Lefthook configuration](https://lefthook.dev/configuration/) |
| a commit message | [Conventional Commits](https://www.conventionalcommits.org/) |
| `bruno/` collections | [Bruno docs](https://docs.usebruno.com/) |
| the vault | [Obsidian Help](https://obsidian.md/help/) |

## Deliberately not in the stack

Reasons are in [architecture.md](architecture.md#what-is-deliberately-absent):
no CI/CD system, no orchestrator, no secrets-manager service, no dotfiles
framework. Each is a reasonable addition *when a specific pain appears*.
