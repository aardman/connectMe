cask "connectme" do
  version "1.0.0"
  sha256 "d4eb98aca2888466baabb8f3f79e9be6e3cf64fc3010161037726c0389f82f89"

  url "https://github.com/aardman/connectMe/releases/download/v#{version}/ConnectMe.pkg"
  name "ConnectMe"
  desc "Menu bar network toolkit for connection info and interface resets"
  homepage "https://github.com/aardman/connectMe"

  depends_on :macos

  pkg "ConnectMe.pkg"

  uninstall quit:    "org.aardman.ConnectMe",
            pkgutil: "org.aardman.ConnectMe.pkg",
            delete:  [
              "/Applications/ConnectMe.app",
              "/etc/sudoers.d/connectme",
            ]
end
