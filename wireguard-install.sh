
source /etc/wireguard/wg.conf > /dev/null 2>&1

function install () {
echo ""
echo "This system in completely updated and rebooted before proceeding"
echo ""
read -n1 -r -p "Press any key to continue... or CTRL + C to cancel"
echo "Finding Public IP Address..."
PUBLIC_IP=`curl -s ifconfig.me`
echo "Public IP: $PUBLIC_IP"
echo "PUBLIC_IP=$PUBLIC_IP" >> /etc/wireguard/wg.conf
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
echo "net.ipv4.ip_forward = 1 net.ipv6.conf.all.forwarding = 1" > /etc/sysctl.d/wg.conf
sysctl --system
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
echo "Address = 192.168.10.1/24" >> /etc/wireguard/wg0.conf
echo "PrivateKey = $SERVER_PRIVATE_KEY" >> /etc/wireguard/wg0.conf
echo "ListenPort = 51820" >> /etc/wireguard/wg0.conf
echo ""
PostUp = iptables -t nat -A POSTROUTING -o ens3 -j MASQUERADE; ip6tables -t nat -A POSTROUTING -o ens3 -j MASQUERADE >> /etc/wireguard/wg0.conf
PostDown = iptables -t nat -D POSTROUTING -o ens3 -j MASQUERADE; ip6tables -t nat -D POSTROUTING -o ens3 -j MASQUERADE >> /etc/wireguard/wg0.conf
echo ""
echo "Setting Permissions..."
chown -v root:root /etc/wireguard/wg0.conf
chmod -v 600 /etc/wireguard/wg0.conf
echo "Starting WireGuard..."
systemctl start wg-quick@wg0
echo "Enabling WireGuard Service..."
systemctl enable wg-quick@wg0
echo "WireGuard Server Setup Complete!..."
echo ""
sudo wg show
echo ""
echo "WireGuard is installed!"
echo "To add a client run ./wireguard-install.sh add-client client-name IP"
echo "For Example: ./wireguard-install.sh add-client macbook 192.168.10.2"
}

function add-client () {
echo ""
echo "Creating Directory - /etc/wireguard/clients/$1/"
mkdir /etc/wireguard/clients/$1/
echo ""
echo "Generating Client Keys..."
wg genkey | tee /etc/wireguard/clients/$1/private_key | wg pubkey > /etc/wireguard/clients/$1/public_key
CLIENT_PRIVATE_KEY=`cat /etc/wireguard/clients/$1/private_key`
CLIENT_PUBLIC_KEY=`cat /etc/wireguard/clients/$1/public_key`
echo ""
echo "Creating Client .conf File..."
echo "# $1" >> /etc/wireguard/clients/$1.conf
echo "[Interface]" >> /etc/wireguard/clients/$1.conf
echo "Address = $2/32" >> /etc/wireguard/clients/$1.conf
echo "PrivateKey = $CLIENT_PRIVATE_KEY" >> /etc/wireguard/clients/$1.conf
echo "" >> /etc/wireguard/clients/$1.conf
echo "[Peer]" >> /etc/wireguard/clients/$1.conf
echo "PublicKey = $SERVER_PUBLIC_KEY" >> /etc/wireguard/clients/$1.conf
echo "Endpoint = $PUBLIC_IP:51820" >> /etc/wireguard/clients/$1.conf
echo "AllowedIPs = 0.0.0.0/0" >> /etc/wireguard/clients/$1.conf
echo "Updating Server..."
echo "" >> /etc/wireguard/wg0.conf
echo "# $1" >> /etc/wireguard/wg0.conf
echo "[Peer]" >> /etc/wireguard/wg0.conf
echo "PublicKey = $CLIENT_PUBLIC_KEY" >> /etc/wireguard/wg0.conf
echo "AllowedIPs = $2/32,::/0" >> /etc/wireguard/wg0.conf
echo ""
echo "Restarting WireGuard..."
echo ""
wg-quick down wg0
echo ""
wg-quick up wg0
echo ""
sudo wg show
echo ""
echo "### /etc/wireguard/clients/$1.conf ####"
echo ""
cat /etc/wireguard/clients/$1.conf
echo ""
echo "### /etc/wireguard/clients/$1.conf ####"
echo ""
}

$@
