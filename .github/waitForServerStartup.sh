#!/usr/bin/env bash

function waitForStartup() {
  local MAXSTEPS=$(($1 / 10))
  
  for i in $(seq 1 $MAXSTEPS); do
    timeout --signal=SIGINT 10 docker logs -f squad-server 2>&1 | grep -qe "LogOnlineSession"
    
    if [ $? == 1 ]; then
      if [ "$i" -gt "$MAXSTEPS" ]; then
        # Notify of failure and break
        echo "Server startup did timeout :("
        exit 1
      else
        # Show a sign that we are alive
        echo "Waiting for server startup... ($i/$MAXSTEPS)"
      fi
    else
      # Server seems to have started, break the loop
      echo "Server Started!"
      break
    fi
  done
}

waitForStartup 1800
