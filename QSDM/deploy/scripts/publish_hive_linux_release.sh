#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo "usage: $0 <stage-dir> <hive-version> [webroot]" >&2
  exit 64
fi

stage_dir="$(cd "$1" && pwd)"
hive_version="$2"
webroot="${3:-/var/www/QSD}"
downloads="$webroot/downloads"

if [[ ! "$hive_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "invalid Hive version: $hive_version" >&2
  exit 64
fi

appimage="QSD-hive-${hive_version}-linux-x86_64.AppImage"
archive="QSD-hive-${hive_version}-linux-x64.tar.gz"
checksums="QSD-hive-${hive_version}-linux-SHA256SUMS.txt"
provenance="QSD-hive-${hive_version}-linux-release-provenance.json"
evidence="QSD-hive-${hive_version}-linux-payload-evidence.json"
required_downloads=(
  "$appimage"
  "$archive"
  "$checksums"
  "$provenance"
  "$evidence"
  "latest-linux.yml"
  "QSD-hive-release-linux.json"
)

for file in "${required_downloads[@]}"; do
  test -f "$stage_dir/downloads/$file"
done
test -f "$stage_dir/download.html"

(
  cd "$stage_dir/downloads"
  sha256sum -c "$checksums"
)
grep -qx "version: ${hive_version}" "$stage_dir/downloads/latest-linux.yml"
grep -q "url: ${appimage}" "$stage_dir/downloads/latest-linux.yml"
grep -q '"schema": "QSD.signed-release.v1"' \
  "$stage_dir/downloads/QSD-hive-release-linux.json"
grep -q '"key_id": "10ab9c5710761d4c9dca59d42446e9ea0e3315d15cdc3715df1dcb8c96fa07a1"' \
  "$stage_dir/downloads/QSD-hive-release-linux.json"
manifest_payload="$(sed -n 's/.*"manifest_base64": "\([^"]*\)".*/\1/p' \
  "$stage_dir/downloads/QSD-hive-release-linux.json")"
test -n "$manifest_payload"
printf '%s' "$manifest_payload" | base64 --decode | \
  grep -q '"version": "'"${hive_version}"'"'

install -d -o caddy -g caddy -m 0755 "$webroot" "$downloads"

atomic_install() {
  local source="$1"
  local destination="$2"
  local mode="${3:-0644}"
  local temporary="${destination}.new.$$"

  if [[ -e "$destination" ]]; then
    cmp --silent "$source" "$destination" || {
      echo "refusing to replace immutable release artifact: $destination" >&2
      exit 1
    }
    return
  fi

  install -o caddy -g caddy -m "$mode" "$source" "$temporary"
  mv "$temporary" "$destination"
}

install_pointer() {
  local source="$1"
  local destination="$2"
  local temporary="${destination}.new.$$"
  install -o caddy -g caddy -m 0644 "$source" "$temporary"
  mv -f "$temporary" "$destination"
}

# Immutable packages and their evidence become public before any pointer moves.
for file in "$appimage" "$archive" "$provenance" "$evidence"; do
  atomic_install "$stage_dir/downloads/$file" "$downloads/$file"
done
install_pointer "$stage_dir/downloads/$checksums" "$downloads/$checksums"

for file in "$appimage" "$archive" "$checksums"; do
  curl --fail --silent --show-error --head --max-time 30 \
    "https://QSD.tech/downloads/$file" >/dev/null
done

install_pointer "$stage_dir/download.html" "$webroot/download.html"

# The Linux exact-version policy moves last. Windows latest.yml is untouched.
install_pointer "$stage_dir/downloads/latest-linux.yml" "$downloads/latest-linux.yml"
install_pointer "$stage_dir/downloads/QSD-hive-release-linux.json" \
  "$downloads/QSD-hive-release-linux.json"

curl --fail --silent --show-error --max-time 30 \
  "https://QSD.tech/downloads/latest-linux.yml" | grep -qx "version: ${hive_version}"
curl --fail --silent --show-error --max-time 30 \
  "https://QSD.tech/downloads/QSD-hive-release-linux.json" | \
  grep -q '"schema": "QSD.signed-release.v1"'
curl --fail --silent --show-error --max-time 30 \
  "https://QSD.tech/download.html" | grep -q "QSD-hive-${hive_version}-linux-x86_64.AppImage"

echo "Published QSD Hive ${hive_version} for Linux. Windows manifest unchanged."
