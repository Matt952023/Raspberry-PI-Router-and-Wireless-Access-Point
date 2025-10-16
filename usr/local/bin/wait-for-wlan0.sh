#!/bin/bash

echo "[*] Waiting for wlan0 to have IP and route..."
for i in {1..30}; do
    if ip route | grep -q "default via 192.168.12.1 dev wlan0"; then
        echo "[+] wlan0 default route is ready"
        exit 0
    fi
    sleep 2
done

echo "[!] wlan0 never came up — routing will fail"
exit 1
