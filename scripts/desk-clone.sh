#!/bin/sh
# Materialise the desk: clone every manifest project that isn't here yet.
# This is the step that turns a restored backup into a working machine.
set -eu
cd "$(dirname "$0")/.."

count=$(yq -r '.projects | length' projects.yml)
i=0
while [ "$i" -lt "$count" ]; do
	name=$(yq -r ".projects[$i].name" projects.yml)
	canonical=$(yq -r ".projects[$i].canonical // \"\"" projects.yml)
	mirror=$(yq -r ".projects[$i].mirror // \"\"" projects.yml)
	i=$((i + 1))

	if [ -d "$name" ]; then
		echo "have     $name"
		continue
	fi

	url=$canonical
	[ -n "$url" ] || url=$mirror
	if [ -z "$url" ]; then
		echo "skip     $name (no remote recorded yet)"
		continue
	fi

	echo "cloning  $name from $url"
	git clone --quiet "$url" "$name"
	if [ -n "$mirror" ] && [ "$url" != "$mirror" ]; then
		git -C "$name" remote add mirror "$mirror"
	fi
done
