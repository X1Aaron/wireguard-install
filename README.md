# WireGuard Installer for Ubuntu 18.04

This script will let you setup a simple, safer, faster and more modern VPN server in just a few minutes.

#Usage

First, get the script and make it executable :

curl -O https://raw.githubusercontent.com/aaronstuder/wireguard-install/master/wireguard-setup.sh
chmod +x wireguard-install.sh

Then run it :

./wireguard-install.sh

You need to run the script as root.

The first time you run it, you'll have to answer a few questions to setup your VPN server.

When WireGuard is installed, you can run the script again, and you will get the choice to :

    Add a client
    Remove a client
    Uninstall WireGuard

In /etc/wireguard/clients/, you will have .conf files. These are the client configuration files. Download them from your server and connect using your WireGuard client.
