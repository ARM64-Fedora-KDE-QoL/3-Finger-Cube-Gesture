# 3-Finger-Cube-Gesture

**Built on ARM64 Linux Fedora 44 Asahi KDE Plasma**

Open and close KDE Plasma's **Desktop Cube** with a three-finger swipe on your touchpad.

| Gesture | Result |
|---|---|
| 3-finger swipe **up** | Opens the Desktop Cube (does nothing if it's already open) |
| 3-finger swipe **down** | Closes the Desktop Cube (does nothing if it's already closed) |
| 3-finger swipe left / right, 4-finger swipes | Unchanged; still handled by KDE |

It uses the [InputActions](https://github.com/taj-ny/InputActions) KWin plugin, which the installer builds from source. It also sets up **automatic rebuilds after KWin updates**, so the gesture keeps working without you doing anything.

**InputActions version:** the installer builds a fixed, tested snapshot of InputActions (commit `e3dfb18`, from the project's former main repository, around v0.9.0), not the newest release. That keeps installs predictable, but it means newer InputActions features and fixes aren't included. See [Security notes](#security-notes) for the one place this matters.

## Requirements

- Fedora with KDE Plasma 6, logged in to a **Wayland** session (the default on Fedora KDE)
- A touchpad
- A user account with `sudo` rights (the account created during Fedora setup has them)
- An internet connection (to download packages and InputActions)

Built and tested on **ARM64 Linux Fedora 44 Asahi KDE Plasma**: Fedora Linux Asahi Remix 44 (KDE Plasma Desktop Edition) on an Apple Silicon MacBook (aarch64), with KDE Plasma / KWin 6.7.5. Nothing in it is ARM-specific, so it should also work on regular Fedora KDE, but that hasn't been tested yet.

You don't need to set up the Desktop Cube yourself: the installer installs it (package `kdeplasma-addons`) and turns it on if it's off.

## Install

You need `git` to download this project. Many Fedora installs already have it; if `git --version` says *command not found*, install it first:

```bash
sudo dnf install git
```

Then download and run the installer:

```bash
git clone https://github.com/Cynders-dev/3-Finger-Cube-Gesture.git
cd 3-Finger-Cube-Gesture
./install.sh
```

**Without git:** on this page, click **Code → Download ZIP**, extract it, open a terminal in the extracted folder, and run `bash install.sh`. Use `bash install.sh` rather than `./install.sh` here, because ZIP downloads can lose the "executable" permission.

Run the installer as your normal user, **not** with `sudo` in front. It asks for your password **once** at the start, then installs everything without further questions. The first run downloads the packages and builds InputActions, which takes a few minutes. When it says **Done**, swipe up with three fingers.

If you already use InputActions, back up `~/.config/inputactions/config.yaml` first. The installer replaces it with the cube gestures. It saves the old file as `config.yaml.bak.<date>`, but your other gestures won't be active until you merge them back in.

## Keyboard shortcut (Meta+C)

KDE opens the Desktop Cube with **Meta+C** by default (Meta is the Windows key, or ⌘ Command on a Mac keyboard).

**The gesture works no matter which keys your cube shortcut uses.** It doesn't press Meta+C. Instead, it asks KDE to run the cube's shortcut *action*, called `Cube`, directly. So if you've changed the cube shortcut to Meta+K, or anything else, or removed the key binding entirely, the swipe still works. There's nothing to configure.

The installer finds the action's name in `~/.config/kglobalshortcutsrc` and prints it during install (`Found: kwin,Cube`). That line in the file looks like `Cube=Meta+C,Meta+C,Toggle Cube`, meaning: action name = current keys, default keys, label. Changing the keys only changes the part after `=`.

## Packages it needs

`install.sh` installs **all of these automatically**. This list is for troubleshooting: if a step fails with an error mentioning one of them, that package is missing, and the command at the end installs them all by hand.

**Build tools and libraries** (needed to build the InputActions plugin):

| Package | What it's for | If it's missing, you'll see… |
|---|---|---|
| `git` | Downloads this project and InputActions | `git: command not found` |
| `gcc-c++` | C++ compiler | CMake: `No CMAKE_CXX_COMPILER could be found` |
| `cmake` | Build system | `cmake: command not found` |
| `extra-cmake-modules` | KDE's CMake helpers | CMake error mentioning `ECM` |
| `pkgconf-pkg-config` | Finds libraries during the build | CMake error mentioning `PkgConfig` |
| `kwin-devel` | KWin headers; **must match your installed KWin version** | CMake error mentioning `KWin` |
| `qt6-qtbase-devel` | Qt 6 headers | CMake error mentioning `Qt6` |
| `kf6-kcmutils-devel`, `kf6-ki18n-devel`, `kf6-kguiaddons-devel`, `kf6-kcoreaddons-devel` | KDE Frameworks headers | CMake error mentioning `KF6…` |
| `libevdev-devel` | Reads touchpad events directly | CMake error mentioning `libevdev` |
| `libxkbcommon-devel` | Keyboard handling | CMake error mentioning `XKB` / `xkbcommon` |
| `yaml-cpp-devel` | Reads the gesture config file | CMake error mentioning `yaml-cpp` |
| `libinput-devel` | Input device library headers | CMake error mentioning `libinput` |
| `libepoxy-devel` | OpenGL helper KWin's headers need | CMake: `Could NOT find epoxy` |
| `libdrm-devel` | Graphics library KWin's headers need | CMake error mentioning `Libdrm` |

**Tools the installer and the automatic rebuilds use:**

| Package | What it's for | If it's missing, you'll see… |
|---|---|---|
| `kdeplasma-addons` | Provides the **Desktop Cube** effect | Gesture fires but no cube; cube missing from Desktop Effects |
| `qt6-qttools` | `qdbus-qt6`, which talks to KWin | `Couldn't find qdbus …` from the installer |
| `kf6-kconfig` | `kwriteconfig6`, which turns effects on | `kwriteconfig6: command not found` |
| `libdnf5-plugin-actions` | Lets dnf run the rebuild after KWin updates | No automatic rebuild; "needs a rebuild" warning at login |
| `rsync` | Copies the source for automatic rebuilds | `rsync: command not found` |
| `libnotify` | `notify-send`, for desktop notifications | No rebuild notifications |

To install them all by hand:

```bash
sudo dnf install git gcc-c++ cmake extra-cmake-modules pkgconf-pkg-config \
  kwin-devel qt6-qtbase-devel \
  kf6-kcmutils-devel kf6-ki18n-devel kf6-kguiaddons-devel kf6-kcoreaddons-devel \
  libevdev-devel libxkbcommon-devel yaml-cpp-devel libinput-devel \
  libepoxy-devel libdrm-devel \
  libdnf5-plugin-actions rsync libnotify \
  qt6-qttools kf6-kconfig kdeplasma-addons
```

`kwin-devel` must be the same version as `kwin`. Check with `rpm -q kwin kwin-devel`; if the versions differ, run `sudo dnf upgrade kwin kwin-devel` first.

## What it changes on your system

| What | Where | Why |
|---|---|---|
| Build packages | `dnf install` (kwin-devel, cmake, gcc-c++, …) | Needed to build the plugin |
| InputActions source | `~/.local/src/InputActions` | Downloaded from GitHub |
| Root-owned source copy and build | `/var/lib/cube-gesture/` | Used for automatic rebuilds (see [Security notes](#security-notes)) |
| KWin plugin | `/usr/lib64/qt6/plugins/kwin/effects/plugins/kwin_gestures.so`, `…/configs/inputactions_kwin_kcm.so` | The plugin itself |
| Gesture config | `~/.config/inputactions/config.yaml` | The up/down cube gestures |
| Touchpad udev rule | `/etc/udev/rules.d/70-touchpad-uaccess.rules` | Lets the plugin count fingers (see below) |
| Rebuild helper | `/usr/local/sbin/cube-gesture-rebuild`, `/etc/cube-gesture.conf` | Rebuilds the plugin for a new KWin |
| dnf hook | `/etc/dnf/libdnf5-plugins/actions.d/cube-gesture.actions` (+ the `libdnf5-plugin-actions` package) | Runs the helper after a kwin update |
| Boot check | `cube-gesture-rebuild.service` (systemd) | Backstop if the hook didn't run |
| Login check | `~/.local/bin/cube-gesture-check`, `~/.config/autostart/cube-gesture-check.desktop` | Notifies you about rebuilds or failures |
| Rebuild log | `/var/log/cube-gesture-rebuild.log` | Output of every rebuild |

## How KWin updates are handled

InputActions is compiled against KWin's internal code, so it has to be rebuilt for each new KWin version. The installer sets that up so it happens automatically:

1. **After an update through `dnf` or Discover**, a dnf hook rebuilds the plugin (about 40 seconds) and shows a *"Cube gesture plugin rebuilt"* notification. Log out and back in to start using the new KWin.
2. **Offline updates** (Discover's default) are applied during a reboot, before anyone logs in. A boot service rebuilds the plugin before the login screen appears, and you get the notification after you log in.
3. **If a rebuild fails**, you get a *"Cube gesture needs a rebuild"* warning at every login until it's fixed. Re-run `./install.sh`, and check `/var/log/cube-gesture-rebuild.log` for details.

Automatic rebuilds reuse the InputActions version you already have. Re-running `./install.sh` rebuilds the same pinned version; moving to a newer InputActions means changing `INPUTACTIONS_COMMIT` near the top of `install.sh` and re-testing the gestures.

## Security notes

**The touchpad udev rule.** InputActions counts fingers by reading the touchpad device (`/dev/input/event*`) directly. On Fedora only root and the `input` group can open it, and KWin runs as you, so without the rule every swipe reports 0 fingers and the gestures never fire. The rule is:

```
SUBSYSTEM=="input", KERNEL=="event*", ENV{ID_INPUT_TOUCHPAD}=="1", TAG+="uaccess"
```

It gives the user logged in at the machine access to **touchpads only**, the same way Fedora already grants access to sound cards and webcams. The trade-off: any program running as you could read raw finger positions from the touchpad. Keystrokes aren't exposed, because keyboards are separate devices that the rule doesn't match. Adding yourself to the `input` group would also work, but it would expose the keyboard too, so this project avoids it.

With the InputActions version this project builds, the rule is **required**: that version takes its finger count only from reading the device, ignoring the count KWin provides. Newer InputActions releases have fixed this, and their wiki lists a similar rule as an optional extra ("Additional setup") for advanced touchpad features.

**Automatic rebuilds run as root.** They build only from a root-owned copy of the source (`/var/lib/cube-gesture/src`). That copy is refreshed only when you run `./install.sh` yourself, so nothing you or your programs can edit is ever built or run as root without your password. New plugin files are swapped in with an atomic rename, so the running KWin isn't disturbed.

## Uninstall

```bash
./uninstall.sh            # removes everything; keeps your config (renamed) and the downloaded source
./uninstall.sh --purge    # also deletes the config and ~/.local/src/InputActions
```

It removes the plugin, the udev rule, the rebuild helper, the dnf hook, the boot service and the login check. The build packages installed with dnf are left in place. Log out and back in afterwards.

## Troubleshooting

- **Nothing happens when I swipe.** Check for config errors:
  `qdbus-qt6 org.inputactions / org.inputactions.issues`
  Then check that the touchpad can be read: `qdbus-qt6 org.inputactions / org.inputactions.deviceList` should show `multiTouch: true` for your touchpad. If it says `false`, the udev rule isn't active. Re-run `./install.sh`, then log out and back in.
- **The cube doesn't open even though the gesture fires.** Make sure the Desktop Cube effect is enabled (System Settings → Window Management → Desktop Effects → Desktop Cube) and that its keyboard shortcut opens it (Meta+C by default). You can also test the action the gesture uses directly:
  `qdbus-qt6 org.kde.kglobalaccel /component/kwin org.kde.kglobalaccel.Component.invokeShortcut Cube`
- **I got a "needs a rebuild" notification.** Re-run `./install.sh` and check `/var/log/cube-gesture-rebuild.log`.

## License

Copyright (C) 2026 Cynders. Licensed under the [GNU General Public License v3.0 or later](LICENSE): you can use, modify and share this project, and any modified versions you distribute must stay open source under the same license. It comes with no warranty.

## Credits

- [InputActions](https://github.com/taj-ny/InputActions) by its developers (GPL-3.0), which does all the gesture work. This project only builds, configures and maintains it.
- KDE Plasma's Desktop Cube effect.
