# WireGuard Installer for Ubuntu 18.04

This script will let you setup a simple, safer, faster and more modern VPN server in just a few minutes.

## Usage

First, get the script and make it executable:
```
curl -O https://raw.githubusercontent.com/aaronstuder/wireguard-install/master/wireguard-install.sh
```
```
chmod +x wireguard-install.sh
```
Then run it :
```
./wireguard-install.sh install
```
You need to run the script as root.

To add a client run .wireguard-install add-client client-name IP

For Example:
```
./wireguard-install.sh add-client macbook 192.168.10.2
```
In /etc/wireguard/clients/, you will have .conf files. These are the client configuration files. Download them from your server and connect using the WireGuard client.

## To-Do
* IPv6
* Auto Set IP Address
* PiHole
* ens3/eth0/etc
