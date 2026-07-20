(() => {
  "use strict";

  const REQUEST_SOURCE = "QSD-hive-provider-request";
  const RESPONSE_SOURCE = "QSD-hive-provider-response";
  const METHODS = new Set([
    "QSD_requestAccounts",
    "QSD_accounts",
    "QSD_getBalance",
    "QSD_signMessage",
    "QSD_sendTransaction",
    "QSD_disconnect",
  ]);

  const postPageResponse = (id, response) =>
    window.postMessage(
      { ...response, source: RESPONSE_SOURCE, id },
      window.location.origin
    );

  chrome.runtime.onMessage.addListener((message, _sender, sendResponse) => {
    if (
      message?.source !== "QSD-hive-background-response" ||
      typeof message.id !== "string" ||
      !message.response ||
      typeof message.response !== "object"
    ) {
      return;
    }
    postPageResponse(message.id, message.response);
    sendResponse({ received: true });
  });

  window.addEventListener("message", (event) => {
    if (
      event.source !== window ||
      event.origin !== window.location.origin ||
      event.data?.source !== REQUEST_SOURCE ||
      typeof event.data?.id !== "string"
    ) {
      return;
    }

    const { id, method, params } = event.data;
    if (!METHODS.has(method)) {
      window.postMessage(
        {
          source: RESPONSE_SOURCE,
          id,
          ok: false,
          error: `Unsupported QSD wallet method: ${String(method)}`,
        },
        window.location.origin
      );
      return;
    }

    chrome.runtime.sendMessage(
      {
        source: "QSD-hive-content",
        id,
        method,
        params,
      },
      () => {
        const runtimeError = chrome.runtime.lastError;
        if (runtimeError) {
          postPageResponse(id, {
            ok: false,
            error: runtimeError.message,
          });
        }
      }
    );
  });
})();
