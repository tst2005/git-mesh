#!/bin/sh

#MESH_DIR="$(dirname "$0")"
#MESH_PEERS='okou obelix idefix chaudron'

stop() {
	echo >&2 "$1"
	exit ${2:-1}
}

subcmd() {
	local cmd="$1$2";shift 2
	"$cmd" "$@"
}

git_mesh_config_status() {
	local enabled=$(git config --local --bool --get mesh.enabled)
	printf %s\\n "${enabled:-false}"
}
git_mesh_config_enable() {
	git config --local mesh.enabled true;
}
git_mesh_config_disable() {
	git config --local mesh.enabled false;
}
git_mesh_config_forget() {
	git config --local --unset mesh.enabled;
}

git_mesh_config_getpeers() {
	git config --local --get mesh.peers;
}
git_mesh_config_setpeers() {
	if [ -z "$1" ]; then
		git config --local --unset mesh.peers
	else
		git config --local mesh.peers "$1"
	fi
}

git_mesh_config() {
	case "$1" in
		(status|enable|disable|forget|getpeers|setpeers)
			subcmd git_mesh_config_ "$@"
		;;
	esac
}

git_mesh_setup() {
	for peer in $MESH_PEERS; do
		[ "$peer" != "$me" ] || continue 
		if ! git remote | grep -q "$peer"; then
			git remote add $peer ssh://${peer}${meshdir}
		fi
	done
}
git_mesh_peers() {
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
git_mesh_peer() {
	[ $# -gt 0 ] || set -- "help";
	case "$1" in
		(help)		stop "Usage: git mesh peer [add|remove|help]" 0 ;;
		(add)		stop NYI ;;
		(remove)	stop NYI ;;
		(*)		stop SYNTAX_ERROR_HELP ;;
	esac
}

git_mesh_fetch_all() {
	for peer in $(peers); do
		subcmd git_mesh_ fetch $peer
	done
}
git_mesh_fetch() {
	git fetch "$@"
}
git_mesh_rfetch() {
	local target="$1";shift;
	ssh -n "$target" 'cd '"$(pwd)"' && ./git-mesh.sh fetch '"$me"
}
#git_mesh_update_master() {
#	: git co master && git rebase foo/master && git co $localme
#}


git_mesh() {
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
		(config)	subcmd git_mesh_ "$@" ;;
		(setup)		subcmd git_mesh_ "$@" ;;
		(fetch)		subcmd git_mesh_ "$@" ;;
		(fetch_all)	subcmd git_mesh_ "$@" ;;
		(rfetch)	subcmd git_mesh_ "$@" ;;
		(peers)		subcmd git_mesh_ "$@" ;;
		(*) echo "USAGE";exit 1;;
	esac
}

git_mesh "$@"
