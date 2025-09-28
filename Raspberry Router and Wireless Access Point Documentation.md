Matthew Zhang

# **Abstract**

# **Introduction**

In this demonstration, I will convert a Raspberry PI 4 Model B into a functional NAT router with a wireless access point for devices to connect. The main goal of this project is to take my primary home network and pass it through my Raspberry PI router and allow other devices to connect to the Raspberry PI through the access point gateway. The following sections will go through the process of converting a Raspberry PI into a router and giving some background information regarding network configuration.

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

The package, iptables, requires additional options tailored to our interests:

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

The systemctl command is a useful tool for managing services or programs inside Linux. The systemctl command communicates with **systemd**, software that manages different parts of the Linux operating system, and can start or stop services.

The “--now” option means that systemctl will start the **dhcpcd** service on reboot immediately.

# **Configuration Files**

A number of various configuration files for the services we have installed requires some changes. Many of these files will be found in the /etc/ directory because that is where configuration files are stored on the Linux file system.

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

* `sudo iw dev wlan0 interface add ap0 type __ap`  
   Makes a **virtual wireless interface** called **ap0** on the same physical radio as `wlan0`, with the **AP (access-point) mode**. This is what lets one Wi-Fi chip do two jobs at once: `wlan0` stays a client (uplink) while **ap0** is the AP (downlink). Your adapter/driver must support **AP mode** and, if you want AP+client simultaneously, the right **interface combinations** (check with `iw list`). ([ArchWiki](https://wiki.archlinux.org/title/Software_access_point))

* `sudo ip link set ap0 up`  
   **Brings the interface up** (activates it). Until an interface is “up,” the kernel won’t pass frames through it. This is the standard `iproute2` way to enable a network device. ([man7.org](https://www.man7.org/linux/man-pages/man8/ip-link.8.html?utm_source=chatgpt.com))

* `sudo ip addr add 192.168.50.1/24 dev ap0`  
   **Assigns an IPv4 address** (the Pi’s gateway IP) to **ap0** with a **/24** prefix (255.255.255.0). Clients on your AP will live in the same subnet (e.g., 192.168.50.10–100 from dnsmasq) and use **192.168.50.1** as their default gateway. ([man7.org](https://www.man7.org/linux/man-pages/man8/ip-address.8.html?utm_source=chatgpt.com))

## **DNSMASQ Configuration**

Edit the dnsmasq.conf file with the command:

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

The hostapd configuration file is used to set up the network settings for our wireless access point. To access the file, use this command:

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
  * Advertise the **country/regulatory info** to clients (pairs with `country_code`; helps clients behave legally).  
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
  * Keep file permissions tight: `sudo chmod 600 /etc/hostapd/hostapd.conf`.  
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

wpa\_supplicant is responsible for handling the connection between my router and the primary home network. The wpa\_supplicant can scan for networks, handle security, and keep the connection alive or reconnect the connection if the connection is severed. There are no direct changes required for wpa\_supplicant if the connection is through a physical connection, such as an ethernet cable, or a higher-level network manager is used.

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
    * tells wpa\_supplicant to actively probe for this SSID (needed if the network hides its SSID).  
    * If the AP isn’t hidden, you can omit this; it won’t hurt if left on.

### **Additional Uplink Configurations**

* `sudo ln -s /etc/wpa_supplicant/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant-wlan0.conf`  
   Creates a **symlink** so the per-interface service `wpa_supplicant@wlan0.service` can find its config.  
   On Raspberry Pi OS/Debian, that service looks for `/etc/wpa_supplicant/wpa_supplicant-<interface>.conf`.  
   The link just points that expected file to your main config, so you don’t have to maintain two copies.

* `sudo systemctl enable wpa_supplicant@wlan0.service`  
   **Enable at boot**. This tells systemd: “start the wpa\_supplicant instance for `wlan0` automatically on every boot.”  
   (Enable \= make it persistent. It doesn’t necessarily start it *right now*.)

* `sudo systemctl restart wpa_supplicant@wlan0.service`  
   **Apply your changes now** by stopping and starting the `wlan0` instance. This makes it re-read the config and reconnect to the Wi-Fi.

* `sudo ip route replace default via 192.168.12.1 dev wlan0`  
   Sets (or replaces) the **default route** so all internet-bound traffic goes out **via `wlan0`** to the **gateway 192.168.12.1** (your upstream router).  
   Use this when DHCP didn’t install the right default route or another interface (like `eth0`) stole it.  
   Notes:

  * This is **temporary** (lasts until reboot or until DHCP changes routes). To make it stick, prefer letting DHCP set the route, or use `dhcpcd.conf` (e.g., give `eth0` `nogateway` and/or set **metrics** so `wlan0` is preferred).

  * Make sure the gateway (`192.168.12.1`) is actually in the same subnet as `wlan0`’s IP.

## **Restart Services**

Restart services to apply the changes made to the configuration file:

**`sudo systemctl restart hostapd`**  
**`sudo systemctl restart dnsmasq`**  
**`sudo systemctl restart dhcpcd`**

# **Enable Routing and NAT**

* `sudo nano /etc/sysctl.conf`  
   You open the kernel-settings file to add:  
   `net.ipv4.ip_forward=1` → **allow the kernel to forward IPv4 packets between interfaces** (required for routing). The kernel knob is `ip_forward` (0=off, 1=on). ([Kernel.org](https://www.kernel.org/doc/html/latest/networking/ip-sysctl.html?utm_source=chatgpt.com))

* `sudo sysctl -p`  
   **Apply the changes right now** by (re)loading `/etc/sysctl.conf`. With `-p`, sysctl reads that file by default and sets the listed parameters. ([Arch Manual Pages](https://man.archlinux.org/man/sysctl.8.en?utm_source=chatgpt.com))

* `sudo iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE`  
   Turn on **NAT** for traffic leaving via `wlan0`.  
   **MASQUERADE** \= a form of **SNAT** that automatically rewrites each packet’s **source IP** to the **current address of `wlan0`** (great when the uplink IP is assigned by DHCP and can change). It only works in the **`nat` table’s `POSTROUTING` chain**. If you had a fixed public IP, you’d typically use `SNAT` instead. ([ipset.netfilter.org](https://ipset.netfilter.org/iptables-extensions.man.html?utm_source=chatgpt.com))

* `sudo iptables -A FORWARD -i ap0 -o wlan0 -j ACCEPT`  
   **Allow forwarding** of packets going **from your LAN (ap0) to the internet (wlan0)**. Without this, forwarded packets would be dropped. (This is in the default **filter** table’s `FORWARD` chain.) ([ArchWiki](https://wiki.archlinux.org/title/Iptables?utm_source=chatgpt.com))

* `sudo iptables -A FORWARD -i wlan0 -o ap0 -m state --state RELATED,ESTABLISHED -j ACCEPT`  
   **Allow replies back in** for connections that were started by your LAN. The `state`/`conntrack` matcher recognizes flows already in progress (`ESTABLISHED`) and helper traffic (`RELATED`), so only legit return traffic is accepted. (Modern docs often show `-m conntrack --ctstate`, which is the newer equivalent.) ([man7.org](https://www.man7.org/linux/man-pages/man8/iptables-extensions.8.html))

* `sudo netfilter-persistent save`  
   **Save your current iptables rules so they survive reboots** (on Debian/Ubuntu this writes to `/etc/iptables/rules.v4`/`.v6` after installing `iptables-persistent`). ([Debian Manpages](https://manpages.debian.org/buster/netfilter-persistent/netfilter-persistent.8.en.html?utm_source=chatgpt.com))

# **Automatic Startup on Boot**

Until now, all of the configurations and services we have employed only lasted until the Raspberry PI shutdowns or reboots. To keep our changes on reboot, we must utilize scripts that run on boot which will reconfigure our changes. Scripts will be located in the /bin/ directory. The “bin” keyword refers to “binary”, in which scripts are converted to: binary machine code. We will create a new file called “setup-router.sh” inside the /bin/ directory. This will be the script that sets up our router on boot:

**`sudo nano /usr/local/bin/setup-router.sh`**

**`sudo chmod +x /usr/local/bin/setup-router.sh`**

To actually run the script, a service must be set up within the systemd directory. Systemd is a system and service manager for Linux operating systems and replaces the .init system.

**`sudo nano /etc/systemd/system/setup-router.service`**  
**`sudo systemctl enable setup-router.service`**

# **Reliability Checks**

**`sudo systemctl disable NetworkManager`**  
**`iw wlan0 get power_save`**  
**`sudo iw wlan0 set power_save off`**  
**`sudo nano /usr/local/bin/wlan0-nosleep.sh`**  
**`sudo nano /etc/systemd/system/wlan0-nosleep.service`**  
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

This documentation goes over the process of configuring a Raspberry PI into a functional router with a wireless access point.