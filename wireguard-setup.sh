
function installQuestions () {
	echo "Welcome to the WireGuard installer!"
	echo "The git repository is available at: https://github.com/xxx/wireguard-install"
	echo ""

	echo "I need to ask you a few questions before starting the setup."
	echo "You can leave the default options and just press enter if you are ok with them."
	echo ""
	echo "I need to know the IPv4 address of the network interface you want OpenVPN listening to."
	echo "Unless your server is behind NAT, it should be your public IPv4 address."

	# Detect public IPv4 address and pre-fill for the user
	IP=$(ip addr | grep 'inet' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1)
	read -rp "IP address: " -e -i "$IP" IP
	# If $IP is a private IP address, the server must be behind NAT
	if echo "$IP" | grep -qE '^(10\.|172\.1[6789]\.|172\.2[0-9]\.|172\.3[01]\.|192\.168)'; then
		echo ""
		echo "It seems this server is behind NAT. What is its public IPv4 address or hostname?"
		echo "We need it for the clients to connect to the server."
		until [[ "$PUBLICIP" != "" ]]; do
			read -rp "Public IPv4 address or hostname: " -e PUBLICIP
		done
	fi

	echo ""
	echo "Checking for IPv6 connectivity..."
	echo ""
	# "ping6" and "ping -6" availability varies depending on the distribution
	if type ping6 > /dev/null 2>&1; then
		PING6="ping6 -c3 ipv6.google.com > /dev/null 2>&1"
	else
		PING6="ping -6 -c3 ipv6.google.com > /dev/null 2>&1"
	fi
	if eval "$PING6"; then
		echo "Your host appears to have IPv6 connectivity."
		SUGGESTION="y"
	else
		echo "Your host does not appear to have IPv6 connectivity."
		SUGGESTION="n"
	fi
	echo ""
	# Ask the user if they want to enable IPv6 regardless its availability.
	until [[ $IPV6_SUPPORT =~ (y|n) ]]; do
		read -rp "Do you want to enable IPv6 support (NAT)? [y/n]: " -e -i $SUGGESTION IPV6_SUPPORT
	done
	
	echo ""
	echo "Okay, that was all I needed. We are ready to setup your wireguard server now."
	echo "You will be able to generate a client at the end of the installation."
	read -n1 -r -p "Press any key to continue..."
}

function installWireGuard () {

ufw allow ssh
ufw allow 51820/udp
ufw enable
add-apt-repository ppa:wireguard/wireguard -y
apt-get update -y
apt-get install wireguard -y
apt-get install linux-headers-`uname -r` -y
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sysctl -p
echo 1 > /proc/sys/net/ipv4/ip_forward
Umask 077
wg genkey | tee server_private_key | wg pubkey > server_public_key
wg genkey | tee client_private_key | wg pubkey > client_public_key
cat <<EOF | /etc/wireguard/wg0.conf
[Interface]
Address = 192.168.5.1/24
PrivateKey = <SERVER_PRIVATE_KEY>
ListenPort = 51820

[Peer]
PublicKey = <CLIENT_PUBLIC_KEY>
AllowedIPs = 192.168.5.2/32
EOF

cat <<EOF | wg0-client.conf
[Interface]
Address = 192.168.5.2/32
PrivateKey = <CLIENT_PRIVATE_KEY>

[Peer]
PublicKey = <SERVER_PUBLIC_KEY>
Endpoint = <SERVER_PUBLIC_IP>:51820
AllowedIPs = 0.0.0.0/0
}

function manageMenu () {
	clear
	echo "Welcome to WireGuard-install!"
	echo "The git repository is available at: https://github.com/xxx/wireguard-install"
	echo ""
	echo "It looks like WireGuard is already installed."
	echo ""
	echo "What do you want to do?"
	echo "   1) Add a new peer"
	echo "   2) Revoke existing peer"
	echo "   3) Remove WireGuard"
	echo "   4) Exit"
	until [[ "$MENU_OPTION" =~ ^[1-4]$ ]]; do
		read -rp "Select an option [1-4]: " MENU_OPTION
	done

	case $MENU_OPTION in
		1)
			newClient
		;;
		2)
			revokeClient
		;;
		3)
			removeOpenVPN
		;;
		4)
			exit 0
		;;
	esac
}

# Check if OpenVPN is already installed
if [[ -e /etc/wireguard/wg0.conf ]]; then
	manageMenu
else
	installWireGuard
fi
