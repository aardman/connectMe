#!/bin/bash

# =================================================================
# Network Commands - Streamlined Alert Version
# =================================================================

# If no arguments, show the menu
if [ $# -eq 0 ]; then
    echo "Show Network Info"
    echo "Show Dot1X Status"
    echo "----"
    echo "Reset DNS Cache"
    echo "Renew Ethernet IP"
    echo "Reset Ethernet"
    echo "Renew Wireless IP"
    echo "Reset WiFi"
    echo "Disable IP Tracking"
    echo "----"
    echo "Open Network Prefs"
    echo "Open Keychain"
    echo "Open Directory Utility"
else
    # Handle menu selection
    menu_choice="$1"
    
    # Get common network info
    get_active_interface() {
        route get default | grep interface | awk '{print $2}' 2>/dev/null
    }
    
    get_ethernet_interface() {
        ifconfig | grep -E "^en[0-9]+.*flags.*RUNNING" | grep -v "PROMISC" | head -1 | cut -d: -f1
    }
    
    get_wifi_interface() {
        ifconfig | grep -E "^en[0-9]+.*PROMISC" | head -1 | cut -d: -f1 || echo "en1"
    }
    
    ACTIVE_IF=$(get_active_interface)
    ETHERNET_IF=$(get_ethernet_interface)
    WIFI_IF=$(get_wifi_interface)
    
    case "$menu_choice" in
        "Show Network Info")
            # Get comprehensive network info
            HOSTNAME=$(hostname)
            COMPUTER_NAME=$(scutil --get ComputerName 2>/dev/null)
            
            if [ -n "$ACTIVE_IF" ]; then
                IP=$(ipconfig getifaddr "$ACTIVE_IF" 2>/dev/null)
                IP_TEXT="${IP:-Not found}"
                MAC=$(ifconfig "$ACTIVE_IF" | grep ether | awk '{print $2}')
                MAC_TEXT="${MAC:-Not found}"
            else
                IP_TEXT="No active interface"
                MAC_TEXT="No active interface"
                ACTIVE_IF="None"
            fi
            
            GATEWAY=$(route -n get default | grep gateway | awk '{print $2}' 2>/dev/null)
            GATEWAY_TEXT="${GATEWAY:-Not found}"
            
            DNS=$(scutil --dns | grep "nameserver\[" | awk '{print $3}' | head -2 | tr '\n' ', ' | sed 's/,$//')
            DNS_TEXT="${DNS:-None found}"
            
            # Get AD domain
            AD_DOMAIN=$(dsconfigad -show | grep "Active Directory Domain" | awk -F= '{print $2}' | xargs 2>/dev/null)
            AD_TEXT="${AD_DOMAIN:-Not joined to domain}"
            
            osascript -e "display dialog \"Hostname: $HOSTNAME
AD Domain: $AD_TEXT

Interface: $ACTIVE_IF
IP Address: $IP_TEXT
MAC Address: $MAC_TEXT
Gateway: $GATEWAY_TEXT
DNS: $DNS_TEXT\" with title \"Network Info\" buttons {\"OK\"} default button \"OK\"" 2>/dev/null
            ;;
            
        "Show Dot1X Status")
            # Check for 802.1X processes
            PROCESSES=$(ps aux | grep -i "eapol\|dot1x\|8021x" | grep -v grep)
            if [ -n "$PROCESSES" ]; then
                PROCESS_STATUS="802.1X processes running"
            else
                PROCESS_STATUS="No 802.1X processes found"
            fi
            
            # Check for 802.1X certificates
            hostname=$(hostname)
            CERT_CHECK=$(security find-certificate -a -c "$hostname" /Library/Keychains/System.keychain 2>/dev/null | grep "labl")
            if [ -n "$CERT_CHECK" ]; then
                CERT_STATUS="Found certificates for $hostname"
            else
                CERT_STATUS="No certificates found for $hostname"
            fi
            
            # Check for 802.1X configuration
            CONFIG_INFO="802.1X is configured in:
• System Preferences > Network > Ethernet/WiFi > Advanced > 802.1X
• Profile Manager configurations
• Directory Utility for system-wide settings"
            
            osascript -e "display dialog \"802.1X Status:
$PROCESS_STATUS
$CERT_STATUS

Configuration Locations:
$CONFIG_INFO\" with title \"802.1X Status\" buttons {\"OK\"} default button \"OK\"" 2>/dev/null
            ;;
            
        "Reset DNS Cache")
            RESULT=$(osascript -e 'display dialog "Reset DNS Cache?

This will flush the DNS cache and restart mDNSResponder." buttons {"Cancel", "Reset"} default button "Reset" with icon caution' 2>/dev/null)

            if [[ "$RESULT" == *"Reset"* ]]; then
                if sudo -n /usr/bin/dscacheutil -flushcache 2>/dev/null && sudo -n /usr/bin/killall -HUP mDNSResponder 2>/dev/null; then
                    osascript -e 'display dialog "DNS cache has been reset." with title "DNS Cache Reset" buttons {"OK"} default button "OK"' 2>/dev/null
                else
                    osascript -e 'display dialog "Could not reset the DNS cache automatically.

Run in Terminal:
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder" with title "DNS Cache Reset" buttons {"OK"} default button "OK" with icon caution' 2>/dev/null
                fi
            fi
            ;;
            
        "Renew Ethernet")
            if [ -n "$ETHERNET_IF" ]; then
                RESULT=$(osascript -e "display dialog \"Renew DHCP lease for Ethernet ($ETHERNET_IF)?\" buttons {\"Cancel\", \"Renew\"} default button \"Renew\" with icon caution" 2>/dev/null)
                
                if [[ "$RESULT" == *"Renew"* ]]; then
                    if sudo -n /usr/sbin/ipconfig set "$ETHERNET_IF" DHCP 2>/dev/null; then
                        osascript -e "display dialog \"Renewed the DHCP lease for Ethernet ($ETHERNET_IF).\" with title \"Ethernet DHCP\" buttons {\"OK\"} default button \"OK\"" 2>/dev/null
                    else
                        osascript -e "display dialog \"Could not renew automatically. Run in Terminal:

sudo ipconfig set \\\"$ETHERNET_IF\\\" DHCP\" with title \"Ethernet DHCP\" buttons {\"OK\"} default button \"OK\" with icon caution" 2>/dev/null
                    fi
                fi
            else
                osascript -e 'display dialog "No Ethernet interface detected" with title "Ethernet DHCP" buttons {"OK"} default button "OK"' 2>/dev/null
            fi
            ;;
            
        "Reset Ethernet")
            if [ -n "$ETHERNET_IF" ]; then
                RESULT=$(osascript -e "display dialog \"Reset Ethernet interface ($ETHERNET_IF)?

This will bring the interface down and back up.\" buttons {\"Cancel\", \"Reset\"} default button \"Reset\" with icon caution" 2>/dev/null)
                
                if [[ "$RESULT" == *"Reset"* ]]; then
                    if sudo -n /sbin/ifconfig "$ETHERNET_IF" down 2>/dev/null; then
                        sleep 2
                        sudo -n /sbin/ifconfig "$ETHERNET_IF" up 2>/dev/null
                        osascript -e "display dialog \"Reset the Ethernet interface ($ETHERNET_IF).\" with title \"Reset Ethernet\" buttons {\"OK\"} default button \"OK\"" 2>/dev/null
                    else
                        osascript -e "display dialog \"Could not reset automatically. Run in Terminal:

sudo ifconfig \\\"$ETHERNET_IF\\\" down
sleep 2
sudo ifconfig \\\"$ETHERNET_IF\\\" up\" with title \"Reset Ethernet\" buttons {\"OK\"} default button \"OK\" with icon caution" 2>/dev/null
                    fi
                fi
            else
                osascript -e 'display dialog "No Ethernet interface detected" with title "Reset Ethernet" buttons {"OK"} default button "OK"' 2>/dev/null
            fi
            ;;
            
        "Renew Wireless")
            if [ -n "$WIFI_IF" ]; then
                RESULT=$(osascript -e "display dialog \"Renew WiFi DHCP lease ($WIFI_IF)?\" buttons {\"Cancel\", \"Renew\"} default button \"Renew\" with icon caution" 2>/dev/null)
                
                if [[ "$RESULT" == *"Renew"* ]]; then
                    if sudo -n /usr/sbin/ipconfig set "$WIFI_IF" DHCP 2>/dev/null; then
                        osascript -e "display dialog \"Renewed the DHCP lease for WiFi ($WIFI_IF).\" with title \"WiFi DHCP\" buttons {\"OK\"} default button \"OK\"" 2>/dev/null
                    else
                        osascript -e "display dialog \"Could not renew automatically. Run in Terminal:

sudo ipconfig set \\\"$WIFI_IF\\\" DHCP\" with title \"WiFi DHCP\" buttons {\"OK\"} default button \"OK\" with icon caution" 2>/dev/null
                    fi
                fi
            else
                osascript -e 'display dialog "No WiFi interface detected" with title "WiFi DHCP" buttons {"OK"} default button "OK"' 2>/dev/null
            fi
            ;;
            
        "Reset WiFi")
            RESULT=$(osascript -e 'display dialog "Reset WiFi?

This will turn WiFi off and back on." buttons {"Cancel", "Reset"} default button "Reset" with icon caution' 2>/dev/null)
            
            if [[ "$RESULT" == *"Reset"* ]]; then
                if sudo -n /usr/sbin/networksetup -setnetworkserviceenabled "Wi-Fi" off 2>/dev/null; then
                    sleep 3
                    sudo -n /usr/sbin/networksetup -setnetworkserviceenabled "Wi-Fi" on 2>/dev/null
                    osascript -e 'display dialog "WiFi has been reset." with title "Reset WiFi" buttons {"OK"} default button "OK"' 2>/dev/null
                else
                    osascript -e 'display dialog "Could not reset automatically. Run in Terminal:

sudo networksetup -setnetworkserviceenabled \"Wi-Fi\" off
sleep 3
sudo networksetup -setnetworkserviceenabled \"Wi-Fi\" on" with title "Reset WiFi" buttons {"OK"} default button "OK" with icon caution' 2>/dev/null
                fi
            fi
            ;;
            
        "Disable IP Tracking")
            RESULT=$(osascript -e 'display dialog "Disable IP address tracking?

This will enable Private WiFi Address (if available) and disable IP tracking." buttons {"Cancel", "Enable"} default button "Enable" with icon note' 2>/dev/null)

            if [[ "$RESULT" == *"Enable"* ]]; then
                if sudo -n /usr/bin/defaults write /Library/Preferences/SystemConfiguration/com.apple.wifi.plist WiFiRandomMAC -bool true 2>/dev/null; then
                    osascript -e 'display dialog "IP tracking has been disabled at the system level.

For full effect, also enable Private WiFi Address in:
System Preferences > Network > WiFi > Advanced > WiFi

Restart WiFi after changes." with title "Disable IP Tracking" buttons {"OK"} default button "OK"' 2>/dev/null
                else
                    osascript -e 'display dialog "Could not disable automatically. Run in Terminal:

sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.wifi.plist WiFiRandomMAC -bool true

Then also enable Private WiFi Address in:
System Preferences > Network > WiFi > Advanced > WiFi" with title "Disable IP Tracking" buttons {"OK"} default button "OK" with icon caution' 2>/dev/null
                fi
            fi
            ;;
            
        "Open Network Prefs")
            open "/System/Library/PreferencePanes/Network.prefPane"
            ;;
            
        "Open Keychain")
            open -a "Keychain Access"
            ;;
            
        "Open Directory Utility")
            open "/System/Library/CoreServices/Applications/Directory Utility.app"
            ;;
            
        "Quit")
            echo "QUITAPP"
            ;;
            
        *)
            osascript -e "display dialog \"Unknown command: $menu_choice\" with title \"Error\" buttons {\"OK\"} default button \"OK\"" 2>/dev/null
            ;;
    esac
fi