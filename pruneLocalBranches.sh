#!/usr/bin/env bash
set -euo pipefail

print_usage() {
    cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h|-l|-i|-a]

Use this script to remove local branches that have been removed upstream.

Available options:

-h, --help              Print this help and exit
-l, --list              Print branches that can be pruned
-i, --interactive       Remove pruned branches interactively
-a, --all               Remove all pruned branches

N.B: Combining multiple options is not possible.

EOF
}

choice=""
parse_params() {
    while :; do
        case "${1-}" in
        -h | --help)
            print_usage && exit 0
            exit 0
            ;;
        -l | --list) choice='list' ;;
        -i | --interactive) choice='interactive' ;;
        -a | --all) choice='all' ;;
        -?*)
            echo "Unknown option: $1"
            exit 1
            ;;
        *) break ;;
        esac
        shift
    done

    args=("$@")

    return 0
}

parse_params "$@"

echo -e "Local branches tracking a remote that has been removed:\n"
GONE_BRANCHES=$(git for-each-ref --format '%(refname:short) %(upstream:track)' | awk '$2 == "[gone]" {print $1}')
for branch in $GONE_BRANCHES; do
    echo -e "\t$branch"
done

echo

if [[ "$choice" == "" ]]; then
    read -e -p "> Remove [a]ll, [i]nteractive, or [q]uit? [a/i/Q]: " choice
    if [[ $choice == 'i' ]]; then
    	choice='interactive'
    elif [[ $choice == 'a' ]]; then
    	choice='all'
    fi
fi


if [[ "$choice" == 'all' ]]; then
    echo -e "\nRemoving all branches!"
    read -e -p "> Please confirm [y/N]: " confirm_remove_all
    if [[ "$confirm_remove_all" != 'y' ]]; then
        echo -e "Quitting."
        exit 0
    fi
    for branch in $GONE_BRANCHES; do
        git branch -D $branch
        echo -e "Removed $branch."
    done
elif [[ "$choice" == 'interactive' ]]; then
    echo -e "\nRemoving interactively\n"
    for branch in $GONE_BRANCHES; do
        read -e -p "> Remove $branch? [y/N/q]: " should_remove
        if [[ "$should_remove" == 'q' ]]; then
            echo -e "Quitting."
            exit 0
        elif [[ "$should_remove" == 'y' ]]; then
            git branch -D $branch
            echo -e "Removed."
        else
            echo -e "Skipped."
        fi
    done
fi
