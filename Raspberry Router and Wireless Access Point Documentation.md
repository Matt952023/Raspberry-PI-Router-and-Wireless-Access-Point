Matthew Zhang

# **Abstract**

In this demonstration, I will convert a Raspberry PI 4 Model B into a functional NAT router with a wireless access point for devices to connect.

# **Introduction**

A number of Linux commands were used to set up and troubleshoot the raspberry pi.

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
ctrl\_interface=DIR=/var/run/wpa\_supplicant GROUP=netdev  
update\_config=1  
country=US

network={  
    ssid=\[Primary Home Network’s Name\]  
    psk=\[Primary Home Network’s Password\]  
    scan\_ssid=1  
}

By looking at the interface line-by-line:

* ctrl\_interface=DIR=/var/run/wpa\_supplicant GROUP=netdev  
  * Creates a control socket so tools like wpa\_cli/wpa\_gui can talk to wpa\_supplicant.  
  * GROUP=netdev lets users in the netdev group run wpa\_cli without root.  
* update\_config=1  
  * Allows wpa\_supplicant (via wpa\_cli or GUI tools) to modify and save this file (add networks, change PSKs) when you run wpa\_cli save\_config.  
* country=US  
  * Sets the regulatory domain (legal channels/power for the U.S.). Keep this consistent with hostapd’s country\_code=US.  
* network={  
     ssid=\[Primary Home Network Name\]  
      psk=\[Primary Home Network Password\]  
      scan\_ssid=1  
  }  
  * This block defines one Wi-Fi you want wlan0 to join.  
  * ssid=\[Primary Home Network Name\]   
    * the name of the network the router will connect with.  
    * Use quotes in real files, e.g. ssid="My-Network" (especially if it has spaces/special chars).  
  * psk=\[Primary Home Network Password\]   
    * The password of the network  
    * This must also be inside quotation marks  
  * scan\_ssid=1 – tells wpa\_supplicant to actively probe for this SSID (needed if the network hides its SSID).  
    * If the AP isn’t hidden, you can omit this; it won’t hurt if left on.

# **Automatic Startup on Boot**

# **Reliability Checks**

# **Troubleshooting**

# **Conclusion**