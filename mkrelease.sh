#!/bin/sh

xcodebuild install
pkgbuild --analyze --root /tmp/syncthing-bar.dst syncthing-bar.plist
pkgbuild --root /tmp/syncthing-bar.dst --component-plist syncthing-bar.plist --scripts scripts syncthing-bar.pkg
