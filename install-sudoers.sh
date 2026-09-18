#!/bin/bash
#
# Installs a sudoers drop-in granting passwordless sudo for the specific
# network commands ConnectMe.app needs, so those actions actually run
# instead of just showing the user a command to paste into Terminal.
# Deploy this via Kandji (e.g. as a postinstall/custom script) alongside
# ConnectMe.app, run as root.

set -euo pipefail

SUDOERS_FILE="/etc/sudoers.d/connectme"

TMPFILE="$(mktemp)"
trap 'rm -f "$TMPFILE"' EXIT

cat > "$TMPFILE" << 'EOF'
# Allow any user to run these specific network commands without a password - used by ConnectMe.app
ALL ALL=(root) NOPASSWD: /usr/bin/dscacheutil -flushcache, \
                         /usr/bin/killall -HUP mDNSResponder, \
                         /usr/sbin/ipconfig set * DHCP, \
                         /sbin/ifconfig * down, \
                         /sbin/ifconfig * up, \
                         /usr/sbin/networksetup -setnetworkserviceenabled "Wi-Fi" off, \
                         /usr/sbin/networksetup -setnetworkserviceenabled "Wi-Fi" on, \
                         /usr/bin/defaults write /Library/Preferences/SystemConfiguration/com.apple.wifi.plist WiFiRandomMAC -bool true
EOF

if ! /usr/sbin/visudo -cf "$TMPFILE"; then
    echo "Generated sudoers file failed validation, not installed" >&2
    exit 1
fi

install -m 0440 -o root -g wheel "$TMPFILE" "$SUDOERS_FILE"
echo "Installed $SUDOERS_FILE"
