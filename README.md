# BustedV2
Monitor WiFi website traffic
-----------------------------
# BustedV2 Project Manual
# Busted Multi-Target ARP Spoofing & Traffic Capture

## Description

This script performs **multi-target ARP spoofing** and captures **DNS and TLS handshake traffic** on a local network. It is useful for **network security analysis, penetration testing, and monitoring encrypted traffic destinations** (e.g., websites visited by targets).

### Features

- **Auto-detects** network interface and router IP
- **Enables IP forwarding** and configures `iptables` for traffic forwarding
- **Spoofs multiple targets simultaneously** using `arpspoof`
- **Captures DNS queries and TLS handshake SNI data** using `tshark`
- **Logs captured traffic** to a file

## Requirements

Ensure the following dependencies are installed before running the script:

- `ip`
- `tshark`
- `arpspoof` (from the `dsniff` package)
- `awk`
- `sudo`

### Installation (Debian-based Systems)

```bash
sudo apt update && sudo apt install dsniff tshark net-tools -y
```

## Usage

### 1️. Run the Script

```bash
sudo ./busted_multi_target.sh
```

**This script must be run as root** (or using `sudo`).

### 2️. Provide Target IPs

When prompted, enter one or more **target IP addresses** (separated by spaces), for example:

```
[*] Enter target IPs separated by spaces (e.g., 192.168.0.6 192.168.0.10):
```

After entering the IPs, the script will:\
  Enable **packet forwarding**\
  Start **ARP spoofing**\
  Begin **capturing network traffic**

### 3️. Stop the Script

Press `CTRL + C` to stop the script and restore network settings. The cleanup function will:

- **Kill ARP spoofing processes**
- **Flush iptables rules**
- **Disable IP forwarding**

## Output

Captured traffic is logged to:

- busted_multi_target_advanced.log

Each entry includes a timestamp, target IP, and domain name from **TLS handshakes** or **DNS queries**.

## ⚠️ Legal Disclaimer

This script is intended for **educational and authorized penetration testing** purposes **only**.\
  **Unauthorized use on networks without explicit permission is illegal** and may result in legal consequences.\
  Always obtain proper authorization before using this tool.

---

### Future Improvements

  Add automatic detection of all devices on the network\
  Implement support for **MitM proxying**\
  Improve output formatting

Contributions and suggestions are welcome!

