#!/bin/bash
echo "Applying iptables"

# DROP INPUT
iptables -P INPUT DROP
ip6tables -P INPUT DROP 1>&- 2>&-

# ACCEPT INPUT to tunnel adapter
iptables -A INPUT -i tun0 -j ACCEPT 				  # all incoming traffic from VPN
iptables -A INPUT -p $VPN_PROTO -s $VPN_SERVER_IP -j ACCEPT # over default adapter, ONLY FROM VPN gateway

# DROP OUTPUT
iptables -P OUTPUT DROP
ip6tables -P OUTPUT DROP 1>&- 2>&-

# accept output to tunnel adapter
iptables -A OUTPUT -o tun0 -j ACCEPT 				   # all outgoing traffic to VPN
iptables -A OUTPUT -p $VPN_PROTO -d $VPN_SERVER_IP -j ACCEPT # over default adapter, ONLY TO VPN gateway

# WebInterface
iptables -A INPUT -i eth0 -p tcp --dport $WEBINTERFACE_PORT -s $LOCAL_SUBNET  -j ACCEPT
iptables -A OUTPUT -o eth0 -p tcp --sport $WEBINTERFACE_PORT -d $LOCAL_SUBNET -j ACCEPT

echo "[info] iptables defined as follows..."
echo "--------------------"
iptables -S
echo "--------------------"

# get VPN Username and Password
printf "$VPN_USERNAME\n$VPN_PASSWORD" > /config/openvpn/credentials.conf
chmod 600 /config/openvpn/credentials.conf


echo "[info] Starting OpenVPN..."
cd /config/openvpn
exec openvpn --config /config/openvpn/profile.ovpn &

exec /usr/bin/qbittorrent-nox --profile=/config &

sleep infinity
	