#!/bin/sh

if [ -x $0.local ]; then
	$0.local "$@" || exit $?
fi

hook=$(dirname $(git rev-parse --git-dir))/util/git-hooks/$(basename $0)
if [ -x $hook ]; then
	$hook "$@" || exit $?
fi
