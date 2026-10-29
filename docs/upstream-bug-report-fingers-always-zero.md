# `fingers` is always 0 for touchpad gestures when the evdev device can't be opened, so `fingers:` triggers never match

<!-- File at: https://github.com/InputActions/core/issues
     (or https://github.com/InputActions/kwin/issues if they prefer KWin-specific reports there).
     The heading above is the issue title; everything below is the body. -->

**Description**

When the KWin plugin can't open the touchpad's `/dev/input/eventN` node (the default on Fedora: `root:input 0660`, and KWin runs as the user), every touchpad swipe reports `fingers = 0`. Any trigger with `fingers:` set never activates, and nothing tells the user why: `org.inputactions.issues()` is empty, and the journal shows nothing at the default log level.

KWin passes the correct finger count in the gesture event, but it gets thrown away.

**Cause (as far as I can tell)**

- `TouchpadTriggerHandler::touchpadGestureLifecyclePhase()` calls `g_variableRegistry->variable(BuiltinVariables::Fingers)->setValue(event.fingers())` on `Begin`.
- `Fingers` is registered with `registerComputed` in `InputActionsMain.cpp`, so it's a `ComputedVariable`. `Variable::setValue()` is a no-op by default (`variables/Variable.h:41`), so the libinput finger count is discarded.
- The computed getter returns `currentMultiTouchDevice()->savedPhysicalState().validTouchPoints().size()`. With no evdev access there are no touch points, so it's always 0.
- `LibevdevComplementaryInputBackend::addDevice()` catches the `libevdev::Exception` from the failed `open()` and returns silently. The only trace is a `qCDebug` message in `libevdev-cpp`.
- Setting `__libevdev_enabled: false` doesn't help, because `Fingers` is still computed from touch points.

**Steps to reproduce**

1. Use a system where the user isn't in the `input` group and touchpad nodes have no `uaccess` ACL (default Fedora).
2. Use this config:
   ```yaml
   touchpad:
     gestures:
       - type: swipe
         fingers: 3
         direction: up
         actions:
           - on: begin
             command: notify-send matched
   ```
3. Do a 3-finger swipe up. Nothing happens.
4. Change `fingers: 3` to `fingers: 0`. Now it matches on every swipe.

`org.inputactions.deviceList()` shows `multiTouch: false` for the touchpad, and `org.inputactions.variables()` shows `fingers: 0`.

**Workaround**

A udev rule that gives the session user access to touchpad nodes:

```
SUBSYSTEM=="input", KERNEL=="event*", ENV{ID_INPUT_TOUCHPAD}=="1", TAG+="uaccess"
```

After reloading the effect, `multiTouch` becomes `true` and `fingers: 3` matches.

**Suggested fix (either or both)**

1. When there are no evdev touch points for the current device, fall back to the libinput finger count from the gesture event for `Fingers`, for example by storing it and having the computed getter use it when `validTouchPoints()` is empty.
2. Report a config/runtime issue (visible through `issues()`, or at least a warning in the log) when the evdev device for a touchpad can't be opened, and mention the `input` group / `uaccess` requirement in the installation docs.

**Environment**

- Fedora Asahi Remix 44 (aarch64), kernel 7.1.13-402.asahi.fc44.aarch64, Apple MacBook touchpad (`Apple MTP multi-touch`)
- KDE Plasma / KWin 6.7.5, Wayland
- InputActions built from source: main `e3dfb18`, kwin `924cb6f`, core `d454abb`
