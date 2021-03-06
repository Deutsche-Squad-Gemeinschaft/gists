#!/bin/bash

# Usage:
# bash <(curl -s https://raw.githubusercontent.com/Deutsche-Squad-Gemeinschaft/gists/master/test-server.sh) "Server Name" "" "Mod1ID,Mod2ID,Mod3ID,..."
# bash <(curl -s https://raw.githubusercontent.com/Deutsche-Squad-Gemeinschaft/gists/master/test-server.sh) "Server Name" "PASSWORD" "Mod1ID,Mod2ID,Mod3ID,..."
#

function waitForStartup() {
  local MAXSTEPS=$(($1 / 10))
  
  for i in $(seq 1 $MAXSTEPS); do
    timeout --signal=SIGINT 10 docker logs -f squad-server 2>&1 | grep -qe "LogOnlineSession"
    
    if [ $? == 1 ]; then
      if [ "$i" -gt "$MAXSTEPS" ]; then
        # Notify of failure and break
        echo "Server startup did timeout"
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

function clearServer() {
  # Stop and remove the container if exists
  docker stop squad-server || true && docker rm squad-server || true
}

function createServer() {
  # Create the container and wait for full startup
  docker run -d -v $HOME/squad-data:/home/steam/squad-dedicated --net=host -e PORT=7787 -e QUERYPORT=27165 -e RCONPORT=21114 --name=squad-server cm2network/squad
  waitForStartup ${1:-900}
}

function restartServer() {
  # Re-Start the container and wait for full startup
  docker restart squad-server
  waitForStartup ${1:-900}
}

# Get arguments or default values
SERVERNAME=${1:-"Squad Server"}
PASSWORD=${2:-""}
MODIDS=${3:-""}

# Setup Docker
sudo apt-get remove -y docker docker-engine docker.io containerd runc || true
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --batch --yes --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
sudo echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
sudo getent group docker || sudo groupadd docker
sudo usermod -aG docker $USER

# Add volume directory
mkdir -p $HOME/squad-data
chmod 777 $HOME/squad-data

# Remove old server container and create a new one
clearServer
createServer

echo "Configuring the server..."

# Rename the Server
sed -i 's/ServerName=".*"/ServerName="'"$SERVERNAME"'"/g' $HOME/squad-data/SquadGame/ServerConfig/Server.cfg

# Set Password if provided
if [ ! -z "$PASSWORD" ]; then
  if grep -q "ServerPassword=" "$HOME/squad-data/SquadGame/ServerConfig/Server.cfg"; then
    sed -i 's/ServerPassword=".*"/ServerPassword="'"$PASSWORD"'"/g' $HOME/squad-data/SquadGame/ServerConfig/Server.cfg
  else
    echo 'ServerPassword='"$PASSWORD" >> $HOME/squad-data/SquadGame/ServerConfig/Server.cfg
  fi
fi

echo "Server successfully configured!"

# Install mods if IDs are provided as first parameter
if [ ! -z "$MODIDS" ]; then
  for i in $(echo $variable | sed "s/,/ /g"); do
      echo "Installing Mod $i..."
      docker exec squad-server bash -c '$STEAMCMDDIR/steamcmd.sh +login anonymous +force_install_dir $STEAMAPPDIR +workshop_download_item 393380 '"$i"' +quit && cp -R $STEAMAPPDIR/steamapps/workshop/content/393380/'"$i"' $STEAMAPPDIR/SquadGame/Plugins/Mods/'
      echo "Mod installed!"
  done
fi

# Re-Start the server and wait for full startup
restartServer

echo "Finsied Setup, connect to: \"$SERVERNAME\" in the Server-Browser or use the following Link: \"steam://connect/$(dig @resolver4.opendns.com myip.opendns.com +short):7787/\""
