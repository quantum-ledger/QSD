#!/usr/bin/env bash
set -euo pipefail

extension_id="${1:-habkkkednignfkoffhpbjahcjbikkahh}"
if [[ ! "$extension_id" =~ ^[a-p]{32}$ ]]; then
  echo "usage: $0 [32-character-extension-id] [native-host-path]" >&2
  exit 64
fi

host_path="${2:-$(cd "$(dirname "$0")/../../native" && pwd)/QSD-hive-wallet-host}"
host_path="$(readlink -f "$host_path")"
if [[ ! -x "$host_path" ]]; then
  echo "QSD native messaging host is missing or not executable: $host_path" >&2
  exit 66
fi

manifest="$(cat <<JSON
{
  "name": "tech.QSD.hive_wallet",
  "description": "QSD Hive Wallet native bridge",
  "path": "$host_path",
  "type": "stdio",
  "allowed_origins": ["chrome-extension://$extension_id/"]
}
JSON
)"

for directory in \
  "$HOME/.config/google-chrome/NativeMessagingHosts" \
  "$HOME/.config/chromium/NativeMessagingHosts" \
  "$HOME/.config/microsoft-edge/NativeMessagingHosts"; do
  mkdir -p "$directory"
  printf '%s\n' "$manifest" > "$directory/tech.QSD.hive_wallet.json"
  chmod 0600 "$directory/tech.QSD.hive_wallet.json"
done

echo "QSD Wallet bridge registered for extension $extension_id"
