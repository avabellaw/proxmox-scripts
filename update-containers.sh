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

function is_container_running() {
    if [[ `lxc-info -n $curr_container_id -s | awk '{print $2}'` == "RUNNING" ]]; then return 0; else return 1; fi # 0=true | 1=false - exit status
}

function start_container() {
    log "Starting...";

    if [ $DRY_RUN==true ]; then 
        return 0;
    fi

    pct start $curr_container_id;

    TIMEOUT=300; # seconds
    TIME_PASSED=0;
    SLEEP_FOR=2 # seconds

    while ! is_container_running; do
        sleep $SLEEP_FOR;
        TIME_PASSED+=$SLEEP_FOR
        if [ $TIME_PASSED >= TIMEOUT ]; then break; fi

        log "Waiting for #$curr_container_id to start...";
    done

    return $(is_container_running)
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

log "Getting container list..."
containers=$(pct list | tail -n +2)

while IFS=$' ' read -r id status hostname; do
  curr_container_id=$id;
  curr_container_hostname=$hostname;
  curr_container_str="\t#$curr_container_id\t $curr_container_hostname"
  
  is_excluded $curr_container_id

  if [ $? -eq 1 ]; then 
    log "Excluding $curr_container_str";
    continue
  fi

  if ! is_container_running && [[ ("$REACH"=="all" || "$REACH"=="stopped") ]]; then
    if start_container; then log "Started";
        update_container;
        shutdown_container;
    else
        log "Start FAILED";
    fi
  elif is_container_running && [[ ("$REACH"=="all" || "$REACH"=="running") ]]; then
    update_container
  fi
done <<< $containers
wait