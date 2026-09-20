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

keep() { restic "$@" forget --keep-last 3 --group-by host --prune; }

case "${1:?usage: run.sh backup|init|snapshots|check|restore-test}" in
backup)
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
*)
	echo "unknown command: $1" >&2
	exit 1
	;;
esac
