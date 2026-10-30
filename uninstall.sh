#!/usr/bin/env bash
# uninstall.sh - 3-Finger-Cube-Gesture
#
# Removes everything install.sh added: the InputActions KWin plugin, the automatic-rebuild
# helper and its dnf hook / boot service, the touchpad udev rule, and the login check.
#
# Kept unless you pass --purge:
#   ~/.config/inputactions/config.yaml   (renamed to config.yaml.uninstalled-<date>)
#   ~/.local/src/inputactions-kwin        (the downloaded source)
# Always kept: the build packages installed with dnf (kwin-devel, cmake, ...).
#
# Usage (as your normal user; it asks for sudo when needed):
#   ./uninstall.sh [--purge]
#
# Copyright (C) 2026 Cynders
# SPDX-License-Identifier: GPL-3.0-or-later
# This program is free software: you can redistribute it and/or modify it under the terms of
# the GNU General Public License as published by the Free Software Foundation, either version 3
# of the License, or (at your option) any later version. It is distributed WITHOUT ANY WARRANTY;
# see the LICENSE file for details.

set -euo pipefail

PURGE=false
[[ "${1:-}" == "--purge" ]] && PURGE=true

say() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }

if [[ $EUID -eq 0 ]]; then
  echo "Run this as your normal user, not root (it will ask for sudo when needed)."
  exit 1
fi

PLUGIN_FILES=(
  /usr/lib64/qt6/plugins/kwin/effects/plugins/kwin_gestures.so
  /usr/lib64/qt6/plugins/kwin/effects/configs/inputactions_kwin_kcm.so
)
UDEV_RULE_FILE=/etc/udev/rules.d/70-touchpad-uaccess.rules
CONFIG_FILE="$HOME/.config/inputactions/config.yaml"
SRC_DIR="$HOME/.local/src/inputactions-kwin"

QDBUS=""
for q in qdbus6 qdbus-qt6 qdbus; do
  if command -v "$q" >/dev/null 2>&1; then QDBUS="$(command -v "$q")"; break; fi
done

# --- 1. Stop the plugin -----------------------------------------------------
say "Unloading the InputActions effect from KWin"
if [[ -n "$QDBUS" ]]; then
  for effect in inputactions kwin_gestures; do
    "$QDBUS" org.kde.KWin /Effects org.kde.kwin.Effects.unloadEffect "$effect" >/dev/null 2>&1 || true
  done
fi
for effect in inputactions kwin_gestures; do
  kwriteconfig6 --file kwinrc --group Plugins --key "${effect}Enabled" --delete 2>/dev/null || true
done

# --- 2. Automatic rebuilds ---------------------------------------------------
say "Removing the automatic-rebuild helper, dnf hook and boot service (sudo)"
sudo systemctl disable cube-gesture-rebuild.service 2>/dev/null || true
sudo rm -f \
  /etc/systemd/system/cube-gesture-rebuild.service \
  /etc/dnf/libdnf5-plugins/actions.d/cube-gesture.actions \
  /usr/local/sbin/cube-gesture-rebuild \
  /etc/cube-gesture.conf \
  /var/log/cube-gesture-rebuild.log
sudo systemctl daemon-reload
sudo rm -rf /var/lib/cube-gesture

# --- 3. Plugin files ---------------------------------------------------------
# Removing a file a running KWin has loaded is safe: KWin keeps its open copy until logout.
say "Removing the plugin files (sudo)"
sudo rm -f "${PLUGIN_FILES[@]}"

# --- 4. Touchpad udev rule ---------------------------------------------------
if [[ -f "$UDEV_RULE_FILE" ]]; then
  say "Removing the touchpad udev rule (sudo)"
  sudo rm -f "$UDEV_RULE_FILE"
  sudo udevadm control --reload
  sudo udevadm trigger --subsystem-match=input --action=change
fi

# --- 5. Login check ----------------------------------------------------------
say "Removing the login check"
rm -f "$HOME/.local/bin/cube-gesture-check" "$HOME/.config/autostart/cube-gesture-check.desktop"
rm -rf "${XDG_STATE_HOME:-$HOME/.local/state}/cube-gesture"

# --- 6. Config and source ----------------------------------------------------
if $PURGE; then
  say "Removing the gesture config and downloaded source (--purge)"
  rm -f "$CONFIG_FILE"
  rmdir "$(dirname "$CONFIG_FILE")" 2>/dev/null || true
  rm -rf "$SRC_DIR"
elif [[ -f "$CONFIG_FILE" ]]; then
  say "Setting the gesture config aside"
  mv "$CONFIG_FILE" "$CONFIG_FILE.uninstalled-$(date +%Y%m%d-%H%M%S)"
  echo "Renamed it so InputActions won't load it if you reinstall the plugin later."
fi

# --- Done -------------------------------------------------------------------
say "Done"
echo "The gestures stop working right away; log out and back in to finish unloading the plugin."
if ! $PURGE; then
  echo "Kept: $SRC_DIR and your old config (next to $CONFIG_FILE). Use --purge to remove them too."
fi
echo "The build packages installed with dnf were left in place."
