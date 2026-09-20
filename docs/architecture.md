# Architecture — why it's shaped like this

The mechanics are in the [README](../README.md) and [cheatsheet](../CHEATSHEET.md).
This is the reasoning, so that a future reader can tell which parts are
load-bearing and which are taste.

## The one rule

> **Config reaches a project by copy, never by reference.**

A project must build, lint, test and deploy with nothing on the machine but
itself. Not the desk, not a shared config repo, not a symlink farm. The desk
is where conventions are *authored*; each project holds its own physical copy.

The cost is real and accepted: improving a template does not improve existing
projects. Pulling an improvement in is a deliberate act (`copier update`), one
project at a time. In exchange, nothing ever breaks because something outside
the repo moved — and things outside the repo *do* move, as this system's own
three restructures demonstrate.

## The layers

1. **Root of trust** — Bitwarden holds the age private key and the restic
   password. age encrypts; sops applies it to structured files. Everything
   else assumes these exist.
2. **The desk** — a copier template, a backup config, and rules. Deliberately
   dumb: nothing here needs to be kept in sync by hand.
3. **Per-project environment** — mise pins tools and defines the shared verbs,
   so `mise run test` works identically in a Rust project and a Python one.
4. **Knowledge** — the Obsidian vault. Specs are written before code exists.
5. **Build loop** — spec → failing test → implementation, run by Claude Code
   under each repo's `CLAUDE.md`.
6. **Code vs servers** — see below.
7. **Backups** — two restic repositories, three snapshots each.

## Code vs servers

> **Changes every commit → app repo. Changes when you roll out → servers repo.**

An app repo *builds*: source, tests, Containerfile, CI that produces an image.
The `servers` repo *runs*: Quadlet units, reverse proxy config, per-host
secrets. The boundary between them is an **immutable container image
referenced by tag** — never source code.

This is what makes rollback boring. You don't revert application code; you
change a tag back and redeploy. It also means "what is running on that box" is
answerable by reading one directory, without cloning every application.

## Why the desk is bounded

`~/Projects/workdesk` is a normal repo with one ignored folder. An earlier
version made `~/Projects` *itself* the desk, ignoring every top-level
directory. That was rejected because:

- every unrelated clone showed up as drift
- the desk claimed the whole namespace
- a stray `git clean -fdx` there would have deleted every project, since they
  were all "ignored files" to that repo

The current shape keeps the single-context benefit — open the desk, see
everything — while leaving `~/Projects` ordinary.

## Why there is no manifest

There was one (`projects.yml`) plus scripts that read it. It was deleted.

An index of projects has to be updated by hand every time a project appears or
moves, and the filesystem already knows the answer. The desk's job is to hold
conventions, not to maintain a second source of truth about itself. If a
"clone everything on a new machine" step is ever wanted again, it belongs in
[recovery.md](recovery.md) as a list of remote URLs — data, not machinery.

## Why secrets are not in `mise [env]`

The desk's `mise.toml` once decrypted the B2 credentials into `[env]`. Because
mise merges parent configs, **every task in every nested project inherited
them** — `mise env` inside `repos/servers` printed `RESTIC_PASSWORD`.

Now `backup/run.sh` is invoked through `sops exec-env`, so the credentials
exist only inside that one process. The general principle: a secret should be
in scope for exactly the command that needs it, and nesting silently widens
scope.

## Why two backup repositories, three snapshots

Local (`~/Backups/restic`) covers the common disaster: you deleted or mangled
something. It is on the same NVMe as the data, so it is *not* protection
against drive failure — B2 is. Three snapshots, not a long history, because
the value here is "undo a recent mistake", and git already holds real history.

Retention is `--group-by host`. By default restic groups snapshots by
`host,paths` and keeps N *per group*, so changing the include list silently
splits retention and old snapshots survive forever. That bug was live here
until it was caught: B2 held 7 snapshots under a "keep 3" policy.

## Why Forgejo, and why it's public but intermittent

Self-hosted and community-governed: it cannot change its terms on you. It runs
on this machine at **https://git.jonnxor.is**, behind Caddy, with git over SSH
on port 2222.

**Uptime follows the machine, deliberately.** That sounds like a flaw and
mostly isn't. Git is distributed — every clone is a complete copy — so a
remote that's offline overnight still does everything a remote is *for*: a
canonical place to push, issues, and a web view. Worst case you push later.
Paying for a VPS to keep a two-person forge reachable at 4am solves a problem
neither of us has.

It was briefly loopback-only, on the theory that not exposing it avoided TLS,
DNS and port forwarding. That was true but bought less than it cost: the forge
is for collaborating, and a remote only reachable from one machine can't be
collaborated on. Being public is worth the certificate renewal it implies.

There is deliberately **no GitHub mirror**. A mirror to a forge nothing depends
on is a chore that earns nothing. If a project ever needs to be public, that's
the moment to push it there — not before.

The trade: three separate firewalls have to agree for it to work (router
dstnat, ufw, and nothing else holding port 80), the certificate depends on
port 80 being reachable at renewal time, and a dynamic PPPoE address means DNS
is a CNAME to the router's DDNS name rather than a fixed record. All of that is
written up in `repos/servers/dns.md` and the Caddyfile's comments, because
every one of them cost time to diagnose the first time.

## What is deliberately absent

- **CI/CD pipelines** — nothing is big enough yet. Deploy is a command you run.
- **An orchestrator** — systemd is already an init system and a supervisor.
- **A secrets manager service** — sops + age is a file and a key.
- **A dotfiles framework** — mise's global config covers the tool pins.

Each of these is a reasonable thing to add *when a specific pain appears*. None
should be added because the diagram looks incomplete.
