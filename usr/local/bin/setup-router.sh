#!/bin/bash

LOG_FILE="/var/log/setup-router.log"
exec > >(tee -a "$LOG_FILE") 2>&1
echo "==== Starting router setup: $(date) ===="

# ✅ Wait for wlan0 to have IP and default route
echo "[*] Waiting for wlan0 to be connected and routed..."
for i in {1..20}; do
    if ip route | grep -q "default via 192.168.12.1 dev wlan0"; then
        echo "[+] wlan0 is up with default route"
        break
    fi
    sleep 1
done

# 🧹 Remove eth0 default route if it appeared (e.g., from SSH handshake)
if ip route | grep -q "default via 192.168.10.100 dev eth0"; then
    echo "[*] Removing unwanted default route from eth0..."
    ip route del default via 192.168.10.100 dev eth0
fi

# ❌ Stop any existing AP services
systemctl stop hostapd
systemctl stop dnsmasq

# 🔁 Recreate ap0 interface in AP mode
ip link set ap0 down 2>/dev/null
iw dev ap0 del 2>/dev/null
iw dev wlan0 interface add ap0 type __ap
ip link set ap0 up
ip addr flush dev ap0
ip addr add 192.168.50.1/24 dev ap0

# 🚀 Start access point services
systemctl start hostapd
systemctl restart dnsmasq

# 🔓 Enable IP forwarding
sysctl -w net.ipv4.ip_forward=1

# 🔐 Flush and reapply NAT rules
iptables -F
iptables -t nat -F
iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
iptables -A FORWARD -i ap0 -o wlan0 -j ACCEPT
iptables -A FORWARD -i wlan0 -o ap0 -m state --state RELATED,ESTABLISHED -j ACCEPT

# 💾 Save rules for persistence
netfilter-persistent save

# 🔁 Final default route fix (just in case)
echo "[*] Verifying default route..."
ip route replace default via 192.168.12.1 dev wlan0

# ✅ Final routing table
echo "[✓] Final routing table:"
ip r

echo "==== Router setup complete ===="

/usr/local/bin/router-boot-timer.sh &
