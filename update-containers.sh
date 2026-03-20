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
    echo "[$LEVEL] $1"
}

if [ $DRY_RUN == true ]; then log "DRY RUN - Updates won't be performed"; fi

# Snippet taken from "sshane" and modified - https://forum.proxmox.com/threads/update-all-lxc-with-one-simple-script.58729/

containers=$(pct list | tail -n +2 | cut -f1 -d' ')

function update_container() {
  local container=$1
  local hostname=`pct config $container | grep hostname`

  log "Updating #$container - $hostname"
  
  if [ $DRY_RUN != true ]; then
    pct exec $container -- bash -c "apt update && apt upgrade -y";
  fi
}

function start_container() {
    local container=$1
    log "Starting #$container";

    if [ $DRY_RUN==true ]; then 
        return 0;
    fi

    pct start $container
    log "Sleeping for 5s"
    sleep 5
}

function shutdown_container() {
    local container=$1
    log "Shutting down #$container";

    if [ $DRY_RUN==true ]; then 
        return 0;
    fi

    pct shutdown $container &
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

for container in $containers
do
  is_excluded $container

  if [ $? -eq 1 ]; then 
    log "Excluding $container";
    sleep 2;
    continue
  fi

  status=`pct status $container`
  if [[ "$status" == "status: stopped" && ("$REACH"=="all" || "$REACH"=="stopped") ]]; then
    start_container $container
    update_container $container
    shutdown_container $container
  elif [[ "$status" == "status: running" && ("$REACH"=="all" || "$REACH"=="running") ]]; then
    update_container $container
  fi
done; wait