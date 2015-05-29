#!/bin/sh

xcodebuild install
pkgbuild --analyze --root /tmp/syncthing-bar.dst syncthing-bar.plist
pkgbuild --root /tmp/syncthing-bar.dst --component-plist syncthing-bar.plist --scripts scripts --version $1 syncthing-bar-$1.pkg
