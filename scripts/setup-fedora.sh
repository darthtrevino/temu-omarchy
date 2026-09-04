#!/usr/bin/env bash

set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
weather_location=""

usage() {
    cat <<'EOF'
Usage: ./scripts/setup-fedora.sh --weather-location LOCATION

LOCATION is kept only in the generated local Quickshell config. It is never
written back to this repository.
EOF
}

while (($# > 0)); do
    case "$1" in
        --weather-location)
            weather_location=${2:-}
            shift 2
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            printf 'Unknown argument: %s\n' "$1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

if [[ -z "$weather_location" ]]; then
    printf 'A weather location is required. Use a ZIP or airport code.\n' >&2
    exit 2
fi

if [[ "$weather_location" == *$'\n'* || "$weather_location" == *$'\r'* ]]; then
    printf 'Weather location must be a single line.\n' >&2
    exit 2
fi

if [[ -d "$root/.git" ]]; then
    chmod +x "$root/hooks/pre-commit" "$root/scripts/check-no-secrets.sh"
    ln -sfn "$root/hooks/pre-commit" "$root/.git/hooks/pre-commit"
fi

if [[ -z "$(dnf repoquery --qf '%{name}' quickshell 2>/dev/null | head -n 1)" ]]; then
    cat >&2 <<'EOF'
The quickshell package is unavailable from enabled repositories.
Review and enable the Fedora COPR used for your Hyprland packages, then rerun
this script. Repository enablement is intentionally not automated.
EOF
    exit 1
fi

packages=(
    bluez
    brightnessctl
    btop
    curl
    dolphin
    flatpak
    fontconfig
    glib2
    grim
    hypridle
    hyprland
    hyprlock
    hyprpolkitagent
    jq
    kf6-kconfig
    kitty
    libnotify
    mako
    NetworkManager-tui
    NetworkManager-wifi
    pam-kwallet
    playerctl
    python3
    quickshell
    rofi
    slurp
    unzip
    upower
    vim-enhanced
    wireplumber
    wl-clipboard
    xdg-utils
)

sudo dnf install -y "${packages[@]}"
flatpak remote-add \
    --user \
    --if-not-exists \
    flathub \
    https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install --user -y flathub app.zen_browser.zen
zen_desktop='app.zen_browser.zen.desktop'
xdg-settings set default-web-browser "$zen_desktop"
for mime_type in \
    text/html \
    x-scheme-handler/http \
    x-scheme-handler/https
do
    xdg-mime default "$zen_desktop" "$mime_type"
done
"$root/scripts/install-nerd-font.sh"
"$root/scripts/install-cliamp.sh"

hyprland_version=$(rpm -q --qf '%{VERSION}' hyprland)
oldest_version=$(
    printf '%s\n%s\n' "0.56.0" "$hyprland_version" \
        | sort -V \
        | head -n 1
)
if [[ "$oldest_version" != "0.56.0" ]]; then
    printf 'Hyprland 0.56.0 or newer is required for this Lua config.\n' >&2
    exit 1
fi

timestamp=$(date +'%Y%m%d-%H%M%S')
backup_root="$HOME/.local/state/temu-omarchy/backups/$timestamp"

backup_target() {
    local target=$1
    local relative=${target#"$HOME/"}

    if [[ -e "$target" || -L "$target" ]]; then
        mkdir -p "$backup_root/$(dirname "$relative")"
        mv "$target" "$backup_root/$relative"
    fi
}

snapshot_target() {
    local target=$1
    local relative=${target#"$HOME/"}

    if [[ -e "$target" || -L "$target" ]]; then
        mkdir -p "$backup_root/$(dirname "$relative")"
        cp -a "$target" "$backup_root/$relative"
    fi
}

link_config() {
    local source=$1
    local target=$2

    mkdir -p "$(dirname "$target")"
    if [[ -L "$target" && "$(readlink -f "$target")" == "$(readlink -f "$source")" ]]; then
        return
    fi

    backup_target "$target"
    ln -s "$source" "$target"
}

copy_config() {
    local source=$1
    local target=$2

    mkdir -p "$(dirname "$target")"
    backup_target "$target"
    install -m 0644 "$source" "$target"
}

backup_target "$HOME/.config/hypr/hyprland.conf"
link_config "$root/config/hypr/hyprland.lua" "$HOME/.config/hypr/hyprland.lua"
link_config "$root/config/hypr/hyprlock.conf" "$HOME/.config/hypr/hyprlock.conf"
link_config "$root/config/hypr/hypridle.conf" "$HOME/.config/hypr/hypridle.conf"
copy_config "$root/config/btop/btop.conf" "$HOME/.config/btop/btop.conf"
link_config "$root/config/btop/themes/current.theme" "$HOME/.config/btop/themes/current.theme"
link_config "$root/config/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
link_config "$root/config/rofi/config.rasi" "$HOME/.config/rofi/config.rasi"
link_config "$root/config/fontconfig/fonts.conf" "$HOME/.config/fontconfig/fonts.conf"

for helper in "$root"/bin/*; do
    chmod +x "$helper"
    link_config "$helper" "$HOME/.local/bin/$(basename "$helper")"
done

quickshell_target="$HOME/.config/quickshell/shell.qml"
mkdir -p "$(dirname "$quickshell_target")"
quickshell_temporary=$(mktemp "$quickshell_target.tmp.XXXXXX")
if ! python3 - "$root/config/quickshell/shell.qml.in" \
    "$quickshell_temporary" "$weather_location" <<'PY'
import json
import pathlib
import sys
import urllib.parse

source, target, location = sys.argv[1:]
text = pathlib.Path(source).read_text()
label = json.dumps(location)[1:-1]
query = urllib.parse.quote(location, safe="")
text = text.replace("__WEATHER_LABEL__", label)
text = text.replace("__WEATHER_QUERY__", query)
pathlib.Path(target).write_text(text)
PY
then
    rm -f "$quickshell_temporary"
    exit 1
fi
backup_target "$quickshell_target"
mv "$quickshell_temporary" "$quickshell_target"

font_value='JetBrainsMono Nerd Font,10,-1,5,50,0,0,0,0,0'
small_font_value='JetBrainsMono Nerd Font,8,-1,5,50,0,0,0,0,0'
snapshot_target "$HOME/.config/kdeglobals"
snapshot_target "$HOME/.config/gtk-3.0/settings.ini"
snapshot_target "$HOME/.config/gtk-4.0/settings.ini"
mkdir -p "$backup_root/dconf"
gsettings get org.gnome.desktop.interface font-name \
    >"$backup_root/dconf/font-name.txt" 2>/dev/null || true
gsettings get org.gnome.desktop.interface monospace-font-name \
    >"$backup_root/dconf/monospace-font-name.txt" 2>/dev/null || true
for key in font fixed menuFont toolBarFont activeFont; do
    kwriteconfig6 --file kdeglobals --group General --key "$key" "$font_value"
done
kwriteconfig6 --file kdeglobals --group General \
    --key smallestReadableFont "$small_font_value"
kwriteconfig6 --file "$HOME/.config/gtk-3.0/settings.ini" \
    --group Settings --key gtk-font-name 'JetBrainsMono Nerd Font, 10'
kwriteconfig6 --file "$HOME/.config/gtk-4.0/settings.ini" \
    --group Settings --key gtk-font-name 'JetBrainsMono Nerd Font, 10'
gsettings set org.gnome.desktop.interface font-name 'JetBrainsMono Nerd Font 10'
gsettings set org.gnome.desktop.interface monospace-font-name \
    'JetBrainsMono Nerd Font 10'
fc-cache -f >/dev/null

systemctl --user enable --now hypridle.service

if hyprctl version >/dev/null 2>&1; then
    hyprctl reload >/dev/null
    qs kill >/dev/null 2>&1 || true
    hyprctl dispatch 'hl.dsp.exec_cmd("qs --no-duplicate")' >/dev/null || true
fi

printf 'Setup complete.\n'
printf 'Backups, when needed, were stored in %s\n' "$backup_root"
printf 'Log out and back in to refresh fonts in every application.\n'
