ECHO_GREEN="echo -e \e[32m" #SUCCESS
NC="\e[0m" # clears color

source /etc/wireguard/wg.conf > /dev/null 2>&1

function install () {
echo ""
$ECHO_GREEN"This system in completely updated and rebooted before proceeding"$NC
echo ""
read -n1 -r -p "Press any key to continue... or CTRL + C to cancel"
echo ""
$ECHO_GREEN"Finding Public IP Address..."$NC
echo ""
PUBLIC_IP=`curl -s ifconfig.me`
echo "Public IP: $PUBLIC_IP"
echo "PUBLIC_IP=$PUBLIC_IP" >> /etc/wireguard/wg.conf
$ECHO_GREEN"Adding Firewall Rules and Enabling Firewall..."$NC
ufw allow ssh
ufw allow 51820/udp
ufw --force enable
echo ""
$ECHO_GREEN"Installing WireGuard..."$NC
add-apt-repository ppa:wireguard/wireguard -y
apt-get update -y
apt-get install linux-headers-`uname -r` -y
apt-get install wireguard -y
echo ""
$ECHO_GREEN"Enabling IPv4 Forwarding..."$NC
echo "net.ipv4.ip_forward = 1 net.ipv6.conf.all.forwarding = 1" > /etc/sysctl.d/wg.conf
sysctl --system
echo ""
echo "Creating Folders and Files..."$NC
mkdir /etc/wireguard
touch /etc/wireguard/wg.conf
mkdir /etc/wireguard/server/
mkdir /etc/wireguard/clients/
echo ""
$ECHO_GREEN"Generating Server Keys..."$NC
wg genkey | tee /etc/wireguard/server/private_key | wg pubkey > /etc/wireguard/server/public_key
SERVER_PUBLIC_KEY=`cat /etc/wireguard/server/public_key`
echo "SERVER_PUBLIC_KEY: $SERVER_PUBLIC_KEY"
echo "SERVER_PUBLIC_KEY=$SERVER_PUBLIC_KEY" >> /etc/wireguard/wg.conf
SERVER_PRIVATE_KEY=`cat /etc/wireguard/server/private_key`
$ECHO_GREEN"Creating Server .conf File..."$NC
echo "[Interface]" >> /etc/wireguard/wg0.conf
echo "Address = 192.168.10.1/24" >> /etc/wireguard/wg0.conf
echo "PrivateKey = $SERVER_PRIVATE_KEY" >> /etc/wireguard/wg0.conf
echo "ListenPort = 51820" >> /etc/wireguard/wg0.conf
echo ""  >> /etc/wireguard/wg0.conf
echo "PostUp = iptables -t nat -A POSTROUTING -o ens3 -j MASQUERADE; ip6tables -t nat -A POSTROUTING -o ens3 -j MASQUERADE" >> /etc/wireguard/wg0.conf
echo "PostDown = iptables -t nat -D POSTROUTING -o ens3 -j MASQUERADE; ip6tables -t nat -D POSTROUTING -o ens3 -j MASQUERADE" >> /etc/wireguard/wg0.conf
echo ""  >> /etc/wireguard/wg0.conf
echo ""
$ECHO_GREEN"Setting Permissions..."$NC
chown -v root:root /etc/wireguard/wg0.conf
chmod -v 600 /etc/wireguard/wg0.conf
echo ""
$ECHO_GREEN"Starting WireGuard..."$NC
systemctl start wg-quick@wg0
echo ""
$ECHO_GREEN"Enabling WireGuard Service..."$NC
systemctl enable wg-quick@wg0
echo ""
$ECHO_GREEN"WireGuard Server Setup Complete!..."$NC
echo ""
sudo wg show
echo ""
$ECHO_GREEN"WireGuard is installed!"$NC
echo ""
$ECHO_GREEN"To add a client run ./wireguard-install.sh add-client client-name IP"$NC
$ECHO_GREEN"For Example: ./wireguard-install.sh add-client macbook 192.168.10.2"$NC
}

function add-client () {
echo ""
$ECHO_GREEN"Creating Directory - /etc/wireguard/clients/$1/"$NC
mkdir /etc/wireguard/clients/$1/
echo ""
$ECHO_GREEN"Generating Client Keys..."$NC
wg genkey | tee /etc/wireguard/clients/$1/private_key | wg pubkey > /etc/wireguard/clients/$1/public_key
CLIENT_PRIVATE_KEY=`cat /etc/wireguard/clients/$1/private_key`
CLIENT_PUBLIC_KEY=`cat /etc/wireguard/clients/$1/public_key`
echo ""
$ECHO_GREEN"Creating Client .conf File..."$NC
echo "# $1" >> /etc/wireguard/clients/$1.conf
echo "[Interface]" >> /etc/wireguard/clients/$1.conf
echo "Address = $2/32" >> /etc/wireguard/clients/$1.conf
echo "PrivateKey = $CLIENT_PRIVATE_KEY" >> /etc/wireguard/clients/$1.conf
echo "" >> /etc/wireguard/clients/$1.conf
echo "[Peer]" >> /etc/wireguard/clients/$1.conf
echo "PublicKey = $SERVER_PUBLIC_KEY" >> /etc/wireguard/clients/$1.conf
echo "Endpoint = $PUBLIC_IP:51820" >> /etc/wireguard/clients/$1.conf
echo "AllowedIPs = 0.0.0.0/0" >> /etc/wireguard/clients/$1.conf
echo ""
$ECHO_GREEN"Updating Server..."$NC
echo "" >> /etc/wireguard/wg0.conf
echo "# $1" >> /etc/wireguard/wg0.conf
echo "[Peer]" >> /etc/wireguard/wg0.conf
echo "PublicKey = $CLIENT_PUBLIC_KEY" >> /etc/wireguard/wg0.conf
echo "AllowedIPs = $2/32,::/0" >> /etc/wireguard/wg0.conf
echo ""
$ECHO_GREEN"Restarting WireGuard..."$NC
echo ""
wg-quick down wg0
echo ""
wg-quick up wg0
echo ""
sudo wg show
echo ""
$ECHO_GREEN"### /etc/wireguard/clients/$1.conf ####"$NC
echo ""
cat /etc/wireguard/clients/$1.conf
echo ""
$ECHO_GREEN"### /etc/wireguard/clients/$1.conf ####"$NC
echo ""
}

$@
