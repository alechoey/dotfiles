#! /usr/bin/env bash

usage() {
    echo "usage: $0 [[-h | --help]] <host_patterns>"
}

cssh() {
    if [ -z "$HOSTS" ]; then
       usage
       echo "$0: No host patterns provided"
       exit 1
    fi

    tmux set-hook window-linked 'setw remain-on-exit on'
    tmux new-window "ssh ${HOSTS[0]}"
    unset HOSTS[0];
    for i in "${HOSTS[@]}"; do
        tmux split-window -d "ssh $i" &2>1
    done
    tmux select-pane -t 0
    tmux select-layout tiled > /dev/null
    tmux set-window-option synchronize-panes on > /dev/null
}

declare -A HOST_PATTERNS
HOST_PATTERNS=()

while [ "$1" != "" ]; do
    case $1 in
        -h | --help )
            usage
            exit;;
        -* | --* )
            echo "Unrecognized option: $1"
            usage
            exit 1
            ;;
        * )
            HOST_PATTERNS[${#HOST_PATTERNS[*]}]=$1
            ;;
    esac
    shift
done

HOSTS=()
REGEX="^(.*)\[([0-9]+)\-([0-9]+)\](.*)$"

for host_pattern in "${HOST_PATTERNS[@]}"
do
    host_fragments=()
    remaining_pattern=$host_pattern

    while [ "$remaining_pattern" != "" ]; do
        if [[ $remaining_pattern =~ $REGEX ]];
        then
            static_fragment=${BASH_REMATCH[1]}
            range_beginning=${BASH_REMATCH[2]}
            range_end=${BASH_REMATCH[3]}
            remaining_pattern=${BASH_REMATCH[4]}

            appended_fragments=()
            range_size=$((range_end - range_beginning))
            for ((i=range_beginning;i<=range_end;i++))
            do
                appended_fragments+=("$static_fragment$i")
            done

            if (( ${#host_fragments[@]} ));
            then
                new_host_fragments=()
                for ((host_index=0; host_index<${#host_fragments[@]}; host_index++))
                do
                    host_fragment=host_fragments[host_index]
                    for appended_fragment in ${appended_fragments[@]}
                    do
                        new_host_fragments+=($host_fragment$appended_fragment)
                    done
                done
                host_fragments=(${new_host_fragments[@]})
            else
                host_fragments=(${appended_fragments[@]})
            fi
        else
            if (( ${#host_fragments[@]} ));
            then
                for ((host_index=0; host_index<${#host_fragments[@]}; host_index++))
                do
                    host_fragment=${host_fragments[host_index]}
                    host_fragments[host_index]=$host_fragment$remaining_pattern
                done
            else
                host_fragments=($remaining_pattern)
            fi
            remaining_pattern=""
        fi
    done
    HOSTS+=(${host_fragments[@]})
done

cssh
