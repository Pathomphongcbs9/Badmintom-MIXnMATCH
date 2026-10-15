// Offline support. Bump VERSION whenever you deploy changes so phones pick up the new version.
const VERSION = 'mixmatch-v57';
const CORE = ['/', '/index.html', '/config.js', '/manifest.webmanifest', '/icons/icon-192.png', '/icons/apple-touch-icon.png'];
// Only these outside files are cached (fonts and libraries). Supabase data is never cached here.
const CDN = ['fonts.googleapis.com', 'fonts.gstatic.com', 'cdnjs.cloudflare.com', 'cdn.jsdelivr.net'];

self.addEventListener('install', (e) => {
  e.waitUntil(caches.open(VERSION).then((c) => c.addAll(CORE)).then(() => self.skipWaiting()));
});

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((k) => k !== VERSION).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

const put = (req, res) => caches.open(VERSION).then((c) => c.put(req, res));

self.addEventListener('fetch', (e) => {
  const req = e.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);

  // Our own files: network first so updates arrive, cached copy when offline.
  // Vercel Web Analytics requests are never cached.
  if (url.pathname.startsWith('/_vercel/')) return;

  if (url.origin === self.location.origin) {
    e.respondWith(
      fetch(req)
        .then((res) => { if (res.ok) put(req.mode === 'navigate' ? '/index.html' : req, res.clone()); return res; })
        .catch(() => caches.match(req.mode === 'navigate' ? '/index.html' : req, { ignoreSearch: true }))
    );
    return;
  }

  // Fonts and libraries: cached copy first, refreshed in the background.
  if (CDN.includes(url.hostname)) {
    e.respondWith(
      caches.match(req).then((hit) => {
        const net = fetch(req)
          .then((res) => { if (res && (res.ok || res.type === 'opaque')) put(req, res.clone()); return res; })
          .catch(() => hit);
        return hit || net;
      })
    );
  }
  // Everything else (Supabase API, sign-in) goes straight to the network.
});
