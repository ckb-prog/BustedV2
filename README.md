# BustedV2
Monitor WiFi website traffic
--------------------------------------------------
Busted Multi-Target ARP Spoofing & Traffic Capture
Description
This script performs multi-target ARP spoofing and captures DNS and TLS handshake traffic on a local network. It is useful for network security analysis, penetration testing, and monitoring encrypted traffic destinations (e.g., websites visited by targets).

Features:

Detects the primary network interface and router IP automatically
Enables IP forwarding and sets up iptables rules for packet forwarding
Spoofs multiple targets simultaneously using arpspoof
Captures TLS handshake and DNS queries with tshark
Logs captured data to a file
Requirements
Ensure the following tools are installed before running the script:

ip
tshark
arpspoof (from dsniff package)
awk
sudo
Usage
1. Install Dependencies
On Debian-based systems (like Ubuntu, Kali, ParrotOS, Trisquel), run:

bash
Copy
Edit
sudo apt update && sudo apt install dsniff tshark net-tools -y
2. Run the Script
bash
Copy
Edit
sudo ./busted_multi_target.sh
⚠️ This script must be run as root (or using sudo).

3. Provide Target IPs
When prompted, enter one or more target IP addresses (separated by spaces), for example:

scss
Copy
Edit
[*] Enter target IPs separated by spaces (e.g., 192.168.0.6 192.168.0.10):
After entering the IPs, the script will:

Enable packet forwarding
Start ARP spoofing
Begin capturing network traffic
4. Stop the Script
Press CTRL + C to stop and restore network settings. The cleanup function will:

Kill ARP spoofing processes
Flush iptables rules
Disable IP forwarding
Output
Captured traffic is logged to:

lua
Copy
Edit
busted_multi_target_advanced.log
Each line includes a timestamp, target IP, and domain name from TLS handshakes or DNS queries.

Legal Disclaimer
This script is for educational and authorized penetration testing purposes only. Unauthorized use on networks without explicit permission is illegal and may result in severe consequences. Use responsibly.

