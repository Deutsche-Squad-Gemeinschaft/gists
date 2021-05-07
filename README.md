<div align="center">
    <h1>Gists</h1>
    <b>Since organizations can not have gists.</b>
    <hr>
    <a href="https://dsg-gaming.de">
        <img alt="Deutsche Squad Gemeinschaft" src="https://raw.githubusercontent.com/Deutsche-Squad-Gemeinschaft/gists/master/dsg-badge.svg">
    </a>
</div>

## Table of Contents  
* [Data](#data)
* [Tools](#tools)
* [Guides](#guides)

## Data
This repository contains various data related to server configuration that is being extracted from the squad dedicated server files. These files will be updated automatically once the squad dedicated server steam depot is being updated, in other terms **these files will/should always be up to date**.

The repository contains the following data:
* [Cleaned LayerRotation.cfg](https://github.com/Deutsche-Squad-Gemeinschaft/gists/tree/master/data/ServerConfig)
* [ServerComfig Folder](https://github.com/Deutsche-Squad-Gemeinschaft/gists/blob/master/data/LayerRotation.cfg)

## Tools
### Checkport
Just a small helper to check if a port is open and something is listening.
```
bash <(curl -s https://raw.githubusercontent.com/Deutsche-Squad-Gemeinschaft/gists/master/validateMapRotation.sh) IP PORT
```

### ValidateMapRotation
Bash only helper script to validate a LayerRotation. Will check against the cleaned LayerRotation.cfg in the data folder of this repository and can be extended with custom layers/maps.
```
bash <(curl -s https://raw.githubusercontent.com/Deutsche-Squad-Gemeinschaft/gists/master/validateMapRotation.sh) ./LayerRotation.cfg
```

## Guides
* [Server setup](https://github.com/Deutsche-Squad-Gemeinschaft/gists/blob/master/server-setup.md)
