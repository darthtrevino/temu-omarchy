#!/usr/bin/env bash

set -euo pipefail

version="2.0.1"

case "$(uname -m)" in
    x86_64)
        architecture="amd64"
        checksum="a96c2c683bc5c58eeee496e3cc89113da46051a74fe7b2214c7f4092758b852c"
        ;;
    aarch64|arm64)
        architecture="arm64"
        checksum="8eb00f3965712d87a55dea029957d40ceb4c7767fdc14db5ba973508204d5936"
        ;;
    *)
        printf 'Unsupported cliamp architecture: %s\n' "$(uname -m)" >&2
        exit 1
        ;;
esac

asset="cliamp-linux-$architecture"
url="https://github.com/bjarneo/cliamp/releases/download/v${version}/${asset}"
temporary=$(mktemp)

cleanup() {
    rm -f "$temporary"
}
trap cleanup EXIT

printf 'Downloading cliamp v%s for %s...\n' "$version" "$architecture"
curl -fL --retry 3 --progress-bar -o "$temporary" "$url"
printf '%s  %s\n' "$checksum" "$temporary" | sha256sum --check

mkdir -p "$HOME/.local/bin"
install -m 0755 "$temporary" "$HOME/.local/bin/cliamp"

installed=$("$HOME/.local/bin/cliamp" --version | awk '{print $3}')
if [[ "$installed" != "v$version" ]]; then
    printf 'cliamp installation failed: reported version is %s\n' "$installed" >&2
    exit 1
fi

printf 'Installed cliamp v%s.\n' "$version"
