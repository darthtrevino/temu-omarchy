# Roadmap

Temu Omarchy focuses on the Omarchy desktop features that are useful on this
Fedora Asahi Remix system. The roadmap favors reliable daily workflows over
replicating Omarchy's Arch-specific distribution tooling.

## Status

- [x] Complete
- [ ] Planned

## Current baseline

- [x] Hyprland tiling, scrolling layouts, groups, scratchpad, and navigation
- [x] Quickshell bar with workspaces, tray, calendar, weather, connectivity,
      audio, battery, and media controls
- [x] Application, system, audio-output, and keybinding menus
- [x] Locking, idle policy, screenshots, and notification actions
- [x] Random-shuffle wallpaper rotation
- [x] Searchable emoji picker
- [x] Local voice dictation
- [x] KDE/Qt, GTK, Kitty, Rofi, btop, and font configuration
- [x] Asahi and network-audio safeguards

## Priority 1: Daily workflow

### Clipboard history

- [ ] Add universal `Super+C`, `Super+X`, and `Super+V` shortcuts that select
      the correct clipboard chord for terminals and graphical applications
- [ ] Add searchable clipboard history on `Super+Ctrl+V`
- [ ] Support both text and image entries
- [ ] Exclude clipboard content marked as sensitive

### Wallpaper controls

- [ ] Add a command and shortcut to advance to the next wallpaper immediately
- [ ] Add a visual wallpaper picker
- [ ] Preserve random-shuffle rotation and avoid immediately repeating images

## Priority 2: Capture and desktop controls

### Capture tools

- [ ] Add screen recording with region and audio-source selection
- [ ] Add OCR region capture with the extracted text copied to the clipboard
- [ ] Add a color picker that copies the selected color
- [ ] Add QR-code decoding from a selected region
- [ ] Add a screenshot annotation workflow

### Notifications

- [ ] Add a persistent notification history
- [ ] Add Do Not Disturb mode with a visible bar indicator
- [ ] Allow replaying the latest notification action
- [ ] Preserve critical notifications while Do Not Disturb is enabled

### Power and idle controls

- [ ] Add a stay-awake toggle
- [ ] Add night-light controls
- [ ] Add power-profile selection with separate AC and battery preferences
- [ ] Show active modes in the top bar

## Priority 3: Hardware and visual polish

### Display management

- [ ] Add monitor scaling presets
- [ ] Add coordinated text-size controls for the shell, terminal, GTK, and Qt
- [ ] Add external-monitor brightness support through DDC/CI
- [ ] Add internal-display and mirroring toggles
- [ ] Add workspace movement between monitors

### Unified theming

- [ ] Define a shared color-palette format
- [ ] Apply themes consistently to Hyprland, Quickshell, Kitty, Rofi, btop,
      GTK, Qt, and wallpapers
- [ ] Add live theme and background switchers
- [ ] Support machine-local theme overrides without modifying repository files

## Priority 4: Additional integrations

### Reminders

- [ ] Add quick countdown reminders
- [ ] Show pending reminders in the top bar
- [ ] Add list and clear actions

### Sharing

- [ ] Add LocalSend integration
- [ ] Add a share menu for files, URLs, and clipboard content
- [ ] Consider Tailscale file transfer when Tailscale is installed

### Input methods

- [ ] Add XCompose sequences for common symbols and quick emoji
- [ ] Add optional fcitx5 setup for multilingual input
- [ ] Add a keyboard-layout indicator when multiple layouts are configured

## Smaller parity items

- [ ] Save and restore preferred window widths
- [ ] Add per-application audio mixing
- [ ] Add microphone volume and mute controls
- [ ] Add touchpad and touchscreen toggles
- [ ] Add network DNS selection and Wi-Fi QR sharing
- [ ] Add media transcoding helpers

## Non-goals

The following upstream Omarchy features are intentionally out of scope unless
this project's goals change:

- Arch Linux package management, AUR integration, and pacman hooks
- Btrfs snapshots, Limine rollback, and factory reset
- Omarchy's ISO installer and hardware-specific installer matrix
- Plymouth and SDDM theme management
- A bundled gaming or web-application catalogue
- Windows virtual-machine provisioning
- A complete port of Omarchy's shell plugin marketplace
