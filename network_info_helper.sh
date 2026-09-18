#!/bin/bash

# =================================================================
# Network Info Helper - For Terminal Output
# =================================================================

# Get the active network interface dynamically
get_active_interface() {
    route get default | grep interface | awk '{print $2}' 2>/dev/null
}

get_active_ethernet() {
    ifconfig | grep -E "^en[0-9]+.*flags.*RUNNING" | grep -v "PROMISC" | head -1 | cut -d: -f1
}

get_wifi_interface() {
    ifconfig | grep -E "^en[0-9]+.*PROMISC" | head -1 | cut -d: -f1 || echo "en1"
}

ACTIVE_IF=$(get_active_interface)
ETHERNET_IF=$(get_active_ethernet) 
WIFI_IF=$(get_wifi_interface)

menu_choice="$1"

case "$menu_choice" in
    "Show Network Info")
        echo "Hostname: $(hostname)"
        echo "Active Interface: $ACTIVE_IF"
        echo "Ethernet Interface: $ETHERNET_IF"
        echo "WiFi Interface: $WIFI_IF"
        echo ""
        
        # Show IP Address
        echo "IP Address:"
        if [ -n "$ACTIVE_IF" ]; then
            IP=$(ipconfig getifaddr "$ACTIVE_IF" 2>/dev/null)
            if [ -n "$IP" ]; then
                echo "  $ACTIVE_IF: $IP"
            else
                echo "  No IP found for $ACTIVE_IF"
            fi
        else
            echo "  No active interface found"
        fi
        echo ""
        
        # Show Gateway
        echo "Gateway:"
        route -n get default | grep gateway | awk '{print "  " $2}'
        echo ""
        
        # Show DNS
        echo "DNS Servers:"
        scutil --dns | grep "nameserver\[" | awk '{print "  " $3}' | sort -u
        ;;
        
    "Show IP Address")
        echo "IP Address Information:"
        if [ -n "$ACTIVE_IF" ]; then
            IP=$(ipconfig getifaddr "$ACTIVE_IF" 2>/dev/null)
            if [ -n "$IP" ]; then
                echo "Active Interface ($ACTIVE_IF): $IP"
            else
                echo "No IP found for $ACTIVE_IF"
            fi
        else
            echo "No active interface found"
        fi
        
        echo ""
        echo "All Active Interface IPs:"
        ifconfig | grep -A1 "status: active" | grep "inet " | grep -v 127.0.0.1 | awk '{print "  " $2}'
        ;;
        
    "Show DNS Servers")
        echo "DNS Servers:"
        scutil --dns | grep "nameserver\[" | awk '{print "  " $3}' | sort -u
        ;;
        
    "Show Gateway")
        echo "Gateway Information:"
        route -n get default | grep gateway | awk '{print "Gateway: " $2}'
        echo ""
        echo "Primary IPv4 Gateway:"
        netstat -rn | awk '/^default/ && !/utun/ && !/fe80/ {print "  " $2 " via " $6}'
        ;;
        
    "Show Active Interface")
        echo "Active Network Interfaces:"
        ifconfig | awk '
        /^[a-z]/ { 
            iface = $1; gsub(/:/, "", iface)
        }
        /status: active/ { 
            print "Interface: " iface " (active)"
        }
        /inet [0-9]/ && !/127\.0\.0\.1/ { 
            if (iface != "") print "  IP: " $2
        }'
        ;;
        
    "Show MAC Address")
        echo "MAC Address Information:"
        if [ -n "$ACTIVE_IF" ]; then
            echo "Active Interface ($ACTIVE_IF):"
            ifconfig "$ACTIVE_IF" | grep ether | awk '{print "  " $2}'
        else
            echo "No active interface found"
        fi
        
        if [ -n "$WIFI_IF" ] && [ "$WIFI_IF" != "$ACTIVE_IF" ]; then
            echo ""
            echo "WiFi Interface ($WIFI_IF):"
            ifconfig "$WIFI_IF" | grep ether | awk '{print "  " $2}'
        fi
        ;;
        
    "Check 802.1X Status")
        echo "802.1X (Dot1X) Status:"
        
        # Check for 802.1X processes
        echo ""
        echo "802.1X Processes:"
        PROCESSES=$(ps aux | grep -i "eapol\|dot1x\|8021x" | grep -v grep)
        if [ -n "$PROCESSES" ]; then
            echo "$PROCESSES"
        else
            echo "  No 802.1X processes found"
        fi
        
        echo ""
        echo "802.1X Certificates:"
        hostname=$(hostname)
        echo "Looking for certificates matching hostname: $hostname"
        
        # Look for certificates matching hostname
        CERT_CHECK=$(security find-certificate -a -c "$hostname" /Library/Keychains/System.keychain 2>/dev/null | grep "labl")
        if [ -n "$CERT_CHECK" ]; then
            echo "Found certificates for $hostname:"
            echo "$CERT_CHECK"
        else
            echo "  No certificates found for $hostname"
        fi
        ;;
esac