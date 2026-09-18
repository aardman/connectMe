#!/bin/bash
#
# Rebuilds ConnectMe.app from connectMe.sh using Platypus.
#
# Platypus's own command line tool (platypus_clt) expects its ScriptExec
# binary and nib to live in /usr/local/share/platypus, which normally only
# get installed there via Platypus > Preferences > "Install command line
# tool". Rather than touching that shared system location, this script
# decodes the bundled ScriptExec straight out of Platypus.app into a local
# .build/ dir and points platypus_clt at it directly.

set -euo pipefail
cd "$(dirname "$0")"

PLATYPUS_APP="/Applications/Platypus.app/Contents/Resources"
PLATYPUS_CLT="$PLATYPUS_APP/platypus_clt"

if [ ! -x "$PLATYPUS_CLT" ]; then
    echo "Platypus.app not found at /Applications/Platypus.app" >&2
    exit 1
fi

mkdir -p .build
base64 -d -i "$PLATYPUS_APP/ScriptExec.b64" > .build/ScriptExec
chmod +x .build/ScriptExec

rm -rf ConnectMe.app
"$PLATYPUS_CLT" \
    -a "ConnectMe" \
    -o "Status Menu" \
    -p /bin/bash \
    -V "1.0.0" \
    -u "Nathan Taylor" \
    -I "org.aardman.ConnectMe" \
    -B \
    -K "Icon" \
    -L "./network-right-solid.png" \
    -q \
    -Y "ConnectMe" \
    -i "./AppIcon.icns" \
    -f "network_info_helper.sh" \
    -e "$(pwd)/.build/ScriptExec" \
    -E "$PLATYPUS_APP/MainMenu.nib" \
    -y \
    connectMe.sh \
    ConnectMe.app

echo "Built ConnectMe.app"
