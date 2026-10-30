# 3-Finger-Cube-Gesture

**Built on ARM64 Linux Fedora 44 Asahi KDE Plasma**

Open, turn and close KDE Plasma's **Desktop Cube** with swipes on your touchpad.

| Gesture | Result |
|---|---|
| 3-finger swipe **up** | Opens the Desktop Cube (does nothing if it's already open) |
| 3- or 4-finger swipe **left / right** in the open cube | **Turns the cube smoothly with your fingers**, as far as you swipe; lifting your fingers snaps it to a desktop ([details](#smooth-swiping-in-the-cube)) |
| 3-finger swipe **down** | Closes the Desktop Cube (does nothing if it's already closed); after a smooth swipe, you land on the desktop you swiped to |
| **↓** (Down arrow) in the open cube | Goes into the desktop facing you |
| Any swipe while the cube is closed | Unchanged; still handled by KDE |

If you turn the Desktop Cube effect **off**, all these swipes are automatically handed back to KDE, and they return to the cube when you turn it back on ([details](#turning-off-the-desktop-cube-or-the-gestures)).

It uses the [InputActions](https://github.com/InputActions/kwin) KWin plugin, which the installer builds from source, plus a small patch to KDE's cube for smooth swiping. It also sets up **automatic rebuilds after KWin and KDE updates**, so everything keeps working without you doing anything.

**Related projects:** [**Cube-Backside-Click**](https://github.com/ARM64-Fedora-KDE-QoL/Cube-Backside-Click) lets you click the *back* of a desktop inside the open cube to switch to it (KDE's cube normally ignores that). Both are part of [**ARM64-Fedora-KDE-QoL**](https://github.com/ARM64-Fedora-KDE-QoL/ARM64-Fedora-KDE-QoL), which installs them together.

**InputActions version:** the installer builds the InputActions KWin plugin's **v0.9.2.1** stable release, from the project's maintained [`InputActions/kwin`](https://github.com/InputActions/kwin) repository. It's pinned to that exact release, so a future upstream change can't break new installs.

## Versions

There are four releases of this project. **3-finger up/down, the installer and the automatic rebuilds are the same in all of them.** v2.0 changed which copy of InputActions is built (so it keeps working longer); v3.0 adds automatic handling of the Desktop Cube being turned off; v4.0 adds smooth left/right swiping inside the cube.

| | [v1.0](https://github.com/ARM64-Fedora-KDE-QoL/3-Finger-Cube-Gesture/releases/tag/v1.0) (old) | [v2.0](https://github.com/ARM64-Fedora-KDE-QoL/3-Finger-Cube-Gesture/releases/tag/v2.0) | [v3.0](https://github.com/ARM64-Fedora-KDE-QoL/3-Finger-Cube-Gesture/releases/tag/v3.0) | **[v4.0](https://github.com/ARM64-Fedora-KDE-QoL/3-Finger-Cube-Gesture/releases/tag/v4.0) (current, recommended)** |
|---|---|---|---|---|
| InputActions source | Frozen snapshot from InputActions' former main repository (~v0.9.0) | Maintained [`InputActions/kwin`](https://github.com/InputActions/kwin), stable release v0.9.2.1 | Same as v2.0 | Same as v2.0 |
| Still getting fixes upstream? | **No.** That repository stopped receiving updates | **Yes.** It's where InputActions development happens now | **Yes** | **Yes** |
| 3-finger up opens / down closes the cube | ✅ | ✅ | ✅ | ✅ |
| Automatic rebuilds after KWin updates, notifications | ✅ | ✅ | ✅ | ✅ |
| Cube turned off → swipes go back to KDE | ❌ (swipes stay taken, do nothing) | ❌ (swipes stay taken, do nothing) | ✅ automatically, and back to the cube when it's turned on | ✅ |
| Smooth left/right swiping in the cube, Down arrow | ❌ (KDE's: one desktop per swipe, after the swipe ends) | ❌ | ❌ | ✅ |
| Patches KDE's cube | No | No | No | Yes, a per-user copy, rebuilt automatically after KDE updates |
| Touchpad udev rule | Required | Optional (still installed by default) | Optional (still installed by default) | Optional (still installed by default) |
| Expected lifespan | Until a future KWin update breaks the old code, which will never be fixed | Can follow new InputActions releases | Can follow new InputActions releases | Can follow new InputActions releases |

**Use v4.0.** Earlier versions are kept for reference.

**Upgrading from an earlier version:** in your copy of this project, run `git pull` and then `./install.sh`, then log out and back in once (to load the patched cube). Your gestures keep working the same. If you're coming from v1.0, you can afterwards delete the old download: `rm -rf ~/.local/src/InputActions`. If you have [Cube-Backside-Click](https://github.com/ARM64-Fedora-KDE-QoL/Cube-Backside-Click) v1.0 installed, it's taken over automatically and keeps working (both projects now share one patched cube); updating it to v2.0 is still a good idea.

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
git clone https://github.com/ARM64-Fedora-KDE-QoL/3-Finger-Cube-Gesture.git
cd 3-Finger-Cube-Gesture
./install.sh
```

**Without git:** on this page, click **Code → Download ZIP**, extract it, open a terminal in the extracted folder, and run `bash install.sh`. Use `bash install.sh` rather than `./install.sh` here, because ZIP downloads can lose the "executable" permission.

Run the installer as your normal user, **not** with `sudo` in front. It asks for your password **once** at the start, then installs everything without further questions. The first run downloads the packages and builds InputActions, which takes a few minutes. When it says **Done**, swipe up with three fingers. **Log out and back in once** to activate smooth swiping: KWin loads the cube at login.

If you already use InputActions, back up `~/.config/inputactions/config.yaml` first. The installer replaces it with the cube gestures. It saves the old file as `config.yaml.bak.<date>`, but your other gestures won't be active until you merge them back in.

**Customizing:** `~/.config/inputactions/config.yaml` is managed by this project and gets swapped automatically when the cube is turned on or off (see [Turning off the Desktop Cube](#turning-off-the-desktop-cube-or-the-gestures)). To add or change gestures, edit `~/.local/share/cube-gesture/gestures-on.yaml` instead, then toggle the Cube effect off and on (or re-run `./install.sh`, which rewrites that file back to the default).

## Smooth swiping in the cube

With the cube open, swipe left or right with 3 or 4 fingers and the cube turns **with your fingers**, smoothly and as far as you swipe. KDE's own cube only jumps one desktop after the swipe has ended.

- **Short swipes** turn the cube gently and always take you to the **next desktop** in the swipe's direction when you lift your fingers. Only a tiny accidental twitch stays put.
- **Long swipes** speed up after about a third of a desktop (to 3.5× the short-swipe rate), so one relaxed swipe can go all the way around. Lifting your fingers snaps to the nearest desktop. If you hold your fingers still mid-swipe for half a second, the cube snaps there too, so you can stop and look at a desktop.
- **Changing direction** mid-swipe, even quickly or in a curve, keeps turning the cube: diagonal movement counts too. Everything until you lift your fingers is one swipe.
- **Swiping down** into a desktop: a fresh 3-finger swipe down closes the cube onto the desktop you swiped to right away. A swipe down that grows out of a left/right swipe without lifting your fingers (for example, a long swipe drifting downwards near your palm) has to travel a bit further first, so it doesn't close the cube by accident.
- **Keyboard:** ← / → turn the cube one desktop, **↓** goes into the desktop facing you, Enter / Space do the same, Esc closes the cube.
- The cube snaps with a gentle ease-in, so it blends with your fingers' motion.

Snapping switches to that desktop and keeps the cube open, so you can keep browsing.

**How it works.** InputActions takes over 3- and 4-finger left/right swipes only while the cube is open, and sends the cube a small sideways scroll step for every bit of finger movement, plus a key press when your fingers lift. A small patch to KDE's cube ([`cube-smooth-swipe.patch`](cube-smooth-swipe.patch)) turns the cube by those steps, snaps it, and lets InputActions tell that the cube is open. The patched cube is a per-user copy in `~/.local/share/kwin/effects/cube/`, which KDE automatically prefers over its own; the system files are never changed. It's kept by `kde-cube-patches-sync`, which is shared with [Cube-Backside-Click](https://github.com/ARM64-Fedora-KDE-QoL/Cube-Backside-Click) so both can patch the cube at once, and it's rebuilt automatically when Fedora updates KDE's cube ([details](#how-kwin-and-kde-updates-are-handled)). Without InputActions, the patched cube still follows KDE's own desktop-switching swipe, but only one desktop per swipe.

**Side effects:**
- **KDE Overview.** InputActions tells the cube is open the same way it tells KDE's Overview is open, so while **Overview** (Meta+W, 4-finger swipe up) is open, 3- and 4-finger left/right swipes are taken too and don't switch desktops there.
- **Swipe directions.** Swipes within 25° of straight left/right/up/down count as that direction (InputActions' default is 20°); the rest count as diagonals. That keeps near-vertical drift out of the cube's diagonal swipes, and also means a slightly slanted 3-finger up/down still opens and closes the cube.
- **2-finger scrolling** left/right inside the open cube may turn it too.

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

**Keep these packages installed.** The automatic rebuild after every KWin update uses the build tools and libraries above. If you remove any of them (for example because they look unused), the next KWin update can't rebuild the plugin: the gestures stop working and you get the *"Cube gesture needs a rebuild"* warning at login. Reinstall them with the command above, then re-run `./install.sh`. Removing `git` also stops the patched cube from being rebuilt after KDE updates, so KDE's own cube is used (without smooth swiping) until you reinstall it. `dnf autoremove` won't remove them, because the installer installs them on purpose.

## What it changes on your system

| What | Where | Why |
|---|---|---|
| Build packages | `dnf install` (kwin-devel, cmake, gcc-c++, …) | Needed to build the plugin |
| InputActions source | `~/.local/src/inputactions-kwin` | Downloaded from GitHub |
| Root-owned source copy and build | `/var/lib/cube-gesture/` | Used for automatic rebuilds (see [Security notes](#security-notes)) |
| KWin plugin | `/usr/lib64/qt6/plugins/kwin/effects/plugins/kwin_gestures.so`, `…/configs/inputactions_kwin_kcm.so` | The plugin itself |
| Gesture config | `~/.config/inputactions/config.yaml` | The active InputActions config: the cube gestures, or none while the cube is off |
| Patched cube | `~/.local/share/kwin/effects/cube/` (marked by a `.kde-cube-patches` file) | KDE's cube with the smooth-swiping patch (and Cube-Backside-Click's, if installed) |
| Cube patch and patcher | `~/.local/share/kde-cube-patches/3-finger-cube-gesture.patch`, `~/.local/bin/kde-cube-patches-sync` | Builds the patched cube; shared with Cube-Backside-Click |
| Cube update watcher | `~/.config/systemd/user/kde-cube-patches.path`, `kde-cube-patches-update.service`, `kde-cube-patches-login.service` | Rebuilds the patched cube after KDE updates; checks at login |
| Stored gesture configs | `~/.local/share/cube-gesture/gestures-on.yaml`, `gestures-off.yaml` | The two versions the watcher switches between |
| Cube on/off watcher | `~/.local/bin/cube-gesture-sync`, `~/.config/systemd/user/cube-gesture-sync.path` + `.service` | Switches the gestures when the Cube effect is turned on or off |
| Touchpad udev rule | `/etc/udev/rules.d/70-touchpad-uaccess.rules` | Optional; enables InputActions' extra touchpad features (see below) |
| Rebuild helper | `/usr/local/sbin/cube-gesture-rebuild`, `/etc/cube-gesture.conf` | Rebuilds the plugin for a new KWin |
| dnf hook | `/etc/dnf/libdnf5-plugins/actions.d/cube-gesture.actions` (+ the `libdnf5-plugin-actions` package) | Runs the helper after a kwin update |
| Boot check | `cube-gesture-rebuild.service` (systemd) | Backstop if the hook didn't run |
| Login check | `~/.local/bin/cube-gesture-check`, `~/.config/autostart/cube-gesture-check.desktop` | Notifies you about rebuilds or failures |
| Rebuild log | `/var/log/cube-gesture-rebuild.log` | Output of every rebuild |

## Disk space and memory

Measured on the test laptop (Fedora 44 Asahi, KDE Plasma 6.7.5).

**Disk space: about 35 MB**, plus the build packages.

| What | Size |
|---|---|
| Root-owned source copy and build, kept for automatic rebuilds (`/var/lib/cube-gesture/`) | 27 MB |
| InputActions source (`~/.local/src/inputactions-kwin`) | 3 MB |
| The KWin plugin | 3 MB |
| Patched cube, patches, configs, scripts, systemd units, rebuild log | under 1 MB |
| [Build packages](#packages-it-needs) from Fedora | about 115 MB for the listed packages, more with the packages they pull in (some may already be installed) |

**Memory: about 5–10 MB.** Nothing runs as its own program:

- **The gesture plugin** runs inside KWin and adds a few MB to KWin's memory.
- **The patched cube** uses the same memory as KDE's own cube while it's open, and nothing while it's closed.
- **The watchers** (`.path` units) are file-change notifications handled by systemd. The update and login services start only after an update or at login, and exit within seconds.
- **A rebuild after a KWin update** briefly uses a few hundred MB for about a minute, then frees it.

## How KWin and KDE updates are handled

**KDE's cube (smooth swiping).** A user-level watcher notices when Fedora updates KDE's cube files (package `kdeplasma-addons`) and rebuilds the patched copy from KDE's new cube, so you keep KDE's own fixes. You get a *"Desktop Cube patches updated"* notification; log out and back in to use it. A check at every login is the backstop. If a future KDE version changes the cube so the patch no longer fits, smooth swiping is turned off with one notification and **KDE's own cube is used**: nothing breaks, the left/right swipes go back to KDE, and 3-finger up/down keep working. Updating this project brings it back once a fixed patch is released.

**The InputActions plugin.** InputActions is compiled against KWin's internal code, so it has to be rebuilt for each new KWin version. The installer sets that up so it happens automatically:

1. **After an update through `dnf` or Discover**, a dnf hook rebuilds the plugin (about 40 seconds) and shows a *"Cube gesture plugin rebuilt"* notification. Log out and back in to start using the new KWin.
2. **Offline updates** (Discover's default) are applied during a reboot, before anyone logs in. A boot service rebuilds the plugin before the login screen appears, and you get the notification after you log in.
3. **If a rebuild fails**, you get a *"Cube gesture needs a rebuild"* warning at every login until it's fixed. Re-run `./install.sh`, and check `/var/log/cube-gesture-rebuild.log` for details.

Automatic rebuilds reuse the InputActions version you already have. Re-running `./install.sh` rebuilds the same pinned version; moving to a newer InputActions release means changing `INPUTACTIONS_COMMIT` near the top of `install.sh` and re-testing the gestures.

## Security notes

**The touchpad udev rule (optional).** The cube gestures work without it, because KWin tells InputActions how many fingers are on the touchpad. The rule additionally lets InputActions read the touchpad device (`/dev/input/event*`) directly, which enables its extra touchpad features (thumb and palm detection, finger positions, pressure). The installer adds it because the [InputActions wiki](https://wiki.inputactions.org/main/getting-started/installation/kwin.html) recommends it as optional setup. On Fedora only root and the `input` group can open the device, and KWin runs as you, so the rule is what grants that access. It is:

```
SUBSYSTEM=="input", KERNEL=="event*", ENV{ID_INPUT_TOUCHPAD}=="1", TAG+="uaccess"
```

It gives the user logged in at the machine access to **touchpads only**, the same way Fedora already grants access to sound cards and webcams. The trade-off: any program running as you could read raw finger positions from the touchpad. Keystrokes aren't exposed, because keyboards are separate devices that the rule doesn't match. Adding yourself to the `input` group would also work, but it would expose the keyboard too, so this project avoids it.

If you'd rather not grant this access, remove the rule after installing; the cube gestures keep working:

```bash
sudo rm /etc/udev/rules.d/70-touchpad-uaccess.rules && sudo udevadm control --reload && sudo udevadm trigger --subsystem-match=input --action=change
```

Re-running `./install.sh` puts it back.

**Automatic rebuilds run as root.** They build only from a root-owned copy of the source (`/var/lib/cube-gesture/src`). That copy is refreshed only when you run `./install.sh` yourself, so nothing you or your programs can edit is ever built or run as root without your password. New plugin files are swapped in with an atomic rename, so the running KWin isn't disturbed.

## Uninstall

```bash
./uninstall.sh            # removes everything; keeps your config (renamed) and the downloaded source
./uninstall.sh --purge    # also deletes the config and ~/.local/src/inputactions-kwin
```

It removes the plugin, the udev rule, the rebuild helper, the dnf hook, the boot service, the login check, the Cube on/off watcher and the smooth-swiping cube patch. If Cube-Backside-Click is installed, the patched cube is rebuilt with just its patch; otherwise the patched cube and its watcher are removed and KDE's own cube is used. The build packages installed with dnf are left in place. Log out and back in afterwards.

## Troubleshooting

- **Nothing happens when I swipe.** Check for config errors:
  `qdbus-qt6 org.inputactions / org.inputactions.issues`
  Make sure the Cube effect is turned on: while it's off, the gestures are switched off on purpose (see below). Then check that InputActions sees your touchpad: `qdbus-qt6 org.inputactions / org.inputactions.deviceList` should list it as `[Touchpad]`. (`multiTouch: false` there is fine; it only means the optional udev rule isn't active.) If the effect isn't loaded at all, re-run `./install.sh`, then log out and back in.
- **The cube doesn't open even though the gesture fires.** Make sure the Desktop Cube effect is enabled (System Settings → Window Management → Desktop Effects → **Cube**, listed under *Window Management*) and that its keyboard shortcut opens it (Meta+C by default). You can also test the action the gesture uses directly:
  `qdbus-qt6 org.kde.kglobalaccel /component/kwin org.kde.kglobalaccel.Component.invokeShortcut Cube`
- **I got a "needs a rebuild" notification.** Re-run `./install.sh` and check `/var/log/cube-gesture-rebuild.log`.
- **Left/right swipes in the cube still jump one desktop.** Log out and back in first (KWin loads the cube at login). Then check that the patched cube has smooth swiping: `grep applied ~/.local/share/kwin/effects/cube/.kde-cube-patches` should list `3-finger-cube-gesture`. If it doesn't, run `~/.local/bin/kde-cube-patches-sync` and read its message: it says if the patch doesn't fit your KDE version, or if another cube override is in the way. To check that InputActions sees the cube as open, run `sleep 8; qdbus-qt6 org.inputactions / org.inputactions.variables plasma_overview_active`, open the cube within 5 seconds and wait: it should print `true`.
- **Turning off just smooth swiping** (KDE's own left/right swipes in the cube; 3-finger up/down keep working): `mkdir -p ~/.config/3-finger-cube-gesture && touch ~/.config/3-finger-cube-gesture/disabled && ~/.local/bin/kde-cube-patches-sync`, then log out and back in. To turn it on again: `rm ~/.config/3-finger-cube-gesture/disabled && ~/.local/bin/kde-cube-patches-sync`, then log out and back in.
- **The cube doesn't open at all after a KDE update.** Run `./uninstall.sh` (or delete `~/.local/share/kwin/effects/cube/`), log out and back in, and please report it.

### Turning off the Desktop Cube (or the gestures)

**What happens if you turn off the cube after installing:** the cube's swipes go **back to KDE** automatically. A small watcher notices when the Cube effect is turned off in System Settings and switches the gestures off within a second or two. Turn the cube back on and the swipes open and close it again, also automatically. There's nothing to re-run and no need to log out.

Details:

- **What's affected.** While the cube is on, this project takes 3-finger up/down always, and 3-/4-finger left/right only while the cube is open. Everything else (and, with the cube off, every swipe) is left to KDE.
- **Not yet confirmed by a hands-on test.** Switching the gestures off and on was tested and works: the watcher swaps the config within a second or two of ticking or unticking Cube. What hasn't been seen in action is a 3-finger up/down swipe actually *doing something* in KDE while the cube is off, because there was nothing to test it with: KDE has no built-in action for 3-finger up/down and no setting to bind one. It should work exactly as intended, though: with the cube off, the active InputActions config contains no gestures at all (`gestures: []`), so nothing intercepts those swipes and they reach KDE the same way 3-finger left/right always do. KDE then passes them on as usual: to a built-in KDE gesture or one you've bound yourself, if a future Plasma version offers either for 3-finger up/down, or otherwise to the app under your fingers. While the cube is on, the cube gestures take those swipes instead.
- **Gesture tools that read the touchpad directly** (such as `libinput-gestures` or Fusuma) work outside KDE and aren't affected by this project either way: they see every swipe, *even while the cube is on*, so a 3-finger up/down binding in one of them would fire together with the cube. If you use one, remove its 3-finger up/down bindings.
- **Nothing breaks either way.** If the cube is off but the gestures were somehow still active, KDE would just quietly ignore them: no error, no popup.
- **Automatic rebuilds keep running** after KWin updates while the cube is off. That's harmless, just about 40 seconds of unneeded work per KWin update, and it means the gestures are ready the moment you turn the cube back on.
- **Re-running `./install.sh` turns the cube back on.** The installer makes sure the cube is enabled. The automatic rebuilds and the watcher don't do this; only re-running the installer does.

Both effects are switched in the same place. Open **System Settings → Window Management → Desktop Effects** (or search System Settings for *Desktop Effects*), then:

| Goal | What to do |
|---|---|
| Turn off the cube (3-finger up/down go back to KDE) | Untick **Cube** (under *Window Management*), click **Apply**. Tick it again and click **Apply**, and the cube gestures come back. |
| Turn off all InputActions gestures, cube on or off | Untick **InputActions** (under *Tools*), click **Apply**. Ticking it again restores them. |
| Remove everything | Run `./uninstall.sh` from this project's folder. |

From a terminal, the same switches are:

```bash
# Cube off / on (the gestures follow automatically)
kwriteconfig6 --file kwinrc --group Plugins --key cubeEnabled false && qdbus-qt6 org.kde.KWin /Effects org.kde.kwin.Effects.unloadEffect cube
kwriteconfig6 --file kwinrc --group Plugins --key cubeEnabled true  && qdbus-qt6 org.kde.KWin /Effects org.kde.kwin.Effects.loadEffect cube

# InputActions off / on
kwriteconfig6 --file kwinrc --group Plugins --key kwin_gesturesEnabled false && qdbus-qt6 org.kde.KWin /Effects org.kde.kwin.Effects.unloadEffect kwin_gestures
kwriteconfig6 --file kwinrc --group Plugins --key kwin_gesturesEnabled true  && qdbus-qt6 org.kde.KWin /Effects org.kde.kwin.Effects.loadEffect kwin_gestures
```

To check which state the gestures are in: `systemctl --user status cube-gesture-sync.path` should say **active (waiting)**, and `~/.config/inputactions/config.yaml` contains either the cube gestures or `gestures: []` (cube off).

## License

Copyright (C) 2026 Cynders. Licensed under the [GNU General Public License v3.0 or later](LICENSE): you can use, modify and share this project, and any modified versions you distribute must stay open source under the same license. It comes with no warranty.

## Credits

- [InputActions](https://github.com/InputActions/kwin) by its developers (GPL-3.0), which does all the gesture work. This project only builds, configures and maintains it.
- KDE Plasma's Desktop Cube effect by Vlad Zahorodnii (GPL-2.0-only OR GPL-3.0-only). `cube-smooth-swipe.patch` modifies two of its files; the patched copy is generated on your machine from your installed KDE cube.
