#!/bin/bash
# _install_v033.sh — install v0.3.3 landing files into /var/www/QSD.
# Run on api.QSD.tech AFTER scp'ing the three files into /tmp.
set -euo pipefail
for f in index.html wallet.html wallet.js ; do
  install -o caddy -g caddy -m 0644 "/tmp/$f" "/var/www/QSD/$f"
  echo "updated /var/www/QSD/$f"
  rm -f "/tmp/$f"
done
systemctl reload caddy
echo "=== live probes ==="
curl -s -o /dev/null -w "index     http=%{http_code} bytes=%{size_download}\n" https://QSD.tech/
curl -s -o /dev/null -w "wallet    http=%{http_code} bytes=%{size_download}\n" https://QSD.tech/wallet.html
curl -s -o /dev/null -w "wallet.js http=%{http_code} bytes=%{size_download}\n" https://QSD.tech/wallet.js
echo
echo "=== version pill markers ==="
curl -s https://QSD.tech/ | grep -E "ver-pill-text|releases/tag/v|Current release:" | head -n 4
echo
echo "=== wallet.js SRI on wallet.html ==="
grep -E "wallet.js.*integrity" /var/www/QSD/wallet.html
echo
echo "=== wallet.js actual sha384 (must match SRI above) ==="
openssl dgst -sha384 -binary /var/www/QSD/wallet.js | openssl base64 -A
echo
echo "DONE."
