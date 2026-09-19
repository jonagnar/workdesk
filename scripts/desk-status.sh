#!/bin/sh
# What's on the desk, what state each project is in, and any drift between
# the manifest and what's actually here.
set -eu
cd "$(dirname "$0")/.."

listed=$(yq -r '.projects[].name' projects.yml)

printf '%-22s %-16s %-12s %s\n' PROJECT BRANCH STATE REMOTE
for d in */; do
	name=${d%/}
	[ -d "$name/.git" ] || continue

	branch=$(git -C "$name" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '-')
	n=$(git -C "$name" status --porcelain | wc -l | tr -d ' ')
	if [ "$n" -eq 0 ]; then state=clean; else state="$n dirty"; fi
	remote=$(git -C "$name" remote get-url origin 2>/dev/null || echo '(none)')

	label=$name
	echo "$listed" | grep -qx "$name" || label="$name [unlisted]"
	printf '%-22s %-16s %-12s %s\n' "$label" "$branch" "$state" "$remote"
done

for n in $listed; do
	[ -d "$n" ] || echo "MISSING on disk: $n  → mise run desk:clone"
done
