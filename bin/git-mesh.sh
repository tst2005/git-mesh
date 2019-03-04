#!/bin/sh

#MESH_DIR="$(dirname "$0")"
#MESH_PEERS='okou obelix idefix chaudron'

stop() {
	echo >&2 "$1"
	exit ${2:-1}
}

isenabled() {
	local enabled=$(git config --local --bool --get mesh.enabled)
	printf %s\\n "${enabled:-false}"
}
enable() {
	git config --local mesh.enabled true;
}
disable() {
	git config --local mesh.enabled false;
}

getpeers() {
	git config --local --get mesh.peers;
}
setpeers() {
	if [ -z "$1" ]; then
		git config --local --unset mesh.peers
	else
		git config --local mesh.peers "$1"
	fi
}

config() {
	case "$1" in
		(status)
			isenabled
		;;
		(enable)
			shift; enable
		;;
		(disable)
			shift; disable
		;;
		(setpeers)
			shift; setpeers "$@"
		;;
		(getpeers)
			shift; getpeers
		;;
	esac
}

setup() {
	for peer in $MESH_PEERS; do
		[ "$peer" != "$me" ] || continue 
		if ! git remote | grep -q "$peer"; then
			git remote add $peer ssh://${peer}${meshdir}
		fi
	done
}
peers() {
	[ $# -gt 0 ] || set -- "list";
	case "$1" in
		(list)
			git remote | while read -r peer; do                   
		                [ "$peer" != "$me" ] || continue
				printf %s\\n "$peer"
			done
		;;
		(help)
			stop "Usage: git mesh peers list|help" 0
		;;
		(*)
			stop "Usage: git mesh peers list|help" 1
		;;
	esac
}
peer() {
	[ $# -gt 0 ] || set -- "help";
	case "$1" in
		(help)		stop "Usage: git mesh peer [add|remove|help]" 0 ;;
		(add)		stop NYI ;;
		(remove)	stop NYI ;;
		(*)		stop SYNTAX_ERROR_HELP ;;
	esac
}

fetch_all() {
	for peer in $(peers); do
		fetch $peer
	done
}
fetch() {
	git fetch "$@"
}
rfetch() {
	local target="$1";shift;
	ssh -n "$target" 'cd '"$(pwd)"' && ./git-mesh.sh fetch '"$me"
}
update_master() {
	: git co master && git rebase foo/master && git co $localme
}

MESH_ENABLED="$(git config --local --bool --get mesh.enabled)"
MESH_ENABLED="${MESH_ENABLED:-false}"

#MESH_PEERS="$(git config --get mesh.peers)"

#[ -n "$MESH_PEERS" ] || stop "ERROR: MESH_PEERS undefined" 1

#me="$MESH_ME"
#[ -n "$me" ] || me=$(uname -n)
#echo "# me=$me"
echo "# MESH_ENABLED=$MESH_ENABLED"
echo "# MESH_PEERS=$MESH_PEERS"

if ! $MESH_ENABLED; then
	case "$1" in
		(config) ;;
		(help) ;;
		(*) stop "MESH is not enabled" ;;
	esac
fi

case "$1" in
	(config) shift; config "$@";;
	(setup) setup;;
	(fetch) shift; fetch "$@";;
	(fetch_all) fetch_all;;
	(rfetch) shift; rfetch "$@";;
	(peers) peers;;
	(*) echo "USAGE";exit 1;;
esac
