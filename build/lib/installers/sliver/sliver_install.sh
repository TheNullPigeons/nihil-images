#!/bin/bash
set -euo pipefail

readonly SLIVER_VERSION="1.7.8"
readonly SLIVER_MINISIGN_PUB_KEY="RWTZPg959v3b7tLG7VzKHRB1/QT+d3c71Uzetfa44qAoX5rH7mGoQTTR"

if [[ "$EUID" -ne 0 ]]; then
    echo "Please run as root" >&2
    exit 1
fi

command -v pacman >/dev/null || { echo "Sliver installer requires pacman" >&2; exit 1; }

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

# The image's optional Nihil package repository can be unavailable; install
# Sliver's dependencies from Arch's official repositories only.
cat >"${tmpdir}/pacman.conf" <<'EOF'
[options]
Architecture = auto
SigLevel = Required DatabaseOptional

[core]
Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist
EOF

pacman --config "${tmpdir}/pacman.conf" -Sy --noconfirm
pacman --config "${tmpdir}/pacman.conf" -S --needed --noconfirm \
    curl minisign mingw-w64-gcc mingw-w64-binutils mingw-w64-headers

for cmd in curl minisign install; do
    command -v "$cmd" >/dev/null || { echo "Required command not found: $cmd" >&2; exit 1; }
done

case "$(uname -m)" in
    x86_64|amd64) SLIVER_PLATFORM="linux-amd64" ;;
    aarch64|arm64) SLIVER_PLATFORM="linux-arm64" ;;
    *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

base_url="https://github.com/BishopFox/sliver/releases/download/v${SLIVER_VERSION}"

for component in server client; do
    file="sliver-${component}_${SLIVER_PLATFORM}"
    echo "Downloading Sliver ${SLIVER_VERSION}: ${file}"
    curl --fail --location --retry 3 --silent --show-error \
        "${base_url}/${file}" --output "${tmpdir}/${file}"
    curl --fail --location --retry 3 --silent --show-error \
        "${base_url}/${file}.minisig" --output "${tmpdir}/${file}.minisig"
    minisign -Vm "${tmpdir}/${file}" -x "${tmpdir}/${file}.minisig" \
        -P "$SLIVER_MINISIGN_PUB_KEY"
done

install -m 0755 "${tmpdir}/sliver-server_${SLIVER_PLATFORM}" /usr/local/bin/sliver-server
install -m 0755 "${tmpdir}/sliver-client_${SLIVER_PLATFORM}" /usr/local/bin/sliver-client
ln -sfn /usr/local/bin/sliver-client /usr/local/bin/sliver

sliver-server unpack --force
sliver-server version
echo "Sliver ${SLIVER_VERSION} installation completed."
