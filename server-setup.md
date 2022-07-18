This guide shows a very simple automated Squad server setup using services and scheduling on **Linux**. It does not or partly explain basic squad server installation knowledge so make sure to read the [Squad Wiki](https://squad.gamepedia.com/Server_Configuration) first.
It hadles **automated restarts**, **updates**, **backups**, **mods** and **CPU affinity**. It can easily be modified and extended and should be ready for use in production.

## Requirements
- Cron (preinstalled)
- SystemD (preinstalled)
- [AWS CLI](https://aws.amazon.com/de/cli/) (Optional Backups)
- [gcore](http://man7.org/linux/man-pages/man1/gcore.1.html) (Optional Core Memory Dumps)
  - `sudo apt i gdm -y`

## Using a Service
Using a [service/daemon](https://en.wikipedia.org/wiki/Daemon_(computing)) for our server and systemctl to control it does give us a lot of what we need for an automated Squad server setup: start/stop/restart/status commands, auto-restart, start after boot, adjusting the CPU Affinity and [much more](https://www.freedesktop.org/software/systemd/man/systemd.unit.html#Wants=).


For better security, we will use **user** controlled services so possible administrators do **NOT** have to use the root user.
First we are going to enable the users services to be run at boot by entering the follwing command:
```loginctl enable-linger sqserver```
Next, su on your sqserver user and create the user services folder if it does not already exist with the following command:
```mkdir -p $HOME/.config/systemd/user```
After that you need to create your service file. prefferably you will store that file **next to your squad-server** and link it into the previously created directory. Create a new service file and paste the contents below:  

**public.service**
```
[Unit]
Description=Deutsche Squad Gemeinschaft: Public - https://dsg-gaming.de
After=network.target

[Service]
CPUAffinity=0 1
WorkingDirectory=/home/sqserver/Public
Type=simple
TimeoutSec=300
ExecStartPre=/home/sqserver/Public/pre-start.sh
ExecStart=/home/sqserver/Public/SquadGameServer.sh
ExecStop=/bin/kill -2 $MAINPID
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
```
Save this file **next to your squad-server** with the following folder structure:
```
~/
├── Servers/
|   ├── Public/
|   │   ├── server/
|   │   ├── public.service
|   │   ├── pre-start.sh
|   ├── Train/
...
├── Mods/

```
Next link the file into your users services directory using the following command:
```ln -s $HOME/Servers/public,service $HOME/.config/systemd/user/public.service```

In order for the service to start at boot you will have to enable it with the following command:
```systemctl --user enable public.service```

That is all, **continue reading** to lear how to start the server.


**After**
This ensures that the Squad server will be started after the listed services.
This can be helpful in edge cases if your server depends on an RemoteAdminList for example.
If you do not need this option remove it, otherwise you would know and you should also read
the according [documentation](https://www.freedesktop.org/software/systemd/man/systemd.unit.html#Wants=) then.

**CPUAffinity**
Basically the affinity mask for on which the process and all sub processes should be restricted to.
This allows you to run the server only on certain cores.

**TimeoutSec**
After this has run out and the server is not started it will automatically restart to prevent a dead server if it crashes on start.
This also means that if your server takes longer to start, for example if you use big mods, you will have to set this timeout
accordingly or your server will be stuck in a restart loop.

**ExecStartPre**
Path to your magic setup script, you handle game updating and mod (un-)installing there. This will always run
and finish before your server will be started.

Thats it pretty much, you can now start/stop/restart your server from anywhere,
it will automatically update the game and install your mods (according to your setup.sh). The example below shows how that script could look like.

**pre-start.sh (example)**
```bash
#!/bin/bash
# Configure
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SERVERDIR=$SCRIPT_DIR/server

# Do stuf
# ...

```

## Automatic Restart & Backup
In order to automatically restart and backup the server i use Cron. This only requires to write the according lines into your Crontab.
**Remember that each user on linux has it's own crontab!, make sure you use the sqserver user for this!** You can open and edit your crontab by using the command `crontab -e`, just edit it to your needs.
The included explanation below is really all you need to understand it and it takes <1 minute to read.

**crontab**
```
# For example, you can run a backup of all your user accounts
# at 5 a.m every week with:
# 0 5 * * 1 tar -zcf /var/backups/home.tgz /home/
#
# For more information see the manual pages of crontab(5) and cron(8)
# m h dom mon dow   command

# Restart a server
0 5 * * * /usr/sbin/systemctl --user restart public.service

# Backup a server
0 * * * * /path/to/backup/script.sh
```

As you can see we will use a backup script to backup the server. This script should copy **all** dynamic files to your setup,
these are the **ServerConfig folder** and your **setup.sh**. You can simply copy these without stopping the server. These can then be
archived and uploaded to the secure location or service of your choice. Below you will see an example using AWS S3 as a final storage,
this does require installing the [AWS CLI](https://aws.amazon.com/de/cli/):

**backup.sh**
```bash
#!/bin/bash
#Configuration

# Server dir, not install dir, contains setup.sh
SERVERDIR=/path/to/serverdir

###########
# Execute #
###########
# Create a new tmp directory for the backup
BACKUPTMP=`mktemp -d

# Copy the pre-start script and log
cp $SERVERDIR/pre-start.sh $BACKUPTMP/

# Copy the configuration directory
cp -r $SERVERDIR/server/SquadGame/ServerConfig $BACKUPTMP

# Archive result
DATE=$(date +%Y-%m-%d-%H%M%S)
tar -cvzpf $BACKUPTMP/backup-$DATE.tar.gz $BACKUPTMP

# Upload to S3 
# REPLACE THIS WITH A STORAGE OF YOUR CHOICE
aws s3 cp $BACKUPTMP/backup-$DATE.tar.gz s3://mybucket/myfolder

# Delete TMP directory
rm -r $BACKUPTMP
```

## Commands
Start: `systemct --user start public.service`  
Stop: `systemct --user stop public.service`  
Restart: `systemct --user restart public.service`  
Status/Output/Log: `systemct --user status public service`  
Follow Log: `tail -f /path/to/server/SquadGame/Saved/Logs/SquadGame.log`  

### Alias
If you do not want to type out the full command above each time it is beneficial to create a bash alias. To do so edit the `~/.bash_aliases` file and add the following content_

```
function sqserver() {
    systemctl --user $2 $1
}
```
Save the file and source it with the following command `. ~/.bashrc`. Now you can use the command like so:
```
sqserver public start
sqserver public status
sqserver public restart
sqserver public stop
```

## Crash dump
To create a crash dump Append `-fullcrashdump` in your units ExecStart startup command. **These dumps can get rather big** and will be stored at /path/to/server/SquadGame/Saved/Crashes
