#!/bin/sh -e

root=$(git rev-parse --git-dir) || ( echo "Not under git control. Cannot install git hooks." >&2 ; exit 0 )
dst="$root/hooks"
src=../../util/git-hooks # relative to dst
hooks=$(cd util/git-hooks/ && git ls-files -c | grep -Ev 'install.sh|wrapper.sh')

for h in $hooks; do
	if [ "x$(readlink "$dst/$h")" != "x$src/wrapper.sh" ]; then
		# preserve custom hooks if any
		if [ -e "$dst/$h" ]; then
			mv "$dst/$h" "$dst/$h.local"
		fi
		ln -s "$src/wrapper.sh" "$dst/$h"
	fi
done
