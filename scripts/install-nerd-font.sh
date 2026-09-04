#!/usr/bin/env bash

set -euo pipefail

version="3.5.1"
archive_name="JetBrainsMono.zip"
checksum="fab782a66f7d3019da64f6572db9fc5d3a4bcb19f9fa13e2d8a62e3693d6396e"
url="https://github.com/ryanoasis/nerd-fonts/releases/download/v${version}/${archive_name}"
destination="$HOME/.local/share/fonts/JetBrainsMonoNerdFont"
temporary=$(mktemp -d)
archive="$temporary/$archive_name"

cleanup() {
    rm -f "$archive"
    rmdir "$temporary" 2>/dev/null || true
}
trap cleanup EXIT

printf 'Downloading JetBrainsMono Nerd Font v%s...\n' "$version"
curl -fL --retry 3 --progress-bar -o "$archive" "$url"
printf '%s  %s\n' "$checksum" "$archive" | sha256sum --check

mkdir -p "$destination"
unzip -jo "$archive" 'JetBrainsMonoNerdFont-*.ttf' -d "$destination" >/dev/null
fc-cache -f "$destination" >/dev/null

resolved=$(
    fc-match -f '%{family}\n' 'JetBrainsMono Nerd Font' \
        | head -n 1 \
        | cut -d, -f1
)
if [[ "$resolved" != "JetBrainsMono Nerd Font" ]]; then
    printf 'Font installation failed: resolved family is %s\n' "$resolved" >&2
    exit 1
fi

printf 'Installed JetBrainsMono Nerd Font v%s.\n' "$version"
