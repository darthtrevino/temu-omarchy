#!/usr/bin/env bash

set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
weather_location=""

usage() {
    cat <<'EOF'
Usage: ./scripts/setup-fedora.sh --weather-location LOCATION

LOCATION is kept only in the generated local Omarchy shell state. It is never
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

if [[ -z "$(dnf repoquery --qf '%{name}' hyprland 2>/dev/null | head -n 1)" ]]; then
    cat >&2 <<'EOF'
The Hyprland packages are unavailable from enabled repositories.
Review and enable the nett00n/hyprland Fedora COPR, then rerun this script:

    sudo dnf copr enable nett00n/hyprland

Repository enablement is intentionally not automated.
EOF
    exit 1
fi

hyprland_copr_repo='copr:copr.fedorainfracloud.org:nett00n:hyprland'
if dnf repolist --enabled | grep -qF "$hyprland_copr_repo"; then
    sudo dnf config-manager setopt \
        "$hyprland_copr_repo.excludepkgs=quickshell"
fi

packages=(
    bluez
    breeze-icon-theme
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
    hyprpaper
    hyprpolkitagent
    inotify-tools
    iproute
    iputils
    iw
    jq
    kf6-kconfig
    kitty
    libnotify
    mako
    NetworkManager-tui
    NetworkManager-wifi
    pam-kwallet
    pipewire-alsa
    plasma-breeze
    playerctl
    pulseaudio-utils
    python3
    quickshell
    rofi
    slurp
    tuned-ppd
    unicode-ucd
    unzip
    upower
    vim-enhanced
    wireplumber
    wl-clipboard
    wtype
    xdg-utils
)

sudo dnf install -y "${packages[@]}"
sudo systemctl enable --now bluetooth.service
sudo dnf distro-sync -y \
    --allow-vendor-change \
    --repo=fedora \
    --repo=updates \
    quickshell
flatpak remote-add \
    --user \
    --if-not-exists \
    flathub \
    https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install --user -y flathub app.zen_browser.zen
zen_profile_root="$HOME/.var/app/app.zen_browser.zen/.zen"
zen_profiles_ini="$zen_profile_root/profiles.ini"
if [[ ! -f "$zen_profiles_ini" ]]; then
    zen_screenshot=$(mktemp --suffix=.png)
    timeout 20 flatpak run app.zen_browser.zen \
        --headless \
        --screenshot "$zen_screenshot" \
        about:blank >/dev/null 2>&1 || true
    rm -f "$zen_screenshot"
fi
python3 - "$zen_profiles_ini" "$root/config/zen/user.js" <<'PY'
import configparser
import pathlib
import re
import sys

profiles_path = pathlib.Path(sys.argv[1])
source_path = pathlib.Path(sys.argv[2])
if not profiles_path.is_file():
    raise SystemExit("Zen profile initialization failed.")

profiles = configparser.RawConfigParser()
profiles.read(profiles_path)

profile_path = None
for section in profiles.sections():
    if section.startswith("Install") and profiles.has_option(section, "Default"):
        profile_path = profiles.get(section, "Default")
        break

if profile_path is None:
    for section in profiles.sections():
        if section.startswith("Profile") and profiles.getboolean(
            section, "Default", fallback=False
        ):
            profile_path = profiles.get(section, "Path")
            break

if profile_path is None:
    raise SystemExit("Unable to identify Zen's default profile.")

target = profiles_path.parent / profile_path / "user.js"
target.parent.mkdir(parents=True, exist_ok=True)
existing = target.read_text() if target.exists() else ""

for preference in source_path.read_text().splitlines():
    match = re.match(r'user_pref\("([^"]+)",', preference)
    if not match:
        continue
    pattern = re.compile(
        rf'^user_pref\("{re.escape(match.group(1))}",.*\);$',
        re.MULTILINE,
    )
    if pattern.search(existing):
        existing = pattern.sub(preference, existing)
    else:
        existing += ("" if existing.endswith("\n") or not existing else "\n")
        existing += preference + "\n"

target.write_text(existing)
PY
"$root/scripts/install-nerd-font.sh"
"$root/scripts/install-cliamp.sh"
"$root/scripts/install-proton-pass-cli.sh"
"$root/scripts/install-voxtype.sh"

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
link_config "$root/config/hypr/hyprpaper.conf" "$HOME/.config/hypr/hyprpaper.conf"
link_config "$root/config/mako/config" "$HOME/.config/mako/config"
copy_config "$root/config/btop/btop.conf" "$HOME/.config/btop/btop.conf"
link_config "$root/config/btop/themes/current.theme" "$HOME/.config/btop/themes/current.theme"
link_config "$root/config/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
link_config "$root/config/rofi/config.rasi" "$HOME/.config/rofi/config.rasi"
link_config "$root/config/fontconfig/fonts.conf" "$HOME/.config/fontconfig/fonts.conf"
link_config "$root/config/voxtype/config.toml" "$HOME/.config/voxtype/config.toml"
link_config "$root/config/herdr/config.toml" "$HOME/.config/herdr/config.toml"
link_config "$root/config/omarchy/shell.toml" "$HOME/.config/omarchy/shell.toml"
link_config \
    "$root/vendor/orthodox-daily" \
    "$HOME/.config/omarchy/plugins/io.github.tyrichards.orthodox-daily"
link_config \
    "$root/vendor/protonpass" \
    "$HOME/.config/omarchy/plugins/josh2c.protonpass"

vscode_argv="$HOME/.vscode/argv.json"
mkdir -p "$(dirname "$vscode_argv")"
python3 - "$vscode_argv" <<'PY'
import os
import pathlib
import re
import sys
import tempfile

path = pathlib.Path(sys.argv[1])
text = path.read_text() if path.exists() else "{}\n"
setting = '"password-store": "gnome-libsecret"'
pattern = re.compile(
    r'(^\s*"password-store"\s*:\s*)"[^"]*"',
    re.MULTILINE,
)

if pattern.search(text):
    updated = pattern.sub(r'\1"gnome-libsecret"', text)
else:
    closing_brace = text.rfind("}")
    if closing_brace < 0:
        raise SystemExit(f"{path} is not a valid VS Code runtime arguments file.")

    before = text[:closing_brace].rstrip()
    separator = "\n" if before.endswith(("{", ",")) else ",\n"
    updated = f"{before}{separator}\t{setting}\n{text[closing_brace:]}"

if updated != text:
    with tempfile.NamedTemporaryFile(
        "w",
        dir=path.parent,
        prefix=f"{path.name}.",
        delete=False,
    ) as temporary:
        temporary.write(updated)
        temporary_path = temporary.name
    os.chmod(temporary_path, path.stat().st_mode if path.exists() else 0o644)
    os.replace(temporary_path, path)
PY

"$HOME/.local/bin/voxtype" setup \
    --download \
    --model base.en \
    --no-post-install

for helper in "$root"/bin/*; do
    chmod +x "$helper"
    link_config "$helper" "$HOME/.local/bin/$(basename "$helper")"
done

chmod +x "$root"/vendor/omarchy/bin/*

backup_target "$HOME/.config/quickshell/shell.qml"
weather_target="$HOME/.local/state/omarchy/settings/weather.json"
mkdir -p "$(dirname "$weather_target")"
weather_temporary=$(mktemp "$weather_target.tmp.XXXXXX")
if ! python3 - "$weather_temporary" "$weather_location" <<'PY'
import json
import pathlib
import sys

target, location = sys.argv[1:]
pathlib.Path(target).write_text(
    json.dumps({"name": location}, indent=2) + "\n"
)
PY
then
    rm -f "$weather_temporary"
    exit 1
fi
backup_target "$weather_target"
mv "$weather_temporary" "$weather_target"

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
plasma-apply-colorscheme BreezeDark
kwriteconfig6 --file kdeglobals --group General --key ColorScheme BreezeDark
kwriteconfig6 --file "$HOME/.config/gtk-3.0/settings.ini" \
    --group Settings --key gtk-font-name 'JetBrainsMono Nerd Font, 10'
kwriteconfig6 --file "$HOME/.config/gtk-3.0/settings.ini" \
    --group Settings --key gtk-theme-name Breeze-Dark
kwriteconfig6 --file "$HOME/.config/gtk-3.0/settings.ini" \
    --group Settings --key gtk-application-prefer-dark-theme true
kwriteconfig6 --file "$HOME/.config/gtk-4.0/settings.ini" \
    --group Settings --key gtk-font-name 'JetBrainsMono Nerd Font, 10'
kwriteconfig6 --file "$HOME/.config/gtk-4.0/settings.ini" \
    --group Settings --key gtk-theme-name Breeze-Dark
kwriteconfig6 --file "$HOME/.config/gtk-4.0/settings.ini" \
    --group Settings --key gtk-application-prefer-dark-theme true
gsettings set org.gnome.desktop.interface font-name 'JetBrainsMono Nerd Font 10'
gsettings set org.gnome.desktop.interface monospace-font-name \
    'JetBrainsMono Nerd Font 10'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'Breeze-Dark'
fc-cache -f >/dev/null

wallpaper_dir="$HOME/.wallpapers"
mkdir -p "$wallpaper_dir"
if ! find "$wallpaper_dir" -maxdepth 1 \( -type f -o -type l \) \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \
       -o -iname '*.bmp' -o -iname '*.webp' -o -iname '*.svg' \) \
    -print -quit | grep -q .
then
    for wallpaper in /usr/share/hypr/wall{0,1,2}.png; do
        if [[ -f "$wallpaper" ]]; then
            ln -sfn "$wallpaper" "$wallpaper_dir/hypr-$(basename "$wallpaper")"
        fi
    done
fi

systemctl --user disable --now hyprpaper.service
systemctl --user enable --now hypridle.service

if hyprctl version >/dev/null 2>&1; then
    hyprctl reload >/dev/null
    pgrep -x hyprpaper >/dev/null \
        || hyprctl dispatch 'hl.dsp.exec_cmd("hyprpaper")' >/dev/null
    "$HOME/.local/bin/voxtype" status --format json \
        | jq -e '.class != "stopped"' >/dev/null \
        || hyprctl dispatch 'hl.dsp.exec_cmd("voxtype daemon")' >/dev/null
    qs kill -p "$root/vendor/omarchy/shell" --any-display \
        >/dev/null 2>&1 || true
    hyprctl dispatch \
        'hl.dsp.exec_cmd("temu-omarchy-shell start")' >/dev/null || true
fi

printf 'Setup complete.\n'
printf 'Backups, when needed, were stored in %s\n' "$backup_root"
printf 'Log out and back in to refresh fonts in every application.\n'
