# ConnectMe

Menu bar network toolkit - shows connection info and lets you reset/renew network
interfaces from the menu bar, instead of digging through System Preferences or Terminal.

Menu items (all show their result as an AppleScript dialog):

* Show Network Info - hostname, AD domain, active interface, IP, MAC, gateway, DNS
* Show Dot1X Status - checks for 802.1X processes/certificates and shows where 802.1X is configured
* Reset DNS Cache - `dscacheutil -flushcache` + `killall -HUP mDNSResponder` (confirms first)
* Renew Ethernet IP / Reset Ethernet - runs the `ipconfig`/`ifconfig` commands directly (confirms first)
* Renew Wireless IP / Reset WiFi - same, for WiFi
* Disable IP Tracking - sets the Private WiFi Address default, then points you at the
  System Preferences toggle for the rest (that part's GUI-only, can't be scripted)
* Open Network Prefs / Open Keychain / Open Directory Utility - opens the relevant system pane/app

## How it works

Six of these actions (DNS reset, Ethernet/WiFi renew/reset, IP tracking) need root, so the
installer sets up a sudoers drop-in (`/etc/sudoers.d/connectme`) granting passwordless
`sudo` for just those specific commands (with fixed arguments, not blanket access to
`ifconfig`/`networksetup`/etc.) - the app itself never shows a password prompt.

If the sudoers drop-in isn't installed for some reason, each action falls back to showing
the manual command to paste into Terminal instead.

## Installing

### Via Homebrew

```
brew tap aardman/connectMe https://github.com/aardman/connectMe
brew install --cask connectme
```

The explicit URL on `brew tap` is needed because this repo isn't named `homebrew-connectMe`
- Homebrew's short `brew tap aardman/connectMe` form only looks for a repo with that exact
prefix, so the URL tells it where to actually find this one.

`brew uninstall --cask connectme` removes the app, forgets the package receipt, and removes
the sudoers drop-in.

### Manually

Download `ConnectMe.pkg` from the [Releases](../../releases) page (or build it yourself,
see below) and run:

```
sudo installer -pkg ConnectMe.pkg -target /
```

This installs the app to `/Applications/ConnectMe.app` and sets up the sudoers drop-in via
a postinstall script. Launch it from Spotlight, Finder, or your MDM of choice - it isn't
set to launch automatically at login.

## Building from source

Requires [Platypus](https://sveinbjorn.org/platypus) (`/Applications/Platypus.app`).

```
./build.sh      # (re)builds ConnectMe.app from connectMe.sh
./package.sh    # builds ConnectMe.pkg from ConnectMe.app
```

`package.sh` also disables `pkgbuild`'s default bundle relocation
(`BundleIsRelocatable`): without this, if Launch Services already knows an app with this
identifier exists somewhere (e.g. this very app, having been run once from a local
checkout), the installer silently installs *there* instead of `/Applications` - no error,
no warning. Worth checking `pkgutil --payload-files ConnectMe.pkg` after any change to
confirm it still lands where you expect.

## Files

* `connectMe.sh` - the wrapped script
* `network_info_helper.sh` - a standalone terminal version of the network-info lookup; not
  called by `connectMe.sh` itself, just bundled alongside it for reference
* `build.sh` - rebuilds `ConnectMe.app` from `connectMe.sh`
* `postinstall` - the package postinstall that installs the sudoers drop-in
* `install-sudoers.sh` - the same sudoers setup, standalone, for manual/local testing
  (`sudo bash install-sudoers.sh`)
* `package.sh` - builds `ConnectMe.pkg` from `ConnectMe.app`
* `Casks/connectme.rb` - the Homebrew cask definition (this repo doubles as its own tap)

## Releasing a new version

1. Bump the version in both `build.sh` (`-V`) and `package.sh` (`VERSION=`), then
   `./build.sh && ./package.sh`
2. `shasum -a 256 ConnectMe.pkg` and update `version`/`sha256` in `Casks/connectme.rb` to
   match
3. Commit, push, then `gh release create vX.Y.Z ConnectMe.pkg` (or create the release and
   upload `ConnectMe.pkg` as an asset via the GitHub UI) - the cask's `url` expects it at
   `releases/download/vX.Y.Z/ConnectMe.pkg`
4. `brew audit --cask` and `brew style --cask` against the tapped cask before calling it done

## License

MIT - see [LICENSE](LICENSE).
