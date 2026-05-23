#!/bin/bash
set -euo pipefail

# Run this on the openVPN_EC2 instance after the CloudFormation stack is created.
# It keeps the difficult OpenVPN setup as a manual student step instead of hiding it
# inside CloudFormation UserData.

CLIENT_NAME="${1:-mike-client}"
VPN_NET="10.8.0.0"
VPN_MASK="255.255.255.0"
VPC_CIDR="10.0.0.0"
VPC_MASK="255.255.0.0"

sudo dnf install -y openvpn iptables-services openssl

sudo mkdir -p /etc/openvpn/server /etc/openvpn/client-config /etc/openvpn/pki
cd /etc/openvpn/pki

sudo openssl genrsa -out ca.key 4096
sudo openssl req -x509 -new -nodes -key ca.key -sha256 -days 365 \
  -subj "/CN=CivicNexusVPN" -out ca.crt

sudo openssl genrsa -out server.key 2048
sudo openssl req -new -key server.key -subj "/CN=server" -out server.csr
sudo tee server.ext >/dev/null <<'EOF'
basicConstraints=CA:FALSE
keyUsage=digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth
subjectAltName=DNS:server
EOF
sudo openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out server.crt -days 365 -sha256 -extfile server.ext

sudo openssl genrsa -out "${CLIENT_NAME}.key" 2048
sudo openssl req -new -key "${CLIENT_NAME}.key" -subj "/CN=${CLIENT_NAME}" -out "${CLIENT_NAME}.csr"
sudo tee client.ext >/dev/null <<'EOF'
basicConstraints=CA:FALSE
keyUsage=digitalSignature
extendedKeyUsage=clientAuth
EOF
sudo openssl x509 -req -in "${CLIENT_NAME}.csr" -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out "${CLIENT_NAME}.crt" -days 365 -sha256 -extfile client.ext

sudo openssl dhparam -out dh.pem 2048
sudo openvpn --genkey secret ta.key

sudo cp ca.crt server.crt server.key dh.pem ta.key /etc/openvpn/server/
sudo cp ca.crt "${CLIENT_NAME}.crt" "${CLIENT_NAME}.key" ta.key /etc/openvpn/client-config/

sudo tee /etc/openvpn/server/server.conf >/dev/null <<EOF
port 1194
proto udp
dev tun
topology subnet
server ${VPN_NET} ${VPN_MASK}
push "route ${VPC_CIDR} ${VPC_MASK}"
keepalive 10 120
persist-key
persist-tun
ca ca.crt
cert server.crt
key server.key
dh dh.pem
tls-auth ta.key 0
auth SHA256
data-ciphers AES-256-GCM:AES-128-GCM:CHACHA20-POLY1305
user nobody
group nobody
status /var/log/openvpn-status.log
verb 3
explicit-exit-notify 1
EOF

echo 'net.ipv4.ip_forward = 1' | sudo tee /etc/sysctl.d/99-civicnexus-vpn.conf >/dev/null
sudo sysctl --system
sudo iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -d 10.0.0.0/16 -j MASQUERADE
sudo iptables-save | sudo tee /etc/sysconfig/iptables >/dev/null
sudo systemctl enable iptables
sudo systemctl restart iptables

TOKEN="$(curl -sS -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")"
PUBLIC_IP="$(curl -sS -H "X-aws-ec2-metadata-token: ${TOKEN}" \
  "http://169.254.169.254/latest/meta-data/public-ipv4")"

sudo tee "/home/ec2-user/civicnexus-vpn.ovpn" >/dev/null <<EOF
client
dev tun
proto udp
remote ${PUBLIC_IP} 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
auth SHA256
data-ciphers AES-256-GCM:AES-128-GCM:CHACHA20-POLY1305
verb 3
key-direction 1
<ca>
$(sudo cat /etc/openvpn/client-config/ca.crt)
</ca>
<cert>
$(sudo cat /etc/openvpn/client-config/${CLIENT_NAME}.crt)
</cert>
<key>
$(sudo cat /etc/openvpn/client-config/${CLIENT_NAME}.key)
</key>
<tls-auth>
$(sudo cat /etc/openvpn/client-config/ta.key)
</tls-auth>
EOF

sudo chown ec2-user:ec2-user /home/ec2-user/civicnexus-vpn.ovpn
sudo chmod 600 /home/ec2-user/civicnexus-vpn.ovpn
sudo systemctl enable openvpn-server@server
sudo systemctl restart openvpn-server@server

echo "OpenVPN is configured."
echo "Download this file to Windows:"
echo "/home/ec2-user/civicnexus-vpn.ovpn"
