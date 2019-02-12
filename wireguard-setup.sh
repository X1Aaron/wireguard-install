
function installQuestions () {

	echo "Welcome to the WireGuard installer!"
	echo "The git repository is available at: https://github.com/xxx/wireguard-install"
	echo ""

PUBLIC_IP=`curl -s ifconfig.me`
echo "Public IP: $PUBLIC_IP"
echo "PUBLIC_IP=$PUBLIC_IP" >> /etc/wireguard/wg.conf

	echo ""
	echo "Okay, that was all I needed. We are ready to setup your wireguard server now."
	echo "You will be able to generate a client at the end of the installation."
	read -n1 -r -p "Press any key to continue..."
}

function installWireGuard () {
installQuestions
apt update -y
apt upgrade -y
ufw allow ssh
ufw allow 51820/udp
ufw --force enable
add-apt-repository ppa:wireguard/wireguard -y
apt-get update -y
apt-get install linux-headers-`uname -r` -y
apt-get install wireguard -y
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sysctl -p
echo 1 > /proc/sys/net/ipv4/ip_forward


umask 077
mkdir /etc/wireguard/server/
mkdir /etc/wireguard/clients/
wg genkey | tee /etc/wireguard/keys/server/private_key | wg pubkey > /etc/wireguard/keys/server/public_key



echo "[Interface]" >> /etc/wireguard/wg0.conf
echo "Address = 192.168.5.1/24" >> /etc/wireguard/wg0.conf
echo "PrivateKey = <SERVER_PRIVATE_KEY>" >> /etc/wireguard/wg0.conf
echo "ListenPort = 51820" >> /etc/wireguard/wg0.conf


# start wiregaurd + permissions + service

create_client
}

function create_client () {

wg genkey | tee /etc/wireguard/keys/clients/$CLIENT_NAME/private_key | wg pubkey > /etc/wireguard/keys/clients/$CLIENT_NAME/public_key
echo "[Interface]" >> /etc/wireguard/clients/$CLIENT_NAME.conf
echo "Address = 192.168.5.2/32" >> /etc/wireguard/clients/$CLIENT_NAME.conf
echo "PrivateKey = <CLIENT_PRIVATE_KEY>" >> /etc/wireguard/clients/$CLIENT_NAME.conf
echo "" >> /etc/wireguard/clients/$CLIENT_NAME.conf
echo "[Peer]" >> /etc/wireguard/clients/$CLIENT_NAME.conf
echo "PublicKey = <SERVER_PUBLIC_KEY>" >> /etc/wireguard/clients/$CLIENT_NAME.conf
echo "Endpoint = <SERVER_PUBLIC_IP>:51820" >> /etc/wireguard/clients/$CLIENT_NAME.conf
echo "AllowedIPs = 0.0.0.0/0" >> /etc/wireguard/clients/$CLIENT_NAME.conf
echo "" >> /etc/wireguard/wg0.conf
echo "[Peer]" >> /etc/wireguard/wg0.conf
echo "PublicKey = <CLIENT_PUBLIC_KEY>" >> /etc/wireguard/wg0.conf
echo "AllowedIPs = 192.168.5.2/32" >> /etc/wireguard/wg0.conf
}

function manageMenu () {

	clear
	echo "Welcome to WireGuard-install!"
	echo "The git repository is available at: https://github.com/xxx/wireguard-install"
	echo ""
	echo "It looks like WireGuard is already installed."
	echo ""
	echo "What do you want to do?"
	echo "   1) Add a New Client"
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

