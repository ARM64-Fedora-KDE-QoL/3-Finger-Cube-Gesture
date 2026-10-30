#!/usr/bin/env bash
# install.sh - 3-Finger-Cube-Gesture
#
#   3-finger swipe up   on the touchpad -> open the KDE Desktop Cube
#   3-finger swipe down on the touchpad -> close it
#
# For Fedora KDE Plasma 6 (Wayland), tested on Fedora Asahi Remix 44 (Apple Silicon MacBook).
# Builds the InputActions KWin plugin (https://github.com/InputActions/kwin, release v0.9.2.1) from source,
# installs it, writes the gesture config, and sets up automatic rebuilds after KWin updates.
# See README.md for exactly what it changes on your system.
#
# Usage (as your normal user; it asks for sudo when needed):
#   ./install.sh
#
# The plugin must be rebuilt whenever KWin is updated. This script sets that up to happen
# automatically (dnf hook + boot check) and installs a login check that warns you if it didn't.
# Re-run this script if you get that warning.
# To remove everything: ./uninstall.sh
#
# Copyright (C) 2026 Cynders
# SPDX-License-Identifier: GPL-3.0-or-later
# This program is free software: you can redistribute it and/or modify it under the terms of
# the GNU General Public License as published by the Free Software Foundation, either version 3
# of the License, or (at your option) any later version. It is distributed WITHOUT ANY WARRANTY;
# see the LICENSE file for details.

set -euo pipefail

SRC_DIR="$HOME/.local/src/inputactions-kwin"

# InputActions version this project was tested with: the KWin plugin's v0.9.2.1 stable release.
# The installer builds exactly this commit (and the submodule commits it records), so an
# upstream change can't break new installs. To move to a newer release: change the commit
# below (git rev-parse 'vX.Y.Z^{commit}' in a clone of the repo), test, and commit the change.
INPUTACTIONS_REPO="https://github.com/InputActions/kwin"
INPUTACTIONS_COMMIT="f61770a60682d1ffb31010f210457cf4ff5228a0"   # v0.9.2.1
CONFIG_DIR="$HOME/.config/inputactions"
CONFIG_FILE="$CONFIG_DIR/config.yaml"

say() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m!!  %s\033[0m\n' "$*"; }

# --- 0. Sanity checks -------------------------------------------------------
if [[ $EUID -eq 0 ]]; then
  echo "Run this as your normal user, not root (it will ask for sudo when needed)."
  exit 1
fi

if [[ "${XDG_SESSION_TYPE:-}" != "wayland" ]]; then
  warn "You don't appear to be in a Wayland session. InputActions' KWin plugin needs Plasma Wayland."
fi

# Ask for the sudo password once, then keep sudo's timestamp fresh in the background so a long
# package download or build doesn't make it ask again partway through.
say "Some steps need sudo; enter your password once"
sudo -v
( while sleep 50; do kill -0 "$$" 2>/dev/null || exit; sudo -n -v 2>/dev/null || exit; done ) &
SUDO_KEEPALIVE_PID=$!
trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT

# --- 1. Build dependencies --------------------------------------------------
say "Installing build dependencies (sudo)"
sudo dnf install -y \
  git gcc-c++ cmake extra-cmake-modules pkgconf-pkg-config \
  kwin-devel qt6-qtbase-devel \
  kf6-kcmutils-devel kf6-ki18n-devel kf6-kguiaddons-devel kf6-kcoreaddons-devel \
  libevdev-devel libxkbcommon-devel yaml-cpp-devel libinput-devel \
  libepoxy-devel libdrm-devel \
  libdnf5-plugin-actions rsync libnotify \
  qt6-qttools kf6-kconfig kdeplasma-addons

# --- 2. Get the source ------------------------------------------------------
say "Fetching InputActions source (pinned to ${INPUTACTIONS_COMMIT:0:7})"
mkdir -p "$(dirname "$SRC_DIR")"
if [[ -d "$SRC_DIR/.git" ]]; then
  git -C "$SRC_DIR" fetch --quiet origin
else
  git clone --quiet "$INPUTACTIONS_REPO" "$SRC_DIR"
fi
git -C "$SRC_DIR" -c advice.detachedHead=false checkout --quiet "$INPUTACTIONS_COMMIT"
# The KWin plugin lives in a git submodule; check out the submodule commits this version records.
git -C "$SRC_DIR" submodule update --init --recursive

# --- 3. Rebuild helper, KWin-update hooks, build and install ----------------
# The plugin has to be rebuilt whenever KWin is updated. cube-gesture-rebuild does that as
# root from a root-owned copy of the source, so nothing you (or a program running as you)
# can edit ever gets built or run as root automatically. It is run:
#   - by this script, right below
#   - by dnf / Discover after an update that touches kwin (dnf5 actions plugin)
#   - at boot, before the login screen, as a backstop if the dnf hook didn't run
#     (e.g. Discover's offline updates); it exits immediately when nothing changed
HELPER=/usr/local/sbin/cube-gesture-rebuild
STATE_DIR=/var/lib/cube-gesture
REBUILD_LOG=/var/log/cube-gesture-rebuild.log

say "Installing the rebuild helper and KWin-update hooks (sudo)"
sudo tee "$HELPER" >/dev/null <<'EOF'
#!/usr/bin/env bash
# cube-gesture-rebuild: rebuild the InputActions KWin plugin against the installed KWin.
# Installed by 3-Finger-Cube-Gesture's install.sh. Runs as root.
#   (no args)  build and install now, output to the terminal and the log
#   --auto     used by the dnf hook and the boot service: log only (dnf reads our stdout),
#              do nothing if the plugin is already built for this KWin, notify the user
set -uo pipefail

STATE_DIR=/var/lib/cube-gesture
SRC_DIR=$STATE_DIR/src
BUILD_DIR=$STATE_DIR/build
STAGE_DIR=$STATE_DIR/stage
LOG=/var/log/cube-gesture-rebuild.log
CONF=/etc/cube-gesture.conf

AUTO=false
[[ "${1:-}" == "--auto" ]] && AUTO=true

touch "$LOG" && chmod 644 "$LOG"
if $AUTO; then exec >>"$LOG" 2>&1; else exec > >(tee -a "$LOG") 2>&1; fi
echo "=== $(date '+%F %T') cube-gesture-rebuild ${1:-} ==="

CUBE_USER=""
[[ -r "$CONF" ]] && source "$CONF"
KWIN="$(rpm -q --qf '%{VERSION}-%{RELEASE}' kwin)"
DEVEL="$(rpm -q --qf '%{VERSION}-%{RELEASE}' kwin-devel 2>/dev/null || echo missing)"

# Desktop notification to the logged-in user (only in --auto mode, only if their session is up).
notify() { # <urgency> <title> <body>
  $AUTO && [[ -n "$CUBE_USER" ]] || return 1
  local uid; uid="$(id -u "$CUBE_USER" 2>/dev/null)" || return 1
  [[ -S "/run/user/$uid/bus" ]] || return 1
  runuser -u "$CUBE_USER" -- env DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" \
    notify-send -a "Cube gesture" -u "$1" -i input-touchpad "$2" "$3"
}
fail() {
  echo "FAILED: $*"
  notify critical "Cube gesture rebuild failed" \
    "KWin is now $KWIN, but the 3-finger cube gesture plugin couldn't be rebuilt ($*). Re-run install.sh from 3-Finger-Cube-Gesture. Details: $LOG" || true
  exit 1
}

if $AUTO && [[ "$(cat "$STATE_DIR/built-for" 2>/dev/null)" == "$KWIN" ]]; then
  echo "Already built for kwin $KWIN; nothing to do."
  exit 0
fi
[[ "$DEVEL" == "$KWIN" ]] || fail "kwin-devel ($DEVEL) doesn't match kwin ($KWIN)"
[[ -f "$SRC_DIR/CMakeLists.txt" ]] || fail "source missing at $SRC_DIR"

rm -rf "$BUILD_DIR" "$STAGE_DIR"
cmake -S "$SRC_DIR" -B "$BUILD_DIR" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/usr || fail "cmake configure failed"
cmake --build "$BUILD_DIR" -j"$(nproc)" || fail "build failed"
DESTDIR="$STAGE_DIR" cmake --install "$BUILD_DIR" || fail "staged install failed"

# Swap each file into place with a rename. Overwriting a plugin that the running KWin has
# loaded can crash the session; a rename leaves KWin's open copy untouched until next login.
while IFS= read -r -d '' staged; do
  dest="${staged#"$STAGE_DIR"}"
  { install -D -m "$(stat -c %a "$staged")" "$staged" "$dest.new" && mv -f "$dest.new" "$dest"; } \
    || fail "couldn't install $dest"
  echo "Installed $dest"
done < <(find "$STAGE_DIR" -type f -print0)
rm -rf "$STAGE_DIR"

printf '%s\n' "$KWIN" > "$STATE_DIR/built-for"
chmod 644 "$STATE_DIR/built-for"
echo "OK: built for kwin $KWIN"

if notify normal "Cube gesture plugin rebuilt" \
  "KWin was updated to $KWIN and the 3-finger cube gesture plugin was rebuilt for it. Log out and back in to use the new KWin."; then
  # Tell the login check this update was already announced.
  runuser -u "$CUBE_USER" -- sh -c 'd="${XDG_STATE_HOME:-$HOME/.local/state}/cube-gesture"; mkdir -p "$d" && printf "%s\n" "$1" > "$d/notified-for"' sh "$KWIN" || true
fi
exit 0
EOF
sudo chmod 755 "$HELPER"
printf 'CUBE_USER=%s\n' "$USER" | sudo tee /etc/cube-gesture.conf >/dev/null

sudo mkdir -p /etc/dnf/libdnf5-plugins/actions.d
sudo tee /etc/dnf/libdnf5-plugins/actions.d/cube-gesture.actions >/dev/null <<EOF
# Rebuild the InputActions KWin plugin (3-finger cube gesture) after kwin is installed or upgraded.
# Installed by 3-Finger-Cube-Gesture's install.sh. Format: callback:package_filter:direction:options:command
post_transaction:kwin:in:enabled=host-only raise_error=0:$HELPER --auto
EOF

sudo tee /etc/systemd/system/cube-gesture-rebuild.service >/dev/null <<EOF
# Installed by 3-Finger-Cube-Gesture's install.sh
[Unit]
Description=Rebuild the InputActions KWin plugin if KWin was updated
After=local-fs.target
Before=display-manager.service

[Service]
Type=oneshot
ExecStart=$HELPER --auto
TimeoutStartSec=15min

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable cube-gesture-rebuild.service

say "Copying the source to $STATE_DIR/src (root-owned, so only root can change what gets built)"
sudo mkdir -p "$STATE_DIR"
sudo rsync -a --delete --chown=root:root --exclude=/build "$SRC_DIR/" "$STATE_DIR/src/"

say "Building and installing the KWin plugin (sudo; this takes a few minutes)"
sudo "$HELPER"

# --- 4. Let KWin read the touchpad (udev rule) ------------------------------
# With this InputActions release, basic swipes work without this rule (KWin supplies the finger
# count). The rule lets the plugin also read the touchpad device (/dev/input/event*) directly,
# which enables its extra touchpad features (thumb/palm detection, finger positions, pressure);
# the InputActions wiki recommends it as optional setup. It grants the logged-in user (and so
# KWin) access to touchpads only; keyboards are not affected.
UDEV_RULE_FILE="/etc/udev/rules.d/70-touchpad-uaccess.rules"
UDEV_RULE="$(cat <<'EOF'
# Let the logged-in user (and so KWin) read touchpad devices, so the InputActions
# KWin plugin can count fingers. Touchpads only; keyboards are not affected.
SUBSYSTEM=="input", KERNEL=="event*", ENV{ID_INPUT_TOUCHPAD}=="1", TAG+="uaccess"
EOF
)"

if [[ -f "$UDEV_RULE_FILE" ]] && [[ "$(cat "$UDEV_RULE_FILE")" == "$UDEV_RULE" ]]; then
  say "Touchpad udev rule already installed"
else
  say "Installing touchpad udev rule (sudo)"
  printf '%s\n' "$UDEV_RULE" | sudo tee "$UDEV_RULE_FILE" >/dev/null
  sudo chmod 644 "$UDEV_RULE_FILE"
  sudo udevadm control --reload
  sudo udevadm trigger --subsystem-match=input --action=change
  sudo udevadm settle
fi

# --- 5. Find qdbus and the cube's global shortcut name ----------------------
QDBUS=""
for q in qdbus6 qdbus-qt6 qdbus; do
  if command -v "$q" >/dev/null 2>&1; then QDBUS="$(command -v "$q")"; break; fi
done
if [[ -z "$QDBUS" ]]; then
  echo "Couldn't find qdbus (qdbus6 / qdbus-qt6 / qdbus). Install qt6-qttools and re-run."
  exit 1
fi

# The gesture needs KDE's Desktop Cube effect (package kdeplasma-addons, installed in step 1).
# Turn it on if it's off; its shortcut action only exists while the effect is enabled.
say "Checking that the Desktop Cube effect is enabled"
if [[ "$("$QDBUS" org.kde.KWin /Effects org.kde.kwin.Effects.isEffectLoaded cube 2>/dev/null || true)" == "true" ]]; then
  echo "Desktop Cube is enabled."
else
  kwriteconfig6 --file kwinrc --group Plugins --key cubeEnabled true
  if [[ "$("$QDBUS" org.kde.KWin /Effects org.kde.kwin.Effects.loadEffect cube 2>/dev/null || true)" == "true" ]]; then
    echo "Desktop Cube was off; turned it on."
    sleep 1
  else
    warn "Couldn't turn on the Desktop Cube. Enable it in System Settings -> Window Management -> Desktop Effects."
  fi
fi

# The gesture runs the cube's shortcut *action* by name (normally "Cube"), not a key combination,
# so it works no matter which keys are bound to the cube (Meta+C by default) - or none at all.
say "Looking up the Desktop Cube shortcut name"
SHORTCUT_NAME="$(awk -F= '
  /^\[/ { in_kwin = ($0 == "[kwin]") ; next }
  in_kwin && tolower($1) ~ /cube/ { print $1; exit }
' "$HOME/.config/kglobalshortcutsrc" 2>/dev/null || true)"

if [[ -z "$SHORTCUT_NAME" ]]; then
  SHORTCUT_NAME="Cube"
  warn "Couldn't find the cube in ~/.config/kglobalshortcutsrc; using the default name 'Cube'."
else
  echo "Found: kwin,$SHORTCUT_NAME"
fi

# --- 6. Write the gesture config --------------------------------------------
say "Writing $CONFIG_FILE"
mkdir -p "$CONFIG_DIR"
CUBE_IS_OPEN="$QDBUS org.kde.KWin /Effects org.freedesktop.DBus.Properties.Get org.kde.kwin.Effects activeEffects | grep -qx cube"
TOGGLE_CUBE="$QDBUS org.kde.kglobalaccel /component/kwin org.kde.kglobalaccel.Component.invokeShortcut $SHORTCUT_NAME"
NEW_CONFIG="$(cat <<EOF
# InputActions config:
#   3-finger swipe up   -> open the Desktop Cube (does nothing if it's already open)
#   3-finger swipe down -> close the Desktop Cube (does nothing if it's already closed)
# Docs: https://wiki.inputactions.org/main/
#
# The cube's shortcut action (kwin,$SHORTCUT_NAME) is a toggle, so each gesture first asks KWin
# whether the cube is currently running and only toggles when that's the right move.
touchpad:
  gestures:
    - type: swipe
      fingers: 3
      direction: up
      actions:
        - on: begin
          command: >-
            $CUBE_IS_OPEN
            || $TOGGLE_CUBE

    - type: swipe
      fingers: 3
      direction: down
      actions:
        - on: begin
          command: >-
            $CUBE_IS_OPEN
            && $TOGGLE_CUBE
EOF
)"

if [[ -f "$CONFIG_FILE" ]] && [[ "$(cat "$CONFIG_FILE")" == "$NEW_CONFIG" ]]; then
  echo "Config is already up to date; left it unchanged."
else
  if [[ -f "$CONFIG_FILE" ]]; then
    cp "$CONFIG_FILE" "$CONFIG_FILE.bak.$(date +%Y%m%d-%H%M%S)"
    echo "Backed up your existing config."
  fi
  printf '%s\n' "$NEW_CONFIG" > "$CONFIG_FILE"
fi

# --- 7. (Re)load the effect -------------------------------------------------
# Unload first so KWin picks up the freshly installed plugin and the plugin re-opens
# the touchpad with the access granted in step 4.
say "Loading the InputActions effect in KWin"
ENABLED=false
for effect in inputactions kwin_gestures; do
  "$QDBUS" org.kde.KWin /Effects org.kde.kwin.Effects.unloadEffect "$effect" >/dev/null 2>&1 || true
  if [[ "$("$QDBUS" org.kde.KWin /Effects org.kde.kwin.Effects.loadEffect "$effect" 2>/dev/null || true)" == "true" ]]; then
    kwriteconfig6 --file kwinrc --group Plugins --key "${effect}Enabled" true 2>/dev/null || true
    echo "Loaded effect: $effect"
    ENABLED=true
    break
  fi
done

# --- 8. Login check ---------------------------------------------------------
# At each login: warn if the plugin isn't built for the installed KWin (the automatic rebuild
# failed or didn't run), or say once that it was rebuilt if that wasn't announced already.
say "Installing the login check"
CHECK="$HOME/.local/bin/cube-gesture-check"
mkdir -p "$HOME/.local/bin" "$HOME/.config/autostart"
cat > "$CHECK" <<'EOF'
#!/usr/bin/env bash
# cube-gesture-check: run at login (installed by 3-Finger-Cube-Gesture's install.sh).
BUILT_FILE=/var/lib/cube-gesture/built-for
SEEN_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/cube-gesture"
SEEN_FILE="$SEEN_DIR/notified-for"

kwin="$(rpm -q --qf '%{VERSION}-%{RELEASE}' kwin)" || exit 0
built="$(cat "$BUILT_FILE" 2>/dev/null)"
mkdir -p "$SEEN_DIR"

if [[ "$built" != "$kwin" ]]; then
  notify-send -a "Cube gesture" -u critical -i input-touchpad "Cube gesture needs a rebuild" \
    "KWin $kwin is installed, but the 3-finger cube gesture plugin was built for ${built:-an unknown version}. Re-run install.sh from 3-Finger-Cube-Gesture. Log: /var/log/cube-gesture-rebuild.log"
elif [[ -f "$SEEN_FILE" && "$(cat "$SEEN_FILE")" != "$kwin" ]]; then
  notify-send -a "Cube gesture" -i input-touchpad "Cube gesture plugin rebuilt" \
    "KWin was updated to $kwin and the 3-finger cube gesture plugin was rebuilt automatically."
  printf '%s\n' "$kwin" > "$SEEN_FILE"
else
  printf '%s\n' "$kwin" > "$SEEN_FILE"
fi
EOF
chmod 755 "$CHECK"
cat > "$HOME/.config/autostart/cube-gesture-check.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Cube gesture check
Comment=Warns if a KWin update left the 3-finger cube gesture plugin out of date
Exec=$CHECK
X-KDE-autostart-phase=2
NoDisplay=true
EOF
"$CHECK"

# --- Done -------------------------------------------------------------------
say "Done"
if $ENABLED; then
  echo "Swipe up with three fingers to open the cube, and down with three fingers to close it."
else
  echo "Couldn't load the effect automatically. Log out and back in, then go to:"
  echo "  System Settings -> Window Management -> Desktop Effects -> enable 'InputActions'"
fi
echo
echo "If a gesture does nothing, check for config errors with:"
echo "  $QDBUS org.inputactions / org.inputactions.issues"
echo "KWin updates now rebuild the plugin automatically; log: $REBUILD_LOG"
