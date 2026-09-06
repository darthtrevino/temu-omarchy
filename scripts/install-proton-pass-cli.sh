#!/usr/bin/env bash

set -euo pipefail

version="2.3.3"

case "$(uname -m)" in
    x86_64)
        architecture="x86_64"
        checksum="b5b49a8b3fd0af8830c0c1979f28ea0c90ccece73f59023a8bca8245d4b68da9"
        ;;
    aarch64|arm64)
        architecture="aarch64"
        checksum="9c3e85e10d3bb631ffe377f063d996b9cc9a545d30971bcedf5910e16d03542b"
        ;;
    *)
        printf 'Unsupported Proton Pass CLI architecture: %s\n' "$(uname -m)" >&2
        exit 1
        ;;
esac

asset="pass-cli-linux-$architecture"
url="https://github.com/protonpass/pass-cli/releases/download/${version}/${asset}"
temporary=$(mktemp)

cleanup() {
    rm -f "$temporary"
}
trap cleanup EXIT

printf 'Downloading Proton Pass CLI v%s for %s...\n' "$version" "$architecture"
curl -fL --retry 3 --progress-bar -o "$temporary" "$url"
printf '%s  %s\n' "$checksum" "$temporary" | sha256sum --check

mkdir -p "$HOME/.local/bin"
install -m 0755 "$temporary" "$HOME/.local/bin/pass-cli"

installed=$(
    "$HOME/.local/bin/pass-cli" --version \
        | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' \
        | head -n 1
)
if [[ "$installed" != "$version" ]]; then
    printf 'Proton Pass CLI installation failed: reported version is %s\n' \
        "${installed:-unknown}" >&2
    exit 1
fi

printf 'Installed Proton Pass CLI v%s.\n' "$version"
