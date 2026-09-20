# Glossary

If you've just landed here, this is what each moving part is. For versions and
where each one is pinned, see [stack.md](stack.md).

| term | what it is | why it's here |
| ---- | ---------- | ------------- |
| **age** | Modern file encryption tool. A keypair: a public key encrypts, a private key decrypts. | Simpler than GPG, one file, no keyring daemon. The private key at `~/.config/sops/age/keys.txt` is the root of everything. |
| **sops** | Encrypts *values* inside structured files (YAML/JSON/env), leaving keys readable. | Lets secrets live committed in git. A diff still shows *which* key changed, just not to what. |
| **mise** | Per-project tool-version manager + task runner + env loader. | Pins the toolchain, and gives every project the same verbs (`fmt`/`lint`/`test`). |
| **copier** | Project scaffolding from templates, with answers recorded so templates can be re-applied later. | Config reaches a project by *copy*, so projects never depend on the desk. |
| **lefthook** | Git hook manager, config in `lefthook.yml`. | Enforces Conventional Commits, runs fmt/lint before commit. Language-agnostic. |
| **restic** | Deduplicating backup tool with client-side encryption. | The cloud never sees plaintext. Snapshots are content-addressed, so repeat backups are cheap. |
| **Backblaze B2** | Cheap S3-compatible object storage. | The offsite copy. Chosen over Proton Drive because restic needs a real S3 API. |
| **Podman** | Container engine; rootless and daemonless. | Runs services as ordinary systemd units instead of under a root daemon. |
| **Quadlet** | A systemd *generator* that turns `.container` files into `.service` units. | Declarative containers, versioned in git, no compose process in production. |
| **Caddy** | Reverse proxy with automatic HTTPS. | Gets and renews Let's Encrypt certificates with no configuration beyond a domain name. |
| **Forgejo** | Self-hosted git forge (a community fork of Gitea). | The canonical remote. GitHub becomes a mirror, never the thing you depend on. |
| **Obsidian** | Markdown notes app over a plain folder. | The vault is just files — greppable, git-tracked, outlives the app. |
| **GSD** | Capture → clarify → organize → review → do. | How work gets into and out of the vault. |
| **SDD** | Spec-Driven Development: write what "done" means before code. | Specs start in the vault, get promoted into the repo. |
| **TDD** | Test-Driven Development: failing test, then implementation. | Each spec acceptance criterion becomes a test. |

## Conventions you'll see everywhere

- **`*.enc.yaml`** — encrypted with sops. Safe in git. Never edit by hand; use `sops edit`.
- **`mise run <verb>`** — never call the underlying tool directly. The verb is the contract; what it maps to differs per language.
- **Conventional Commits** — `feat:`, `fix:`, `chore:`… Enforced by a hook, not by etiquette.
- **`repos/` is ignored** — the desk never tracks what's inside it.
- **Images are referenced by exact tag** — the tag is the deploy and the rollback.
