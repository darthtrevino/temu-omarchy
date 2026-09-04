# Temu Omarchy

A Fedora Asahi Remix / Hyprland desktop configuration inspired by the parts of
Omarchy used on this machine.

## Included

- Hyprland Lua configuration and Omarchy-style keybindings
- Top-half dropdown workspace with terminal and cliamp
- Automatic PipeWire recovery when the Asahi speaker sink is unavailable
- Quickshell bar with workspaces, tray, calendar, Wi-Fi, Bluetooth, weather,
  Orthodox fasting guidance and daily details, volume, battery, and media
  controls
- Themed hyprlock and battery-aware hypridle policy
- btop activity monitor and matching theme
- Screenshot workflow using grim, slurp, and wl-copy
- Network audio outputs start muted at 5% and are unmuted only when selected
- JetBrainsMono Nerd Font installer and desktop font defaults
- Breeze Dark defaults across KDE/Qt, GTK, and Flatpak applications
- Zen Browser installed from Flathub with borderless content
- Rofi, kitty, fontconfig, and helper scripts

## Install

This setup targets Fedora 44 with Hyprland's Lua config provider.

```bash
./scripts/setup-fedora.sh --weather-location SEA
```

Use your own ZIP or airport code. The location is inserted only into
`~/.config/quickshell/shell.qml`; the repository template remains sanitized.

The setup script:

1. Installs Fedora packages through `sudo dnf`.
2. Adds Flathub for the current user, installs Zen Browser, and makes it the
   default web browser.
3. Downloads JetBrainsMono Nerd Font v3.5.1 and cliamp v2.0.1 from their
   official releases and verifies pinned SHA-256 checksums.
4. Backs up replaced or mutated configuration files under
   `~/.local/state/temu-omarchy/backups/<timestamp>`.
5. Symlinks static configurations and helper scripts from this repository.
6. Generates the local Quickshell config with the requested weather location.
7. Applies dark KDE/Qt and GTK themes plus fontconfig, kitty, rofi, and
   hyprlock font defaults.
8. Enables the `hypridle` user service and reloads the active desktop.
9. Starts KDE Wallet's PAM bridge with Hyprland so the login password can
   unlock the default wallet automatically.

Keep the repository at a stable path because most installed files are symlinks
back to it.

## Manual or consent-required steps

- **Quickshell repository:** Fedora may require a third-party Hyprland COPR.
  The setup script will stop instead of enabling a third-party repository
  without explicit review and consent.
- **Sudo authentication:** enter the password directly into `sudo`; no
  credentials are read or stored by these scripts.
- **cliamp providers:** run `cliamp setup` for any remote music provider after
  installation. Provider credentials remain in cliamp's local configuration
  and must not be added to this repository.
- **Wi-Fi credentials:** known/open networks can connect from the bar. Use the
  bar's **Manage** action (`nmtui`) for a new protected network. Passwords are
  managed by NetworkManager and never written here.
- **Bluetooth pairing:** use the Bluetooth **Manage** action for first-time
  pairing. The bar handles reconnecting already-paired devices.
- **Multiple monitors:** the dropdown workspace uses a bottom gap of `540`,
  matching a 2160-pixel panel at 2x scale. Adjust
  `config/hypr/hyprland.lua` for displays with a different logical height.
- **Font refresh:** existing applications may need to be restarted; a full
  logout/login refreshes every toolkit.
- **Lock screen:** test manual locking from `Super+Escape` before relying on
  automatic idle locking.
- **KDE Wallet:** set the `kdewallet` password to the same password used at
  login. Open `kwalletmanager5`, select `kdewallet`, and use **Change
  Password**. After the next logout/login, applications such as Copilot can
  read their saved credentials without a separate wallet prompt. Passwordless
  or automatic login cannot provide a password to unlock an encrypted wallet.

## Key shortcuts

| Shortcut | Action |
|---|---|
| `Super+Space` | Application launcher |
| `Super+Enter` | Terminal |
| `Super+Shift+Enter` | Zen Browser |
| `Super+\`` | Toggle dropdown workspace |
| `Super+Shift+\`` | Move focused window to dropdown |
| `Super+Ctrl+L` | Lock immediately |
| `Super+Ctrl+T` | btop activity monitor |
| `Super+L` | Toggle dwindle/scrolling layout |
| `Super+O` | Pop and pin the active window |
| `Super+Ctrl+F` | Toggle tiled fullscreen |
| `Super+,` | Dismiss the latest notification |
| `Super+Shift+,` | Dismiss all notifications |
| `Super+Alt+,` | Invoke the latest notification action |
| `Super+Ctrl+Z` | Increase compositor zoom |
| `Super+Ctrl+Alt+Z` | Reset compositor zoom |
| `Shift+Volume Mute` | Select an audio output |
| `Super+Shift+Space` | Toggle top bar |
| `Print` | Screenshot focused monitor |
| `Shift+Print` | Screenshot region |
| `Super+Print` | Screenshot active window |
| `Super+K` | Keybinding reference |
| `Super+Escape` | System menu |

## Secret policy

Do not commit secret keys, tokens, passwords, Wi-Fi credentials, private keys,
or personal weather locations.

`.gitignore` blocks common credential filenames. The repository also includes a
pre-commit hook that rejects high-confidence private-key and token patterns.
Install it by running the setup script, or manually:

```bash
ln -sfn "$PWD/hooks/pre-commit" .git/hooks/pre-commit
chmod +x hooks/pre-commit scripts/check-no-secrets.sh
```

Run a full working-tree scan at any time:

```bash
./scripts/check-no-secrets.sh
```

The scanner is defense in depth, not a substitute for reviewing changes before
committing.
