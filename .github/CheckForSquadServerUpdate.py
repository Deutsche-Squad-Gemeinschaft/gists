#!/usr/bin/env python
import steam
from steam.client import SteamClient
from steam.client.cdn import CDNClient
import os.path

# Configure OS (Linux/Windows)
system = "Linux"

# Initialize SteamClient and login
client = SteamClient()
client.anonymous_login()

# Initialize CDN client
mycdn = CDNClient(client)

# Try to find the correct depot
needle = False
for depot in mycdn.get_manifests(403240):
    if depot.name == 'Squad Dedicated Server Depot ' + system:
        needle = depot
        break

# Check if the depot information could be found
if needle:
    # Get the last update / creation time as string
    lastUpdate = str(needle.creation_time)
    
    # Initialize a default oldLastUpdate
    oldLastUpdate = 0
    
    # Try to read the previous lastUpdate for the desired system from cache file
    if os.path.isfile('./data/lastUpdate' + system):
        with open('./data/lastUpdate' + system, "r") as f:
            oldLastUpdate = f.read()
    
    # If we have a different creation time we also have an update
    if lastUpdate != oldLastUpdate:
        # Update lastUpdate file
        with open('./data/lastUpdate' + system, "a+") as f:
            f.truncate(0)
            f.write(lastUpdate)

        print('Update found.')
    else:
        print('No update found.')
else:
    print('Could not find the correct depot!')
    exit(1)
