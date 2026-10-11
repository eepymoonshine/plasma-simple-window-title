# Simple Window Title

A KDE Plasma 6 panel widget that shows the active window's icon and title, with a card-style popup in the same look as [System Usage](https://github.com/eepymoonshine/plasma-system-usage), [Simple Weather](https://github.com/eepymoonshine/plasma-simple-weather) and [Simple Clock](https://github.com/eepymoonshine/plasma-simple-clock).

## Features

- **Panel:** the active window's icon and text built from a pattern (`%a` app name, `%w` window title, `%q` current activity), with separate patterns for when the app and title match and for when no window is active. Optional maximum width, cut with `…`.
- **Mouse:** click opens the popup, double-click maximizes or restores, middle-click closes, scroll switches windows. Each can be turned off.
- **Popup:** the current window with its state (maximized, minimized, on top, all desktops) and buttons to minimize, maximize, keep above, show on all desktops or close it; a list of the windows on this desktop to switch to (middle-click or the × closes one); and a button for KWin's Overview.
- **Settings:** text patterns, icon and its size, maximum width, the panel's font, size, weight and italic, and filters for maximized windows or the panel's screen.

## Install

```sh
kpackagetool6 -t Plasma/Applet -i package
```

Update after making changes:

```sh
kpackagetool6 -t Plasma/Applet -u package
plasmashell --replace &
```

Then right-click the panel → **Add Widgets** → search for **Simple Window Title**.

## Requirements

- Plasma 6 (KWin)

## Credits

Inspired by [Window Title Applet](https://github.com/Idesmi/plasma6-window-title-applet).

## License

GPL-3.0-or-later.
