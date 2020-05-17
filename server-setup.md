This guide shows a very simple automated Squad server setup on Linux using FOSS.
It hadles automated restarts, updates, backups, mods and cpu affinity.

Requirements:
- Linux
- Cron
- SystemD
- [AWS CLI](https://aws.amazon.com/de/cli/) (Optional Backups)
- [gcore](http://man7.org/linux/man-pages/man1/gcore.1.html) (Optional Memory Dumps)
  - `sudo apt i gdm -y`

## Using a Service
Using a [service/daemon](https://en.wikipedia.org/wiki/Daemon_(computing)) for our server and systemd to control it does give us a lot of what we need for an automated Squad server setup: start/stop/restart commands, auto-restart, start after boot, adjusting the CPU Affinity and [much more](https://www.freedesktop.org/software/systemd/man/systemd.unit.html#Wants=).
To create the service, navigate to `/etc/systemd/system/` and create a new service file and paste the contents below:  

**squad.service**
```
[Unit]
Description=Deutsche Squad Gemeinschaft: Public - https://dsg-gaming.de
After=caddy.service

[Service]
CPUAffinity=6 7
WorkingDirectory=/path/to/install/has/to/end/with/server
User=squad
Type=simple
TimeoutSec=300
ExecStartPre=/path/to/setup/script.sh
ExecStart=/path/to/install/has/to/end/with/server/SquadGameServer.sh Port=7787 QueryPort=27165 FIXEDMAXPLAYERS=80 RANDOM=NONE
ExecStop=/bin/kill -2 $MAINPID
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
```
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

**setup.sh (example)**
```bash
#!/bin/bash
# Configure
$SERVERDIR=/path/to/serverdir

# Update the game
/usr/games/steamcmd +login anonymous +force_install_dir $SERVERDIR/server +app_update 403240 validate +quit

# Uninstall a mod
rm -r $SERVERDIR/server/SquadGame/Plugins/Mods/$MODID

# Install a mod
/usr/games/steamcmd +login anonymous +force_install_dir $SERVERDIR/server +workshop_download_item 393380 $MODID +quit
cp -R /$SERVERDIR/server/steamapps/workshop/content/393380/$MODID  $SERVERDIR/server/SquadGame/Plugins/Mods/

```
**You may notice that to install a new server it is enough to execute the setup.sh once.**

## Automatic Restart & Backup
In order to automatically restart and backup the server i use Cron. This only requires to write the according lines into your Crontab.
**Remember that each user on linux has it's own crontab!** You can open and edit your crontab by using the command `crontab -e`, just edit it to your needs.
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
0 5 * * * /usr/sbin/service squad restart

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

# Copy the setup script and log
cp $SERVERDIR/setup.sh $BACKUPTMP/

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
Start: `sudo service squad start`  
Stop: `sudo service squad stop`  
Restart: `sudo service squad restart`  
Status/Output/Log: `sudo service squad status`  

Follow Log: `tail -f /path/to/server/SquadGame/Saved/Logs/SquadGame.log`  
Create dump: `gcore -o /path/to/dump $(systemctl show --property MainPID --value squad)`
