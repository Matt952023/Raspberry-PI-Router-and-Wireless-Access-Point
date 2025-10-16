Matthew Zhang

# **Abstract**

# **Introduction**

In this demonstration, I will convert a Raspberry PI 4 Model B into a functional NAT router with a wireless access point for devices to connect. The main goal of this project is to take my primary home network and pass it through my Raspberry PI router and allow other devices to connect to the Raspberry PI through the access point gateway. The following sections will go through the process of converting a Raspberry PI into a router and giving some background information regarding network configuration. It will also go into detail of preserving router configuration on boot through bash scripting. Reliability and troubleshooting tips are also discussed at the end of this documentation.

# **Setup**

Before starting anything make sure to enter the Raspberry PI’s system settings and enter geographical location to avoid broadcasting on an illegal transmission. In order to change the location, first enter the raspberry system configuration interface:

**`sudo raspi-config`**

Next, enter “System Options” and select “Wireless LAN”. Select the country location for the Raspberry PI.

## **Package Installation**

Firstly, make sure the Raspberry PI’s packages are up to date with the command:

**`sudo apt update`**

Next, we will be installing several packages required to convert our Raspberry PI into a working router.

These packages are:

* **`hostapd -`** a user space daemon that implements access points and authentication servers. In our demonstration, the purpose is to create an access point or wireless network that appears in a device’s list of networks and enforce its security. A daemon is a service that runs in the background.  
* **`dnsmasq -`** offers a lightweight DHCP server with a DNS forwarder. DNS or Domain Name System is a system which allows website domains to be converted into IP (Internet Protocol) addresses. It is responsible for handing IPs, gateway, and DNS for clients connecting to the wireless access point.  
* **`dhcpcd5 -`** a DHCP client Daemon for the Raspberry PI itself. The purpose of DHCP or Dynamic Host Configuration Protocol is to request an IP, default route, and DNS from the upstream network. This is done through a wireless local area network or WLAN.  
* **`iptables -`** userspace command-line program used to configure the packet filtering. Used to allow packet forwarding between the access point and WLAN.

These packages can be installed with these commands:

**`sudo apt-get install hostapd`**  
**`sudo apt-get install dnsmasq`**  
**`sudo apt-get install dhcpcd5`**  
**`sudo DEBIAN_FRONTEND=noninteractive apt install -y netfilter-persistent iptables-persistent`**

The package, **`iptables`**, requires additional options tailored to our interests:

* **`sudo`**  
  * run command with superuse (root) privileges  
* **`DEBIAN_FRONTEND=noninteractive`**  
  * Avoid interactive prompts and only use default configurations  
* **`apt install`**  
  * Install using Debian’s package manager: APT or Advanced Package Tool  
* **`-y`**  
  * Assume “yes” to APT’s confirmation prompts  
* **`netfilter-persistent`**  
  * Load, flush and save netfilter firewall rulesets through the usage of other plugins.  
* **`iptables-persistent`**  
  * Iptables plugin used to save store packet filtering rules at boot

Enable the following services with the following commands:

* **`sudo systemctl unmask hostapd.service`**  
* **`sudo systemctl enable hostapd.service`**  
* **`sudo systemctl enable dnsmasq`**  
* **`sudo systemctl enable dhcpcd.service --now`**

Note that hostapd is masked by default and will have to be unmasked in order to be used.

### **What is systemctl?** 

The **`systemctl`** command is a useful tool for managing services or programs inside Linux. The **`systemctl`** command communicates with **systemd**, software that manages different parts of the Linux operating system, and can start or stop services.

The “--now” option means that **`systemctl`** will start the **dhcpcd** service on reboot immediately.

# **Configuration Files**

A number of various configuration files for the services we have installed requires some changes. Many of these files will be found in the **`/etc/`** directory because that is where configuration files are stored on the Linux file system.

## **AP Configuration**

Edit the AP configuration through this command:

**`sudo nano /etc/sysctl.d/routed-ap.conf`**

Add this single line to the file:

**`net.ipv4.ip_forward=1`**

This line says we will forward IPv4 addresses between the wireless access point and the router.

Next, create the Access Point (AP) interface with the following commands:  
**`sudo iw dev wlan0 interface add ap0 type __ap`**   
**`sudo ip link set ap0 up`**   
**`sudo ip addr add 192.168.50.1/24 dev ap0`**

This set of commands creates a new wireless access point for client devices to connect with my Raspberry PI router:

* **`sudo iw dev wlan0 interface add ap0 type __ap`**  
  * Makes a **virtual wireless interface** called **ap0** on the same physical radio as **`wlan0`**, with the **AP (access-point) mode**. This is what lets one Wi-Fi chip do two jobs at once: **`wlan0`** stays a client (uplink) while **ap0** is the AP (downlink). Your adapter/driver must support **AP mode** and, if you want an AP+client simultaneously, the right **interface combinations** (check with **`iw list`**).  
* **`sudo ip link set ap0 up`**  
  * **Brings the interface up** (activates it). Until an interface is “up,” the kernel won’t pass frames through it. This is the standard **`iproute2`** way to enable a network device  
* **`sudo ip addr add 192.168.50.1/24 dev ap0`**  
  * **Assigns an IPv4 address** (the Pi’s gateway IP) to **ap0** with a **/24** prefix (255.255.255.0). Clients on your AP will live in the same subnet (e.g., 192.168.50.10–100 from **`dnsmasq`**) and use **192.168.50.1** as their default gateway.

## **DNSMASQ Configuration**

Edit the **`dnsmasq.conf`** file with the command:

**`sudo nano /etc/dnsmasq.conf`**

Add these lines to the configuration file:

**`interface=ap0`**  
**`dhcp-range=192.168.50.10,192.168.50.100,255.255.255.0,300d`**

These lines determines the configuration of the wireless access point

* **`interface=ap0`**  
  * Tells dnsmasq to only operate on the ap0 interface  
* **`dhcp-range=192.168.50.10,192.168.50.100,255.255.255.0,300d`**  
  * Gives the range of usable addresses:  
    * 192.168.50.10 → 192.168.50.100  
  * “**`255.255.255.0`**” is the netmask or subnet mask  
    * The final zero means the subnet mask can be anywhere from 192.168.10.0 to 192.168.10.255  
  * **`300d = lease time`**  
    * How long DHCP configurations will last for clients  
    * Things like IP addresses will last until the lease expires

## **HostAPD Configuration**

The hostAPD configuration file is used to set up the network settings for our wireless access point. To access the file, use this command:

**`sudo nano /etc/hostapd/hostapd.conf`**

Here, the settings will be applied to the file as such:  
**`country_code=US`**  
**`interface=ap0`**  
**`ssid=[Network Name]`**  
**`hw_mode=a`**  
**`channel=40`**  
**`wmm_enabled=1`**  
**`ieee80211d=1`**  
**`ieee80211n=1`**  
**`ieee80211ac=1`**  
**`auth_algs=1`**  
**`wpa=2`**  
**`wpa_passphrase=[Network Password]`**  
**`wpa_key_mgmt=WPA-PSK`**  
**`rsn_pairwise=CCMP`**  
**`ap_max_inactivity=600`**

Here is what all these options mean:

* **country\_code=US**  
  * Tells hostapd your regulatory region so it only uses **legal channels/power** for the U.S. (required; affects which channels are allowed).  
* **interface=ap0**  
  * Which network interface to turn into the AP (your virtual AP interface).  
* **ssid=\[Network Name\]**  
  * The **network name** you’ll see on phones/laptops when attempting to connect with a network.  
* **hw\_mode=a**  
  * Use the **5 GHz band** (802.11a family).  
  * `g` would be 2.4 GHz; `a` \= 5 GHz.  
* **channel=40**  
  * Pick **channel 40** in 5 GHz (center ≈ 5200 MHz).  
  * Tip: channels **36/40/44/48** are common, non-DFS (fewer radar checks). Must be legal for your country. Be careful not to pick a channel that is already in use nearby.  
* **wmm\_enabled=1**  
  * Enable **Wi-Fi Multimedia (QoS)**. Required for 802.11n/ac high throughput and helps with voice/video.  
* **ieee80211d=1**  
  * Advertise the **country/regulatory info** to clients (pairs with **`country_code`**; helps clients behave legally).  
* **ieee80211n=1**  
  * Enable **802.11n (HT)** features (MIMO/aggregation on 2.4/5 GHz). On 5 GHz it just means HT features are on.  
* **ieee80211ac=1**  
  * Enable **802.11ac (VHT)** features (faster 5 GHz).  
* **auth\_algs=1**  
  * Use **Open System** auth (normal for WPA/WPA2). Avoids legacy WEP “shared key” auth.  
* **wpa=2**  
  * Turn on **WPA2 (RSN)** security mode. (WPA1 would be `1`; you don’t want that.)  
* **wpa\_passphrase=\[Password\]**  
  * Your network’s **Wi-Fi password** that devices are required to enter in order to connect with the wireless access point.  
  * Keep file permissions tight: **`sudo chmod 600 /etc/hostapd/hostapd.conf`**.  
* **wpa\_key\_mgmt=WPA-PSK**  
  * Use **pre-shared key** authentication (home/SMB standard).  
* **rsn\_pairwise=CCMP**  
  * Use **AES-CCMP** encryption (the secure default for WPA2). Don’t use TKIP.  
* **ap\_max\_inactivity=600**  
  * If a client is silent for **600 seconds (10 min)**, disconnect it. Frees resources and cleans up stale associations.

## **DHCPCD Configuration**

Configure the configuration file for the DHCP client daemon by editing the file with the command:

**`sudo nano /etc/dhcpcd.conf`**

Inside, configure the file with the following:

**`# Wireless Access Point (ap0) with static IP`**  
**`interface ap0`**  
    **`metric 100`**  
    **`static ip_address=192.168.50.1/24`**  
    **`nohook wpa_supplicant`**

**`# Ethernet (eth0) for local LAN access, no default route`**  
**`interface eth0`**  
    **`metric 400`**  
    **`static ip_address=192.168.10.10/24`**  
    **`# No router or DNS — avoids overriding wlan0's internet route`**  
    **`nogateway`**

The first block of text determines settings for the wireless access point (ap0) used to broadcast the Wi-Fi network to other devices. Going through the following lines:

* **`interface ap0 -`** defines the AP interface used to broadcast the router’s Wi-Fi network.  
* **`metric 100 -`**  determines the preferred paths devices will take. Having a lower metric makes devices more likely to connect via that path.  
* **`static ip_address=192.168.10.10/24 -`** gives the path a static address that devices will connect to on the network. Make sure to select an address that is not currently on the network  
* **`nohook wpa_supplicant -`** tells the dhcp daemon to skip the wpa\_supplicant file. This is necessary because this interface gets its configuration from **hostapd** and not **wpa\_supplicant**

The second block of text follows a similar structure to the first with an interface and configurations below the interface. This interface is via ethernet cable and is used when the Raspberry PI is connected by an ethernet cable. This is useful for troubleshooting purposes if the Raspberry PI has issues regarding its wireless access point. Looking through the interfaces configurations:

* **`metric 400 -`** the metric set to 400 which is much higher than the wireless access point’s path, making this route much less preferred.  
* **`static ip_address=192.168.10.10/24 -`** Gives the Raspberry PI a fixed address on wired LAN.  
* **`nogateway -`** prevents the wired LAN from overriding the internet uplink or ap0

## **WLAN Configuration**

WLAN or wireless local area network is a type of network that uses Wi-Fi to connect devices to a network in a small area. WLAN is used for more flexibility compared to LAN because LAN requires a physical connection, such as an ethernet cable, to transfer data.

**`wpa_supplicant`** is responsible for handling the connection between my router and the primary home network. The **`wpa_supplicant`** can scan for networks, handle security, and keep the connection alive or reconnect the connection if the connection is severed. There are no direct changes required for **`wpa_supplicant`** if the connection is through a physical connection, such as an ethernet cable, or a higher-level network manager is used.

Here is how my wpa\_supplicant is organized:  
**`ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev`**  
**`update_config=1`**  
**`country=US`**

**`network={`**  
    **`ssid=[Primary Home Network’s Name]`**  
    **`psk=[Primary Home Network’s Password]`**  
    **`scan_ssid=1`**  
**`}`**

By looking at the interface line-by-line:

* **`ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev`**  
  * Creates a control socket so tools like **`wpa_cli/wpa_gui`** can talk to wpa\_supplicant.  
  * **`GROUP=netdev`** lets users in the **`netdev`** group run **`wpa_cli`** without root.  
* **`update_config=1`**  
  * Allows wpa\_supplicant (via wpa\_cli or GUI tools) to modify and save this file (add networks, change PSKs) when you run wpa\_cli save\_config.  
* **`country=US`**  
  * Sets the regulatory domain (legal channels/power for the U.S.). Keep this consistent with hostapd’s country\_code=US.  
* **`network={`**  
     **`ssid=[Primary Home Network Name]`**  
      **`psk=[Primary Home Network Password]`**  
      **`scan_ssid=1`**  
  **`}`**  
  * This block defines one Wi-Fi you want wlan0 to join.  
  * **`ssid=[Primary Home Network Name]`**   
    * the name of the network the router will connect with.  
    * Use quotes in real files, e.g. ssid="My-Network" (especially if it has spaces/special chars).  
  * **`psk=[Primary Home Network Password]`**   
    * The password of the network  
    * This must also be inside quotation marks  
  * **`scan_ssid=1`**   
    * tells **`wpa_supplicant`** to actively probe for this SSID (needed if the network hides its SSID).  
    * If the AP isn’t hidden, you can omit this; it won’t hurt if left on.

After editing the **`wpa_supplicant`** file, we need to make sure that the system kernel is able to utilize that file in our **`wlan0`** interface. The next set of commands enables the **`wpa_supplicant`**, makes sure it runs on boot, and also adjusts the network route, so that our router will connect with the upstream network.

* **`sudo ln -s /etc/wpa_supplicant/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant-wlan0.conf`**  
  * Creates a **symlink** so the per-interface service **`wpa_supplicant@wlan0.service`** can find its configuration file.  
  * On Raspberry Pi OS/Debian, that service looks for: **`/etc/wpa_supplicant/wpa_supplicant-<interface>.conf`**  
    * The link just points that expected file to your main configuration file, so you don’t have to maintain two copies.  
* **`sudo systemctl enable wpa_supplicant@wlan0.service`**  
  * **Enable at boot**.   
    * This tells **systemd**: “start the **`wpa_supplicant`** instance for **`wlan0`** automatically on every boot.”  
      * (Enable \= make it persistent. It doesn’t necessarily start right *now*.)  
* **`sudo systemctl restart wpa_supplicant@wlan0.service`**  
  * **Apply your changes now** by stopping and starting the **`wlan0`** instance.  
    * This makes it re-read the config and reconnect to the Wi-Fi.  
* **`sudo ip route replace default via 192.168.12.1 dev wlan0`**  
  * Sets (or replaces) the **default route** so all internet-bound traffic goes out **via `wlan0`** to the **gateway 192.168.12.1** (your upstream router).  
  * Use this when DHCP didn’t install the right default route or another interface (like **`eth0`**) stole it.  
    * NOTE: This is **temporary** (lasts until reboot or until DHCP changes routes). To make it stick, prefer letting DHCP set the route, or use **`dhcpcd.conf`** (e.g., give **`eth0` `nogateway`** and/or set **metrics** so **`wlan0`** is preferred).  
  * Make sure the gateway **(`192.168.12.1`**) is actually in the same subnet as **`wlan0`**’s IP.

## **Restart Services**

Restart services to apply the changes made to the configuration file:

**`sudo systemctl restart hostapd`**  
**`sudo systemctl restart dnsmasq`**  
**`sudo systemctl restart dhcpcd`**

# **Enable Routing and NAT**

In order to get our Raspberry PI to act as a router, we will need to employ the usage of the **`iptables`** command-line tool which will let us configure how packets of data will be broadcasted throughout the router. The rules that will be created and utilized are shown below:

**`sudo iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE`**

Turn on Network Address Translation **(NAT)** for traffic leaving via `wlan0`. This rule allows packets sent from the upstream network through the proper channels on my router.

* **`-t nat`**  
  * Lets us operate on the NAT table; The filter table will be used instead if no option is selected  
* **`-A POSTROUTING`**  
  * The \-A option is used to append a rule and POSTROUTING refers to the chain, a control at a certain point of a packet’s travel, specifically for packets that are about to go out. Therefore, we are appending a rule for packets that are getting output by our router.  
* **`-o wlan0`**  
  * This determines where the outbound packets are being sent. In this case, we are dealing with outgoing packets through wlan0 or the connection between our router and the upstream network/router  
* **`-j masquerade`**  
  * perform “masquerade” SNAT. It rewrites each packet’s **source IP** to the current address on **`wlan0`** (perfect when that IP comes from DHCP and may change). Masquerade is the dynamic form of SNAT and is used in **`nat/POSTROUTING`**.

**`sudo iptables -A FORWARD -i ap0 -o wlan0 -j ACCEPT`**

Allow forwarding of packets going from the wireless access point or LAN **(ap0)** to the internet or upstream network **(wlan0)**. Without this, forwarded packets would be dropped. This is performed in the default filter table’s `FORWARD` chain.

* **`-A FORWARD`**  
  * Append to the FORWARD chain. The FORWARD chain are rules for packets being routed through the Raspberry PI.  
* **`-i ap0`**  
  * match packets **coming in** via the AP interface (ap0).  
* **`-o wlan0`**   
  * Same as the previous command: Matches packets that are going out through wlan0 or the connection to the upstream network  
* **`-j ACCEPT`**  
  * Allow the packets to be forwarded

**`sudo iptables -A FORWARD -i wlan0 -o ap0 -m state --state RELATED,ESTABLISHED -j ACCEPT`**

Allow replies back in for connections the LAN started. The “state/conntrack” matcher recognizes **ESTABLISHED** traffic (part of an existing flow) and **RELATED** helper traffic (like FTP data channels), so only legitimate return packets are accepted. You’ll also see the newer syntax **`-m conntrack --ctstate ...`**; **conntrack** is a superset of the older **state** match. This is a simple firewall filter which blocks unsolicited inbound connections, but allows replies to flow back.

* **`-A FORWARD`**  
  * Traffic going through the router  
* **`-i wlan0 -o ap0`**  
  * If you look at the previous command, the \-i and \-o options are swapped. This is because, in this case, we are looking at the packets coming from the upstream network and going out to the devices connected to the wireless access point.  
* **`-m state`**  
  * load the **state** match module (a subset of **conntrack**, Linux’s connection-tracking subsystem).  
* **`--state RELATED,ESTABLISHED`**   
  * match packets that are part of an **existing** connection (ESTABLISHED) or closely **RELATED** helper traffic (e.g., some protocols open secondary flows). In short: “let replies and related packets back in.”  
* **`-j ACCEPT`**  
  * allow those reply packets to pass.

**`sudo netfilter-persistent save`**

Save your current **`iptables`** rules so they survive reboots.

On Debian/Ubuntu this writes to **`/etc/iptables/rules.v4`/`.v6`** after installing **`iptables-persistent`**.

# **Startup on Boot**

Until now, all of the configurations and services we have employed only lasted until the Raspberry PI shutdowns or reboots. To keep our changes on reboot, we must utilize scripts that run on boot which will reconfigure our changes. Scripts will be located in the **`/bin/`** directory. The “bin” keyword refers to “binary”, in which scripts are converted to: binary machine code. We will create a new file called **`setup-router.sh`** inside the **`/bin/`** directory:

**`sudo nano /usr/local/bin/setup-router.sh`**

This will be the script that sets up our router on boot:

**`#!/bin/bash`**

**`LOG_FILE="/var/log/setup-router.log"`**  
**`exec > >(tee -a "$LOG_FILE") 2>&1`**  
**`echo "==== Starting router setup: $(date) ===="`**

**`# Wait for wlan0 to have IP and default route`**  
**`echo "[*] Waiting for wlan0 to be connected and routed..."`**  
**`for i in {1..20}; do`**  
    **`if ip route | grep -q "default via 192.168.12.1 dev wlan0"; then`**  
        **`echo "[+] wlan0 is up with default route"`**  
        **`break`**  
    **`fi`**  
    **`sleep 1`**  
**`done`**

**`# Remove eth0 default route if it appeared (e.g., from SSH handshake)`**  
**`if ip route | grep -q "default via 192.168.10.100 dev eth0"; then`**  
    **`echo "[*] Removing unwanted default route from eth0..."`**  
    **`ip route del default via 192.168.10.100 dev eth0`**  
**`fi`**

**`# Stop any existing AP services`**  
**`systemctl stop hostapd`**  
**`systemctl stop dnsmasq`**

**`# Recreate ap0 interface in AP mode`**  
**`ip link set ap0 down 2>/dev/null`**  
**`iw dev ap0 del 2>/dev/null`**  
**`iw dev wlan0 interface add ap0 type __ap`**  
**`ip link set ap0 up`**  
**`ip addr flush dev ap0`**  
**`ip addr add 192.168.50.1/24 dev ap0`**

**`# Start access point services`**  
**`systemctl start hostapd`**  
**`systemctl restart dnsmasq`**

**`# Enable IP forwarding`**  
**`sysctl -w net.ipv4.ip_forward=1`**

**`# Flush and reapply NAT rules`**  
**`iptables -F`**  
**`iptables -t nat -F`**  
**`iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE`**  
**`iptables -A FORWARD -i ap0 -o wlan0 -j ACCEPT`**  
**`iptables -A FORWARD -i wlan0 -o ap0 -m state --state RELATED,ESTABLISHED -j ACCEPT`**

**`# Save rules for persistence`**  
**`netfilter-persistent save`**

**`# Final default route fix (just in case)`**  
**`echo "[*] Verifying default route..."`**  
**`ip route replace default via 192.168.12.1 dev wlan0`**

**`# Final routing table`**  
**`echo "[✓] Final routing table:"`**  
**`ip r`**

**`echo "==== Router setup complete ===="`**

**`/usr/local/bin/router-boot-timer.sh &`**

At the very top of this script, a block of code is set to log the outputs of this script to a log file.

* **`LOG_FILE="/var/log/setup-router.log"`**  
  * Sets a variable LOG\_FILE to the path to the file used for logging  
* **`exec > >(tee -a "$LOG_FILE") 2>&1`**  
  * Using the exec command and redirections to send all standard output and errors through the LOG\_FILE variable.  
  * **`2>&1`**   
    * sends both standard error (2) and stand output (1) to **`"/var/log/setup-router.log"`**  
    * Note: the order of stdout and stderr matters here

After establishing the logging feature, a for loop will run 20 times waiting to establish the default wlan0 route. Each iteration will take one second to run using the **`sleep`** command to avoid overloading.

**`if ip route | grep -q "default via 192.168.10.100 dev eth0"; then`**  
    **`echo "[*] Removing unwanted default route from eth0..."`**  
    **`ip route del default via 192.168.10.100 dev eth0`**  
**`fi`**

* Removes unwanted eth0 (ethernet cable) connection if it appears  
* This was a recurring issue I faced when attempting to establish a consistent connection to the network

**`# Final routing table`**  
**`echo "[✓] Final routing table:"`**  
**`ip r`**

* Outputs the final IP configurations to the log file

**`echo "==== Router setup complete ===="`**

* Finishes the router setup

This script’s purpose is to reapply configuration interfaces, IP table rules, and restart important system services such as **`hostapd`** and **`dnsmasq`**. After reapplying these changes, the script runs another script that logs network configurations and services statuses:

**`/usr/local/bin/router-boot-timer.sh &`**

After creating the shell script for the router setup, we must change the permissions to allow the file to be executed using the **`chmod`** command and the **`+x`** symbol referring to execution privileges for all groups and users.

**`sudo chmod +x /usr/local/bin/setup-router.sh`**

To actually run the script as a daemon (background service), a service unit file must be set up within the systemd directory. Systemd is a system and service manager for Linux operating systems and replaces the .init system. Create the service unit file as shown below:

**`sudo nano /etc/systemd/system/setup-router.service`**

This file will contain the information below:

**`[Unit]`**  
**`Description=Custom Router Setup Script`**  
**`After=network-online.target dhcpcd.service wpa_supplicant@wlan0.service`**  
**`Wants=network-online.target`**

**`[Service]`**  
**`Type=oneshot`**  
**`ExecStart=/usr/local/bin/setup-router.sh`**  
**`ExecStartPost=/usr/local/bin/wait-for-wlan0.sh`**  
**`RemainAfterExit=true`**

**`[Install]`**  
**`WantedBy=multi-user.target`**

This service file is broken into three distinct sections:

* **`[Unit]`**  
  * Used to describe the purpose of the service and also to add dependencies  
  * **`After=network-online.target dhcpcd.service wpa_supplicant@wlan0.service`**  
    * Sets the order of services that will start BEFORE this service unit  
  * **`Wants=network-online.target`**  
    * Weak dependency that asks systemd for the network-online.target, but will continue to run if that checkpoint is not available  
* **`[Service]`**  
  * Describes how the process should run  
  * **`Type=oneshot`**  
    * Runs commands in the script once (effective for router setup)  
  * **`ExecStart=/usr/local/bin/setup-router.sh`**  
    * Runs the setup-router bash script above  
  * **`ExecStartPost=/usr/local/bin/wait-for-wlan0.sh`**  
    * Runs another bash script after successfully running the main setup script (setup-router.sh)  
  * **`RemainAfterExit=true`**  
    * systemd will consider this service to be “active” or “running” after setup  
* **`[Install]`**  
  * Define installation-related settings  
  * **`WantedBy=multi-user.target`**  
    * When multi-user login has been booted, then this service unit will be included in that boot up process

After creating the service unit file and script, we will need to enable the service. This can be done with the following command:

**`sudo systemctl enable setup-router.service`**

# **Boot Timer Script**

Using the command:

**`/usr/local/bin/router-boot-timer.sh &`**

Create a boot timer script with the following:  
**`#!/bin/bash`**

**`LOG="/var/log/router-boot-timer.log"`**  
**`echo "==== Boot Timer: $(date) ====" >> $LOG`**

**`log_time() {`**  
    **`echo "[$(date +'%H:%M:%S')] $1" >> $LOG`**  
**`}`**

**`START=$(date +%s)`**

**`log_time "Script started"`**

**`# Wait for wlan0 to get an IP`**  
**`for i in {1..30}; do`**  
    **`if ip -4 addr show wlan0 | grep -q "inet "; then`**  
        **`log_time "wlan0 got IP: $(ip -4 addr show wlan0 | grep inet | awk '{print $2}')"`**  
        **`break`**  
    **`fi`**  
    **`sleep 1`**  
**`done`**

**`# Wait for wlan0 default route`**  
**`for i in {1..10}; do`**  
    **`if ip route | grep -q "default via 192.168.12.1 dev wlan0"; then`**  
        **`log_time "Default route via wlan0 ready"`**  
        **`break`**  
    **`fi`**  
    **`sleep 1`**  
**`done`**

**`# Wait for hostapd to start`**  
**`for i in {1..10}; do`**  
    **`if systemctl is-active --quiet hostapd; then`**  
        **`log_time "hostapd is active"`**  
        **`break`**  
    **`fi`**  
    **`sleep 1`**  
**`done`**

**`# Wait for dnsmasq to start`**  
**`for i in {1..10}; do`**  
    **`if systemctl is-active --quiet dnsmasq; then`**  
        **`log_time "dnsmasq is active"`**  
        **`break`**  
    **`fi`**  
    **`sleep 1`**  
**`done`**

**`END=$(date +%s)`**  
**`DURATION=$((END - START))`**  
**`log_time "Setup completed in $DURATION seconds"`**  
**`echo "====" >> $LOG`**

* The script creates a log header with date and then prints the status of **`wlan0`**, **`hostapd`**, and **`dnsmasq`** to the **`router-boot-timer.log`** file.

### **Wait For WLAN**

Another script is defined inside the setup-router.service file that runs after the main script:

**`/usr/local/bin/wait-for-wlan0.sh`**

The contents of this script are listed below”

**`#!/bin/bash`**

**`echo "[*] Waiting for wlan0 to have IP and route..."`**  
**`for i in {1..30}; do`**  
    **`if ip route | grep -q "default via 192.168.12.1 dev wlan0"; then`**  
        **`echo "[+] wlan0 default route is ready"`**  
        **`exit 0`**  
    **`fi`**  
    **`sleep 2`**  
**`done`**

**`echo "[!] wlan0 never came up — routing will fail"`**  
**`exit 1`**

* The purpose of this script is to loop every 2 seconds, 30 times for a total of a minute while checking to see if the wlan0 interface has the correct IP route; If the loop concludes without confirmation, an error message will be outputted  
* This is an additional reliability check to make sure **`wlan0`** is properly connected and configured correctly

# **Reliability Checks**

This project had lots of obstacles, mainly due to the wlan0 interface getting disconnected or overtaken by other interfaces such as eth0. To prevent **`wlan0`** from being disconnected or failing as easily, I disabled power-saving for the wlan0 interface and made sure the changes persist on reboots.

* **`sudo systemctl disable NetworkManager`**  
  * Disables **`NetworkManager`** daemon  
  * Aims to prevent conflicts between **NetworkManager** and other network services (**dhcpcd**, **wpa\_supplicant**, etc.)  
* **`iw wlan0 get power_save`**  
  * Displays the status of power-saving mode on the **`wlan0`** interface  
* **`sudo iw wlan0 set power_save off`**  
  * Turns off power-saving for the **`wlan0`** interface  
  * Done to increase latency or performance of **`wlan0`**  
* **`sudo nano /usr/local/bin/wlan0-nosleep.sh`**  
  * Create a new script that ensures wlan0 is not on power-saving mode:

    **`#!/bin/bash`**

    **`iw wlan0 set power_save off`**

* **`sudo nano /etc/systemd/system/wlan0-nosleep.service`**  
  * Creates a service unit that will run the above script on boot.  
  * Similarly to the router setup script, it will run once:

    **`[Unit]`**

    **`Description=Disable Wi-Fi power saving on wlan0`**

    **`After=multi-user.target network.target`**

    

    **`[Service]`**

    **`Type=oneshot`**

    **`ExecStart=/usr/local/bin/wlan0-nosleep.sh`**

    **`RemainAfterExit=true`**

    

    **`[Install]`**

    **`WantedBy=multi-user.target`**

# **Router Health Check**

To handle random disconnects or network interference, another script is used to restart the router setup. This script runs on set intervals and checks the health of the router. Inside the router-healthcheck.sh bash script:

**`#!/bin/bash`**

**`LOG="/var/log/router-health.log"`**

**`echo "[$(date)] Checking wlan0 route and link..." >> $LOG`**

**`# Is wlan0 up?`**  
**`if ! ip link show wlan0 | grep -q "state UP"; then`**  
    **`echo "[$(date)] wlan0 is down. Restarting setup..." >> $LOG`**  
    **`/usr/local/bin/setup-router.sh`**  
    **`exit`**  
**`fi`**

**`# Is default route via wlan0 missing?`**  
**`if ! ip route | grep -q "default via 192.168.12.1 dev wlan0"; then`**  
    **`echo "[$(date)] Default route missing or hijacked. Fixing..." >> $LOG`**  
    **`/usr/local/bin/setup-router.sh`**  
    **`exit`**  
**`fi`**

**`# All good`**  
**`echo "[$(date)] All OK." >> $LOG`**

* Firstly, all outputs of this file are recorded within the **`router-health.log`** file.  
* The first if-statement block checks if the **`wlan0`** interface is UP or active  
  * If it is not active, then the **`setup-router.sh`** bash script will be run.  
* The second if-statement block checks if the IP route of **`wlan0`** is missing.  
  * If the route is not present or **`wlan0`** is not the default path, then the **`setup-router.sh`** script will also be run  
* If neither condition is true, then the script will output a positive confirmation  
* **`grep`** is used to locate the matching text patterns from **`ip route`**, a command used to display the current network interfaces.

To run this script intermittently, a .timer unit within systemd will schedule a .service unit file to run the bash script on set intervals. The file, router-healthcheck.timer will contain this information:

**`[Unit]`**  
**`Description=Run router health check every 30s`**

**`[Timer]`**  
**`OnBootSec=1min`**  
**`OnUnitActiveSec=30s`**  
**`Unit=router-healthcheck.service`**

**`[Install]`**  
**`WantedBy=timers.target`**

* **`[Unit]`**  
  * Gives a simple description of the file  
* **`[Timer]`**  
  * Defines this as a timer unit, unlike service units  
  * **`OnBootSec=1min`**  
    * Will run 1 minute after boot  
  * **`OnUnitActiveSec=30s`**  
    * Runs this unit every 30 seconds after the first initial boot  
  * **`Unit=router-healthcheck.service`**  
    * The unit that will be triggered by this timer

This will also require another file, router-healthcheck.service, that actually runs the script:  
**`[Unit]`**  
**`Description=Router auto-recovery watchdog`**

**`[Service]`**  
**`ExecStart=/usr/local/bin/router-healthcheck.sh`**

* Executes the **`router-healthcheck.sh`** script on activation

To make sure the timer is up and running, use **`systemctl enable`** to run the **`router-healthcheck.timer`**. –now ensures the changes are made immediately. In addition, make sure that the script has execution privileges or it cannot be run.

**`sudo systemctl enable --now router-healthcheck.timer`**

# **Troubleshooting**

Throughout this project, I used various commands, to determine whether network paths were set up properly and the router is able to communicate with the internet. The most used commands are listed below:

* **`iwgetid`**  
  * Prints the Service Set Identifier (SSID) of the uplink network or the primary network that my router is routing.   
* **`iw dev ap0 info`**  
  * The iw command is used to display wireless devices and their configuration.   
  * In this case, the syntax of “dev ap0 info” is used to display information regarding the network interface, dev, of ap0.   
  * I use this command to determine if my access point is running properly.  
* **`ip -4 addr show ap0`**  
  * Lists the IPv4 addresses on the ap0 wireless interface.   
  * If the IP address is the same as the static address inside dhcpcd.conf and the message that says “state UP”, then things should be working correctly.  
* **`ip route`**  
  * Prints the IP routing table which displays how network packets are forwarded between different hosts and networks.  
* **`iptables -t nat -L -n`**  
  * This command will display the Network Address Translation (NAT) table for the Raspberry PI Router.   
  * Specifically, the “-t nat” option in conjunction with the iptables command will provide a table with rules for PREROUTING, OUTPUT, and POSTROUTING.  
* **`ping -c 3 8.8.8.8`**  
  * Using the ping command with the \-c option, meaning count, followed by an integer will send that many packets of data to the destination address.  
  * The 8.8.8.8 belongs to Google’s public DNS server and we are sending three packets to the address. I used this command many times to check the internet connectivity of the Raspberry PI router. 

# **Conclusion**

This documentation goes over the process of configuring a Raspberry PI into a functional router with a wireless access point. The steps first required installing the necessary network software that allowed the raspberry pi to run as a router and wireless access point. Later, I would need to configure multiple files which defined network interface configurations. After properly configuring and establishing the network path, I had to ensure that the router setup would persist on reboot. Therefore, bash scripts and systemd service files had to be created to ensure proper setup of the Raspberry PI router on boot and periodically. Throughout the process, I made several safeguards to protect the network connection from going down. In addition, I relied on a multitude of IP and network troubleshooting commands to help me pinpoint errors in configuration and within the bash scripts. This project taught me the importance of resilience and to not back down even when all options have been exhausted. The project also taught me important network fundamentals and core features of the Linux shell.