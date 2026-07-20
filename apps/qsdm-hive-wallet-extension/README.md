# QSD Wallet Extension

The extension lets websites use the active wallet in QSD Hive. It is a secure
provider, not a second wallet vault: it never stores a private key, keystore
JSON, or passphrase.

## User flow

1. Create or import a wallet once in **QSD Hive > Settings > Wallet**.
2. Keep Hive running in the notification area.
3. Open a supported website and select **Connect QSD Wallet**.
4. Approve the website once in Hive.

The website remains connected to that wallet until the user disconnects it in
the extension or revokes it under **Hive > Settings > Wallet > Connected
Sites**. Signatures and CELL transfers always require a fresh Hive approval.

There is no separate extension account, password, recovery phrase, or wallet
import. This avoids creating another copy of the user's wallet secrets.

## Installation

Packaged Hive releases register the native browser bridge automatically for
the current user. This requires no administrator access. The extension has the
stable Chromium ID `habkkkednignfkoffhpbjahcjbikkahh`.

Until the extension is published in browser stores, install it once:

1. Open the browser extensions page and enable developer mode.
2. Choose **Load unpacked** and select the bundled `wallet-extension` folder.
3. Start or restart QSD Hive.

Chrome, Edge, Chromium, and Brave are supported. Users upgrading from the old
random-ID development build should remove it and load the current bundled
extension once. Daily use is automatic after that migration.

The scripts in `native-host` remain available for development diagnostics;
normal packaged installs do not require running them manually.

## Website API

```js
const [address] = await window.QSD.request({
  method: "QSD_requestAccounts",
});

const signature = await window.QSD.request({
  method: "QSD_signMessage",
  params: { message: "QSD ownership challenge" },
});
```

Supported methods are `QSD_requestAccounts`, `QSD_accounts`,
`QSD_getBalance`, `QSD_signMessage`, `QSD_sendTransaction`, and
`QSD_disconnect`.

## Verification

After building the Windows native tools, run:

```powershell
node tests/run-acceptance.mjs
```

The isolated test validates the pinned extension ID, provider, native host,
popup, permissions, signing request, transfer request, and disconnect flow. It
does not open a private wallet or broadcast CELL.

With Hive running, this read-only probe checks the live local bridge:

```powershell
node tests/probe-live-broker.mjs
```
