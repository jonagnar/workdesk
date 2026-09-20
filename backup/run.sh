#!/bin/sh
# Every restic operation, against both repositories.
#
# Invoked as: sops exec-env backup/restic.env.enc.yaml backup/run.sh <cmd>
# so the credentials exist only for the duration of this process — they are
# deliberately NOT in the desk's mise [env], which every nested project would
# otherwise inherit.
#
# $RESTIC_REPOSITORY (B2) and $RESTIC_PASSWORD come from the encrypted file.
# $RESTIC_LOCAL is a plain path from mise [env] — not a secret.
set -eu
cd "$(dirname "$0")/.."

FORGEJO_DUMP_DIR="$HOME/Backups/forgejo"

# Forgejo's repositories and database live in a Podman volume, outside the
# paths restic walks — and its SQLite file cannot be copied safely while the
# server is running. `forgejo dump` writes a consistent archive (including
# forgejo-db.sql) which we drop somewhere include.txt covers.
#
# Uncompressed tar on purpose: restic deduplicates by content, so unchanged
# repositories cost nothing on the next snapshot. A zip would re-store whole.
dump_forgejo() {
	if ! podman ps --filter 'name=^forgejo$' --format '{{.Names}}' | grep -q forgejo; then
		echo "forgejo: not running, skipping dump" >&2
		return 0
	fi

	mkdir -p "$FORGEJO_DUMP_DIR"
	tmp="$FORGEJO_DUMP_DIR/.dump.tmp"

	# Write to a temp file and move it into place only on success, so a failed
	# dump can never replace the last good one with a truncated file.
	if podman exec forgejo forgejo dump --type tar --file - >"$tmp" 2>/dev/null; then
		mv "$tmp" "$FORGEJO_DUMP_DIR/forgejo-dump.tar"
		echo "forgejo: dumped $(du -h "$FORGEJO_DUMP_DIR/forgejo-dump.tar" | cut -f1)" >&2
	else
		rm -f "$tmp"
		echo "forgejo: DUMP FAILED — backing up everything else; forge data is NOT covered by this snapshot" >&2
	fi
}

keep() { restic "$@" forget --keep-last 3 --group-by host --prune; }

case "${1:?usage: run.sh backup|init|snapshots|check|restore-test|verify}" in
backup)
	dump_forgejo
	restic -r "$RESTIC_LOCAL" backup --files-from backup/include.txt --exclude-file backup/exclude.txt
	keep -r "$RESTIC_LOCAL"
	restic backup --files-from backup/include.txt --exclude-file backup/exclude.txt
	keep
	;;
init)
	restic -r "$RESTIC_LOCAL" cat config >/dev/null 2>&1 || restic -r "$RESTIC_LOCAL" init
	restic cat config >/dev/null 2>&1 || restic init
	;;
snapshots)
	echo "== local"; restic -r "$RESTIC_LOCAL" snapshots
	echo "== b2"; restic snapshots
	;;
check)
	echo "== local"; restic -r "$RESTIC_LOCAL" check
	echo "== b2"; restic check
	;;
restore-test)
	dir=$(mktemp -d)
	restic restore latest --target "$dir" --include "$HOME/.config/sops/age/keys.txt"
	echo "restored into $dir:"
	find "$dir" -type f
	;;
verify)
	# Run unattended by restic-verify.timer. Exits non-zero on any failure,
	# which systemd turns into a desktop notification — a backup nobody has
	# restored from is a theory, and one nobody has restored from *lately*
	# is a theory about the past.
	dir=$(mktemp -d)
	trap 'rm -rf "$dir"' EXIT
	fail=0

	# 1. B2 is reachable, credentials still valid, repository intact enough
	#    to list. Catches revoked keys and deleted buckets.
	if ! restic snapshots --latest 1 >/dev/null 2>&1; then
		echo "VERIFY FAIL: cannot list snapshots in B2" >&2
		exit 1
	fi

	# 2. The age key actually restores, and matches the live one. Catches a
	#    repository that lists fine but cannot reconstruct its data.
	if restic restore latest --target "$dir" --include "$HOME/.config/sops/age/keys.txt" >/dev/null 2>&1 &&
		cmp -s "$dir$HOME/.config/sops/age/keys.txt" "$HOME/.config/sops/age/keys.txt"; then
		echo "ok: age key restored from B2 and matches"
	else
		echo "VERIFY FAIL: age key did not restore, or differs from the live key" >&2
		fail=1
	fi

	# 3. The Forgejo dump in the latest snapshot is a readable archive that
	#    still contains a database. Catches dumps that started failing after
	#    an upgrade and have been silently writing garbage.
	if restic restore latest --target "$dir" --include "$HOME/Backups/forgejo" >/dev/null 2>&1 &&
		tar -tf "$dir$HOME/Backups/forgejo/forgejo-dump.tar" 2>/dev/null | grep -q '^forgejo-db.sql$'; then
		echo "ok: forgejo dump readable and contains forgejo-db.sql"
	else
		echo "VERIFY FAIL: forgejo dump missing, unreadable, or has no database" >&2
		fail=1
	fi

	# 4. The most recent snapshot is recent. Catches the timer silently not
	#    firing, which no amount of repository integrity would reveal.
	last=$(restic snapshots --latest 1 --json 2>/dev/null | grep -oE '"time":"[^"]+"' | head -1 | cut -d'"' -f4)
	if [ -n "$last" ]; then
		age_days=$(( ($(date +%s) - $(date -d "$last" +%s)) / 86400 ))
		if [ "$age_days" -gt 3 ]; then
			echo "VERIFY FAIL: newest B2 snapshot is ${age_days} days old" >&2
			fail=1
		else
			echo "ok: newest B2 snapshot is ${age_days} day(s) old"
		fi
	fi

	exit "$fail"
	;;
*)
	echo "unknown command: $1" >&2
	exit 1
	;;
esac
