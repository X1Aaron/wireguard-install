
source /etc/wireguard/wg.conf > /dev/null 2>&1

function installWireGuard () {
echo "Finding Public IP Address..."
PUBLIC_IP=`curl -s ifconfig.me`
echo "Public IP: $PUBLIC_IP"
echo "PUBLIC_IP=$PUBLIC_IP" >> /etc/wireguard/wg.conf
echo Server IP Address?
read SERVER_IP
echo "SERVER_IP: $SERVER_IP"
echo "SERVER_IP=$SERVER_IP" >> /etc/wireguard/wg.conf
echo "Adding Firewall Rules and Enabling Firewall..."
ufw allow ssh
ufw allow 51820/udp
ufw --force enable
echo "Installing WireGuard..."
add-apt-repository ppa:wireguard/wireguard -y
apt-get update -y
apt-get install linux-headers-`uname -r` -y
apt-get install wireguard -y
echo "Enabling IPv4 Forwarding..."
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sysctl -p
echo 1 > /proc/sys/net/ipv4/ip_forward
echo "Creating Folders and Files..."
mkdir /etc/wireguard
touch /etc/wireguard/wg.conf
mkdir /etc/wireguard/server/
mkdir /etc/wireguard/clients/
echo "Generating Server Keys..."
wg genkey | tee /etc/wireguard/server/private_key | wg pubkey > /etc/wireguard/server/public_key
SERVER_PUBLIC_KEY=`cat /etc/wireguard/server/public_key`
echo "SERVER_PUBLIC_KEY: $SERVER_PUBLIC_KEY"
echo "SERVER_PUBLIC_KEY=$SERVER_PUBLIC_KEY" >> /etc/wireguard/wg.conf
SERVER_PRIVATE_KEY=`cat /etc/wireguard/server/private_key`
echo "Creating Server .conf File..."
echo "[Interface]" >> /etc/wireguard/wg0.conf
echo "Address = $SERVER_IP/24" >> /etc/wireguard/wg0.conf
echo "PrivateKey = $SERVER_PRIVATE_KEY" >> /etc/wireguard/wg0.conf
echo "ListenPort = 51820" >> /etc/wireguard/wg0.conf
echo "PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE"
echo "PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE"
echo "Setting Permissions..."
chown -v root:root /etc/wireguard/wg0.conf
chmod -v 600 /etc/wireguard/wg0.conf
echo "Starting WireGuard..."
wg-quick up wg0
echo "Enabling WireGuard Service..."
systemctl enable wg-quick@wg0.service #Enable the interface at boot
echo "WireGuard Server Setup Complete!..."
echo ""
sudo wg show
echo ""

create_client
}

function create_client () {
echo Client Name?
read CLIENT_NAME
echo IP Address?
read CLIENT_IP
mkdir /etc/wireguard/clients/$CLIENT_NAME/
wg genkey | tee /etc/wireguard/clients/$CLIENT_NAME/private_key | wg pubkey > /etc/wireguard/clients/$CLIENT_NAME/public_key
CLIENT_PRIVATE_KEY=`cat /etc/wireguard/clients/$CLIENT_NAME/private_key`
CLIENT_PUBLIC_KEY=`cat /etc/wireguard/clients/$CLIENT_NAME/public_key`
echo "[Interface]" >> /etc/wireguard/clients/$CLIENT_NAME.conf
echo "Address = $CLIENT_IP/32" >> /etc/wireguard/clients/$CLIENT_NAME.conf
echo "PrivateKey = $CLIENT_PRIVATE_KEY" >> /etc/wireguard/clients/$CLIENT_NAME.conf
echo "" >> /etc/wireguard/clients/$CLIENT_NAME.conf
echo "[Peer]" >> /etc/wireguard/clients/$CLIENT_NAME.conf
echo "PublicKey = $SERVER_PUBLIC_KEY" >> /etc/wireguard/clients/$CLIENT_NAME.conf
echo "Endpoint = $PUBLIC_IP:51820" >> /etc/wireguard/clients/$CLIENT_NAME.conf
echo "AllowedIPs = 0.0.0.0/0" >> /etc/wireguard/clients/$CLIENT_NAME.conf
echo "" >> /etc/wireguard/wg0.conf
echo "[Peer]" >> /etc/wireguard/wg0.conf
echo "PublicKey = $CLIENT_PUBLIC_KEY" >> /etc/wireguard/wg0.conf
echo "AllowedIPs = $CLIENT_IP" >> /etc/wireguard/wg0.conf
wg-quick down wg0
wg-quick up wg0
sudo wg show
cat /etc/wireguard/clients/$CLIENT_NAME.conf
}

# Check if WireGuard is already installed
if [[ -e /etc/wireguard/wg0.conf ]]; then
echo "WireGuard is already installed!"
echo "To add a client run .wireguard-install add_client client-name IP"
echo "For Example: .wireguard-install add_client MacBook 10.0.0.16
exit
else
	installWireGuard
fi

$@
