# Onboarding — zero to working

For a new machine, or a new person who has been handed this system. Read
[glossary.md](glossary.md) first if the tool names mean nothing to you.

Roughly 30 minutes, most of it waiting on installs.

## 0. What you must already have

Two things that cannot be recovered from this repository:

- The **age private key** — a secure note in Bitwarden, or the paper copy.
- The **restic password** — also in Bitwarden. Without it both backups are
  permanently unreadable.

If you have neither, you are not onboarding, you are starting over. Everything
encrypted is gone; the git history is not.

## 1. System packages

```bash
sudo pacman -S git age sops mise podman github-cli rsync    # Arch / CachyOS
```

Other distros: same packages, different manager. `mise` may need its own
install script — see mise.jdx.dev.

Activate mise in your shell (fish shown; the line differs per shell):

```fish
echo 'mise activate fish | source' >> ~/.config/fish/config.fish
exec fish
```

## 2. Restore the age key

```bash
mkdir -p ~/.config/sops/age
$EDITOR ~/.config/sops/age/keys.txt     # paste the AGE-SECRET-KEY-… line
chmod 600 ~/.config/sops/age/keys.txt
```

Tell mise where it is — this is what lets mise and sops decrypt anything:

```bash
mise settings set sops.age_key_file ~/.config/sops/age/keys.txt
```

Verify the key is the right one; this must match the recipient in `.sops.yaml`:

```bash
age-keygen -y ~/.config/sops/age/keys.txt
```

## 3. Get the desk

```bash
mkdir -p ~/Projects && cd ~/Projects
git clone <desk remote> workdesk       # or restore from backup — see recovery.md
cd workdesk
mise trust
mise install                           # restic, lefthook, copier
lefthook install
```

Set your git identity if this machine has none:

```bash
git config --global user.name  "jonnxor"
git config --global user.email "jonnxor@jonnxor.is"
```

## 4. Prove decryption works

```bash
sops -d backup/restic.env.enc.yaml | head -1
```

If that prints a line, the key is correct and everything else will work. If it
fails, stop — nothing downstream can succeed.

## 5. Backups

```bash
mise run backup:init        # creates missing repositories; safe to re-run
mise run backup             # first snapshot to local + B2
mise run backup:install     # nightly 03:00 timer
mise run backup:snapshots   # confirm
```

## 6. Get the projects back

Each project is its own repo. Clone whichever you need into `repos/`:

```bash
cd ~/Projects/workdesk/repos
git clone <vault remote> vault
git clone <servers remote> servers
```

Per project, once cloned:

```bash
cd <project> && mise trust && mise install && lefthook install
```

If there are no remotes yet, the projects come back from the backup instead —
see [recovery.md](recovery.md).

## 7. Obsidian

Open Obsidian → *Open folder as vault* → `~/Projects/workdesk/repos/vault`.
Settings travel with the folder; the Templates plugin is already configured to
point at `templates/`.

## 8. Forgejo

Git hosting runs on this machine, bound to loopback. To bring it up:

```bash
cd ~/Projects/workdesk/repos/servers
mise run lint                 # units generate?
mise run deploy -- hades      # install and start
```

Then http://localhost:3000. First-run steps (admin account, disabling
registration, adding your SSH key) are in `repos/servers/README.md`.

If the host directory is named after a *different* machine, that name is used
as an SSH alias and needs a matching `Host` block in `~/.ssh/config`.

## Done when

```bash
cd ~/Projects/workdesk
mise run backup:snapshots     # both repositories listed
cd repos/servers && mise run lint   # units generate
```

Both green means the machine is fully set up.
