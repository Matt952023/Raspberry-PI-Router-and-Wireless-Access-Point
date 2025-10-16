#!/bin/bash

LOG="/var/log/router-health.log"

echo "[$(date)] Checking wlan0 route and link..." >> $LOG

# Is wlan0 up?
if ! ip link show wlan0 | grep -q "state UP"; then
    echo "[$(date)] wlan0 is down. Restarting setup..." >> $LOG
    /usr/local/bin/setup-router.sh
    exit
fi

# Is default route via wlan0 missing?
if ! ip route | grep -q "default via 192.168.12.1 dev wlan0"; then
    echo "[$(date)] Default route missing or hijacked. Fixing..." >> $LOG
    /usr/local/bin/setup-router.sh
    exit
fi

# All good
echo "[$(date)] All OK." >> $LOG
