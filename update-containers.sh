#!/bin/bash

if [ $1 ]; then 
    REACH=$1;
else 
    REACH=all;
fi

EXCLUDE=119
DRY_RUN=true

function log() {
    LEVEL=${2:-Info}
    echo -e "[$LEVEL] $1"
}

function update_container() {

  log "Updating $curr_container_str"
  
  if [ $DRY_RUN != true ]; then
    pct exec $curr_container_id -- bash -c "apt update && apt upgrade -y";
  fi
}

function start_container() {
    log "Starting $curr_container_str";

    if [ $DRY_RUN==true ]; then 
        return 0;
    fi

    pct start $curr_container_id
    log "Sleeping for 5s"
    sleep 5
}

function shutdown_container() {
    log "Shutting down $curr_container_str";

    if [ $DRY_RUN==true ]; then 
        return 0;
    fi

    pct shutdown $curr_container_id &
}

function is_excluded() {
    local IFS=','
    for x in $EXCLUDE; do
        if [[ x -eq $1 ]]; then 
            return 1
        fi
    done

    return 0
}

if [ $DRY_RUN == true ]; then log "DRY RUN - Updates won't be performed"; fi

containers=$(pct list | tail -n +2)

while IFS=$' ' read -r id _ hostname; do
  curr_container_id=$id;
  curr_container_hostname=$hostname;
  curr_container_str="\t#$curr_container_id\t $curr_container_hostname"
  
  is_excluded $curr_container_id

  if [ $? -eq 1 ]; then 
    log "Excluding $curr_container_str";
    continue
  fi

  status=`pct status $curr_container_id`
  if [[ "$status" == "status: stopped" && ("$REACH"=="all" || "$REACH"=="stopped") ]]; then
    start_container
    update_container
    shutdown_container
  elif [[ "$status" == "status: running" && ("$REACH"=="all" || "$REACH"=="running") ]]; then
    update_container
  fi
done <<< $containers
wait