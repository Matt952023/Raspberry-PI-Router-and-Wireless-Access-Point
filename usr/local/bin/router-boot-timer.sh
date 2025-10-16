#!/bin/bash

LOG="/var/log/router-boot-timer.log"
echo "==== Boot Timer: $(date) ====" >> $LOG

log_time() {
    echo "[$(date +'%H:%M:%S')] $1" >> $LOG
}

START=$(date +%s)

log_time "Script started"

# Wait for wlan0 to get an IP
for i in {1..30}; do
    if ip -4 addr show wlan0 | grep -q "inet "; then
        log_time "wlan0 got IP: $(ip -4 addr show wlan0 | grep inet | awk '{print $2}')"
        break
    fi
    sleep 1
done

# Wait for wlan0 default route
for i in {1..10}; do
    if ip route | grep -q "default via 192.168.12.1 dev wlan0"; then
        log_time "Default route via wlan0 ready"
        break
    fi
    sleep 1
done

# Wait for hostapd to start
for i in {1..10}; do
    if systemctl is-active --quiet hostapd; then
        log_time "hostapd is active"
        break
    fi
    sleep 1
done

# Wait for dnsmasq to start
for i in {1..10}; do
    if systemctl is-active --quiet dnsmasq; then
        log_time "dnsmasq is active"
        break
    fi
    sleep 1
done

END=$(date +%s)
DURATION=$((END - START))
log_time "Setup completed in $DURATION seconds"
echo "====" >> $LOG
