#!/usr/bin/env bash

set -euo pipefail

version="1.0.1"
source_commit="dda37ca72b71294d08b0c5bb49c5b24ca590d847"
source_checksum="0e75614f77f9b66b82f1acdf90129f6b66ca0246b703ec8b036cea291f0fad8b"

case "$(uname -m)" in
    x86_64)
        architecture="x86_64"
        engine_variant="x86_64-avx2"
        engine_checksum="cb3843a894ef47aca230b30bb1c45c2ef8e0d015adf2fa754d60e55123165fd0"
        osd_checksum="7250027b1672507a6d584f795731c87e1d3b5c1de891438bd55e34b136a2d5cc"
        quickshell_checksum="b809c5140e844a6add801d7e592775cd89af8cce73fa399b6a3aec15dfd09533"
        bridge_checksum="45776290e364194d83a8b89445166406c278e890507bf07ec52a5f0e8fa57720"
        ;;
    aarch64|arm64)
        architecture="aarch64"
        engine_variant="aarch64-cpu"
        engine_checksum="b5e31a85aaa952d1a78c12b8a16ba5cbdcd92eb31adc7d1a908f3c9d06edd4f1"
        osd_checksum="ea910d4fd1fe331d38dbed1c3a639cb7e0c04542919192ff6f74be2139afe3c6"
        quickshell_checksum="097bd518d5e2eac2c3cbad714b65dd8058c818dcb4d900b9a16e442af7d65b8a"
        bridge_checksum="35170ad89fea2874fce0f08758ccc2164892ed643aacae632bcfbc6f10433976"
        ;;
    *)
        printf 'Unsupported Voxtype architecture: %s\n' "$(uname -m)" >&2
        exit 1
        ;;
esac

temporary_dir=$(mktemp -d)

cleanup() {
    rm -rf "$temporary_dir"
}
trap cleanup EXIT

install_asset() {
    local suffix=$1
    local target=$2
    local checksum=$3
    local asset="voxtype-${version}-linux-${suffix}"
    local temporary="$temporary_dir/$asset"
    local url="https://github.com/peteonrails/voxtype/releases/download/v${version}/${asset}"

    printf 'Downloading %s...\n' "$asset"
    curl -fL --retry 3 --progress-bar -o "$temporary" "$url"
    printf '%s  %s\n' "$checksum" "$temporary" | sha256sum --check
    install -Dm0755 "$temporary" "$HOME/.local/bin/$target"
}

install_asset "$engine_variant" "voxtype" "$engine_checksum"
install_asset "$architecture-osd" "voxtype-osd" "$osd_checksum"
install_asset \
    "$architecture-osd-quickshell" \
    "voxtype-osd-quickshell" \
    "$quickshell_checksum"
install_asset \
    "$architecture-audio-bridge" \
    "voxtype-audio-bridge" \
    "$bridge_checksum"

source_archive="$temporary_dir/voxtype-source.tar.gz"
source_url="https://github.com/peteonrails/voxtype/archive/${source_commit}.tar.gz"
printf 'Downloading Voxtype Quickshell sources...\n'
curl -fL --retry 3 --progress-bar -o "$source_archive" "$source_url"
printf '%s  %s\n' "$source_checksum" "$source_archive" | sha256sum --check
tar -xzf "$source_archive" -C "$temporary_dir"
"$HOME/.local/bin/voxtype" setup quickshell \
    --source "$temporary_dir/voxtype-${source_commit}/quickshell" \
    --force

installed=$("$HOME/.local/bin/voxtype" --version | awk '{print $2}')
if [[ "$installed" != "$version" ]]; then
    printf 'Voxtype installation failed: reported version is %s\n' "$installed" >&2
    exit 1
fi

if [[ $("$HOME/.local/bin/voxtype-osd" --version | awk '{print $2}') != "$version" ]] \
    || [[ $("$HOME/.local/bin/voxtype-osd-quickshell" --version | awk '{print $2}') != "$version" ]] \
    || [[ $("$HOME/.local/bin/voxtype-audio-bridge" --version | awk '{print $2}') != "$version" ]]
then
    printf 'Voxtype OSD installation failed version verification.\n' >&2
    exit 1
fi

printf 'Installed Voxtype v%s with Quickshell OSD.\n' "$version"
