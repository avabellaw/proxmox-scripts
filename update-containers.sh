#!/bin/bash

if [ $1 ]; then 
    REACH=$1;
else 
    REACH=all;
fi

EXCLUDE=119
DRY_RUN=true

if [ $DRY_RUN == true ]; then echo "DRY RUN - Updates won't be performed"; fi

# Snippet taken from "sshane" and modified - https://forum.proxmox.com/threads/update-all-lxc-with-one-simple-script.58729/

containers=$(pct list | tail -n +2 | cut -f1 -d' ')

function update_container() {
  container=$1
  hostname=`pct config $container | grep hostname`

  echo "[Info] Updating #$container - $hostname"
  
  if [ $DRY_RUN != true ]; then
    pct exec $container -- bash -c "apt update && apt upgrade -y";
  fi
}

function start_container() {
    if [ $DRY_RUN==true ]; then 
        echo "[Info] Starting container $container";
        return 0;
    fi
    container=$1
    echo [Info] Starting $container
    pct start $container
    echo [Info] Sleeping 5 seconds
    sleep 5
}

function shutdown_container() {
    if [ $DRY_RUN==true ]; then 
        echo "[Info] Shutting down container $container";
        return 0;
    fi
    container=$1
    echo [Info] Shutting down $container
    pct shutdown $container &
}

function is_excluded() {
    IFS=','
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
  status=$?

  if [ $status -eq 1 ]; then 
    echo [Info] Excluding $container;
    sleep 2
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