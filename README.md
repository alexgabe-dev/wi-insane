# WI-INSANE — Auto‑Invite Helper for Turtle WoW

A lightweight, polished auto-invite addon for Turtle WoW that listens for configured keywords in whispers and automatically invites eligible players.

<img width="422" height="392" alt="wi-insane" src="https://github.com/user-attachments/assets/af5327a0-9c3b-4b1e-b991-cd9f8311b2a8" />


- Original code by Mazli
- Modernised and maintained by Stabastian
- Version: 1.2 (tested on Turtle WoW 1.18.0)

---

## Features
- Auto‑invite on exact, case‑insensitive keyword match
- Clean configuration GUI (`/wi`) with dialog styling
- Clickable keywords list with quick select → remove
- Minimap button with classic circular frame, draggable around the minimap
- Info popup with authorship and helpful tips
- Colorized help output (`/wi help`)
- Optional debug logging for troubleshooting

---

## Installation
1. Download or clone into your WoW addons folder:
   - `Interface\\AddOns\\WI/`
2. Ensure the addon contains:
   - `WI.toc`
   - `WI.lua`
   - `Icon/wi-icon.tga` (32×32 TGA with alpha)
3. Launch the game (or `/reload`).

If you see the minimap icon and `/wi` opens the config, installation succeeded.

---

## Usage
Open the config: `/wi` or `/wi gui`

- Add a keyword: type it in the field and click `Add`.
- Remove a keyword: click the keyword in the list (it will highlight and populate the input), then click `Remove`.
- Enable/disable: toggle the checkbox or use `/wi on`, `/wi off`, or `/wi toggle`.

### Commands
| Command | Description |
|---|---|
| `/wi gui` | Open the configuration window |
| `/wi on` / `/wi off` / `/wi toggle` | Enable, disable, or toggle auto‑invite |
| `/wi add <keyword>` | Add a keyword |
| `/wi remove <keyword>` | Remove a keyword |
| `/wi list` | Print all keywords to chat |
| `/wi map` | Show/hide the minimap icon |
| `/wi debug` | Toggle debug logging |
| `/wi help` | Show colorized help in chat |

---

## Minimap Icon
- Left‑click: open the `/wi` GUI.
- Right‑click: toggle auto‑invite.
- Drag with left mouse to reposition around the minimap.
- The icon uses your custom `Icon/wi-icon.tga` and a classic circular border.

---

## Configuration Notes
- Matching is exact (after lowercase normalization). For example, keyword `eg` matches whisper `eg` but not `egg`.
- Add multiple short keywords to support common variations.
- The GUI uses WoW 1.12 conventions (`this`, `arg1`) for compatibility with Turtle WoW.

---

## Troubleshooting
- No invites happen:
  - Ensure auto‑invite is enabled in the GUI or via `/wi on`.
  - Whisper an exact keyword; check `/wi list` for the current set.
  - Turn on debug with `/wi debug` and watch chat for match logs.
- Minimap icon missing:
  - Run `/wi map` to toggle visibility.
  - Confirm `Icon/wi-icon.tga` exists and is 32×32 TGA with alpha.
- GUI overlap or sizing:
  - The window can be resized in code; current defaults are tuned for Turtle WoW’s UI scale.

---

## Credits
- Authors: Mazli (original), Stabastian (remix)
- Guild: `<INSASE>`

Thanks for using our <INSANE> addon and keeping invites simple!
