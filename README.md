# Wireguard Install Script

WireGuard is an extremely simple yet fast and modern VPN that utilizes state-of-the-art cryptography. It aims to be faster, simpler, leaner, and more useful than IPsec, while avoiding the massive headache. It intends to be considerably more performant than OpenVPN. WireGuard is designed as a general purpose VPN for running on embedded interfaces and super computers alike, fit for many different circumstances. Initially released for the Linux kernel, it is now cross-platform and widely deployable. It is currently under heavy development, but already it might be regarded as the most secure, easiest to use, and simplest VPN solution in the industry.

WireGuard installer for Ubuntu 18.04

This script will let you setup a simple, safer, faster and more modern VPN server in just a few minutes.

#Usage

First, get the script and make it executable :

curl -O https://raw.githubusercontent.com/Angristan/openvpn-install/master/openvpn-install.sh
chmod +x openvpn-install.sh

Then run it :

./openvpn-install.sh

You need to run the script as root and have the TUN module enabled.

The first time you run it, you'll have to follow the assistant and answer a few questions to setup your VPN server.

When OpenVPN is installed, you can run the script again, and you will get the choice to :

    Add a client
    Remove a client
    Uninstall OpenVPN

In your home directory, you will have .ovpn files. These are the client configuration files. Download them from your server and connect using your favorite OpenVPN client.


This script automatically setups WireGuard in a "Road Warrior Scenario" and generates client .conf files for quick and easy deployment.
