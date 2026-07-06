importScripts('flutter_service_worker.js');

const CUSTOM_CACHE_NAME = 'mak-finflow-custom-v1';

self.addEventListener('install', (event) => {
    // Force new SW to activate immediately, don't wait for old tabs to close
    self.skipWaiting();
});

self.addEventListener('activate', (event) => {
    event.waitUntil(
        (async () => {
            // Delete ALL old caches on every new deployment
            const cacheNames = await caches.keys();
            await Promise.all(
                cacheNames
                    .filter(name => name !== CUSTOM_CACHE_NAME)
                    .map(name => {
                        return caches.delete(name);
                    })
            );
            // Take control of all open tabs immediately
            await self.clients.claim();

            // Tell all open tabs to hard reload
            const clients = await self.clients.matchAll({ type: 'window' });
            clients.forEach(client => {
                client.postMessage({ type: 'SW_UPDATED' });
            });
        })()
    );
});

self.addEventListener('message', (event) => {
    if (event.data?.type === 'SKIP_WAITING') {
        self.skipWaiting();
    }
});

self.addEventListener('fetch', (event) => {
    if (event.request.method !== 'GET') return;
    
    // Skip caching for API calls to make sure they always fetch fresh
    if (event.request.url.includes('/api/')) return;

    event.respondWith(
        fetch(event.request).catch(() => caches.match(event.request))
        // ↑ Network FIRST — only fall back to cache if offline
        // This ensures users always get fresh assets when online
    );
});
