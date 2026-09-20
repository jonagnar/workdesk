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
git clone ssh://git@git.jonnxor.is:2222/WAAAGH/workdesk.git
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
git clone ssh://git@git.jonnxor.is:2222/jonnxor/vault.git
git clone ssh://git@git.jonnxor.is:2222/WAAAGH/servers.git
```

Both are private, so this needs your SSH key registered in Forgejo — and
Forgejo has to be *running*, which is a chicken-and-egg problem if this
machine is the one you're rebuilding. In that case restore from backup
instead: [recovery.md](recovery.md).

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

## 8. Split DNS — do this before anything else touches git.jonnxor.is

`git.jonnxor.is` resolves publicly to this network's address, but the router
does not hairpin: traffic from inside the LAN to the public address leaves and
never comes back. Two settings are needed on any machine here, and **both**
failures look identical from the outside — the forge appears down while
working fine for everyone else.

```bash
# 1. stop systemd-resolved silently falling back to Quad9 behind the router
sudo mkdir -p /etc/systemd/resolved.conf.d
printf '[Resolve]\nFallbackDNS=\n' | sudo tee /etc/systemd/resolved.conf.d/no-fallback.conf
sudo systemctl restart systemd-resolved

# 2. pin the name — a RouterOS static entry only covers the record type it
#    declares, so an AAAA query returns the public CNAME and poisons the cache
echo '192.168.50.33 git.jonnxor.is' | sudo tee -a /etc/hosts
```

Check it worked. `getent` and `resolvectl` can disagree, so test what SSH
actually uses:

```bash
python3 -c "import socket;print(socket.getaddrinfo('git.jonnxor.is',2222)[0][4][0])"
```

That must print `192.168.50.33`. Full explanation in `repos/servers/dns.md`.

On a machine *outside* this LAN, skip both: the public address is correct
there.

## 9. Forgejo

Git hosting runs on this machine at https://git.jonnxor.is, behind Caddy.
To bring it up on a rebuilt machine:

```bash
cd ~/Projects/workdesk/repos/servers
mise run lint                 # units generate?
mise run deploy -- hades      # install and start
```

First-run steps (admin account, disabling registration, adding your SSH key)
and the going-public checklist — sysctl, DNS, router forwarding, and the order
they must happen in — are in `repos/servers/README.md`.

If the host directory is named after a *different* machine, that name is used
as an SSH alias and needs a matching `Host` block in `~/.ssh/config`.

## Done when

```bash
cd ~/Projects/workdesk
mise run backup:snapshots     # both repositories listed
mise run backup:verify        # the backup is provably restorable
python3 -c "import socket;print(socket.getaddrinfo('git.jonnxor.is',2222)[0][4][0])"
ssh -p 2222 git@git.jonnxor.is          # "Hi there, <you>"
cd repos/servers && mise run lint        # units generate
```

All green means the machine is fully set up. The resolution check is there
because it's the one that fails silently and wastes an afternoon — everything
else announces itself.
