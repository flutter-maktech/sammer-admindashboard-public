// custom_service_worker.js (CLEAN PRODUCTION VERSION)

const CACHE_PREFIX = "nexprime-cache";

self.addEventListener("install", (event) => {
    self.skipWaiting();
});

self.addEventListener("activate", (event) => {
    event.waitUntil(
        (async () => {

            console.log("[SW] Activating & clearing cache...");

            const cacheNames = await caches.keys();

            await Promise.all(
                cacheNames.map((name) => caches.delete(name))
            );

            await self.clients.claim();

            const clients = await self.clients.matchAll({
                type: "window",
                includeUncontrolled: true
            });

            clients.forEach((client) => {
                client.postMessage({
                    type: "SW_UPDATED"
                });
            });

            console.log("[SW] Activated successfully");
        })()
    );
});

self.addEventListener("message", (event) => {
    if (event.data?.type === "SKIP_WAITING") {
        self.skipWaiting();
    }
});

self.addEventListener("fetch", (event) => {

    if (event.request.method !== "GET") return;

    // NEVER cache API calls
    if (event.request.url.includes("/api/")) return;

    event.respondWith(
        fetch(event.request, {
            cache: "no-store"
        }).catch(async () => {
            const cached = await caches.match(event.request);
            return cached || Response.error();
        })
    );
});