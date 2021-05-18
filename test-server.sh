#!/bin/bash

# Usage:
# bash <(curl -s https://raw.githubusercontent.com/Deutsche-Squad-Gemeinschaft/gists/master/test-server.sh) "Server Name" "" "Mod1ID,Mod2ID,Mod3ID,..."
# bash <(curl -s https://raw.githubusercontent.com/Deutsche-Squad-Gemeinschaft/gists/master/test-server.sh) "Server Name" "PASSWORD" "Mod1ID,Mod2ID,Mod3ID,..."
#

function waitForStartup() {
  local MAXSTEPS=$(($1 / 3))
  
  for i in {1..$MAXSTEPS}; do
    timeout --signal=SIGINT 3 docker logs -f squad-server 2>&1 | grep -qe "LogOnlineSession"
    if [ "$i" -gt "$MAXSTEPS" ]; then
      echo "Server startup did timeout"
      exit 1
    else
      # Show a sign that we are alive
      echo "."
      exit 0
    fi
  done
}

function startServer() {
  # Start the server and wait for full startup
  docker run -d -v $HOME/squad-data:/home/steam/squad-dedicated --net=host -e PORT=7787 -e QUERYPORT=27165 -e RCONPORT=21114 --name=squad-server cm2network/squad
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

# Cleanup
docker stop squad-server || true  && docker rm squad-server || true

# Start the server and wait for full startup
startServer

# Rename the Server
sed -i 's/ServerName=".*"/ServerName="'"$SERVERNAME"'"/g' $HOME/squad-data/SquadGame/ServerConfig/Server.cfg

# Set Password if provided
if [ ! -z "$PASSWORD" ]; then
  echo 'SrverPassword='"$ASSWORD" >> $HOME/squad-data/SquadGame/ServerConfig/Server.cfg
fi

# Install mods if IDs are provided as first parameter
if [ ! -z "$MODIDS" ]; then
  for i in $(echo $variable | sed "s/,/ /g"); do
      docker exec squad-server bash -c '$STEAMCMDDIR/steamcmd.sh +login anonymous +force_install_dir $STEAMAPPDIR +workshop_download_item 393380 '"$i"' +quit && cp -R $STEAMAPPDIR/steamapps/workshop/content/393380/'"$i"' $STEAMAPPDIR/SquadGame/Plugins/Mods/'
  done
fi

# Re-Start the server and wait for full startup
docker stop squad-server
startServer
