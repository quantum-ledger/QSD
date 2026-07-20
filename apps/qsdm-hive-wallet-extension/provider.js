(() => {
  "use strict";

  if (window.QSD?.isQSDHive) return;

  const REQUEST_SOURCE = "QSD-hive-provider-request";
  const RESPONSE_SOURCE = "QSD-hive-provider-response";
  const pending = new Map();
  const listeners = new Map();

  const emit = (event, value) => {
    const callbacks = listeners.get(event) || [];
    callbacks.forEach((callback) => callback(value));
  };

  window.addEventListener("message", (event) => {
    if (
      event.source !== window ||
      event.origin !== window.location.origin ||
      event.data?.source !== RESPONSE_SOURCE ||
      typeof event.data?.id !== "string"
    ) {
      return;
    }
    const request = pending.get(event.data.id);
    if (!request) return;
    pending.delete(event.data.id);
    clearTimeout(request.timeout);
    if (event.data.ok) {
      if (request.method === "QSD_requestAccounts") {
        emit("accountsChanged", event.data.result);
      } else if (request.method === "QSD_disconnect") {
        emit("accountsChanged", []);
      }
      request.resolve(event.data.result);
    } else {
      request.reject(
        new Error(event.data.error || "QSD wallet request failed")
      );
    }
  });

  const provider = Object.freeze({
    isQSDHive: true,
    version: "QSD-provider/v1",
    request({ method, params } = {}) {
      if (typeof method !== "string" || !method.startsWith("QSD_")) {
        return Promise.reject(
          new Error("A valid QSD provider method is required")
        );
      }
      const id = crypto.randomUUID();
      return new Promise((resolve, reject) => {
        const timeout = setTimeout(() => {
          pending.delete(id);
          reject(new Error("QSD Hive did not answer the wallet request"));
        }, 125000);
        pending.set(id, { resolve, reject, timeout, method });
        window.postMessage(
          { source: REQUEST_SOURCE, id, method, params },
          window.location.origin
        );
      });
    },
    on(event, callback) {
      if (typeof callback !== "function") return provider;
      listeners.set(event, [...(listeners.get(event) || []), callback]);
      return provider;
    },
    removeListener(event, callback) {
      listeners.set(
        event,
        (listeners.get(event) || []).filter((entry) => entry !== callback)
      );
      return provider;
    },
  });

  Object.defineProperty(window, "QSD", {
    value: provider,
    configurable: false,
    enumerable: false,
    writable: false,
  });
  window.dispatchEvent(new Event("QSD#initialized"));
})();
