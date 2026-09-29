// Local static preview only. Never proxies production API or reads credentials.
import http from 'node:http';
import { createReadStream } from 'node:fs';
import { stat } from 'node:fs/promises';
import { resolve, sep, extname } from 'node:path';

const root = resolve(process.argv[2] || 'build/web');
const port = Number(process.env.WEBAPP_PORT || 8788);
const types = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript',
  '.json': 'application/json', '.css': 'text/css', '.wasm': 'application/wasm',
  '.png': 'image/png', '.svg': 'image/svg+xml', '.woff2': 'font/woff2', '.ttf': 'font/ttf' };
const server = http.createServer(async (req, res) => {
  res.setHeader('Cache-Control', 'no-store');
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('Referrer-Policy', 'no-referrer');
  res.setHeader('Content-Security-Policy', "default-src 'self'; script-src 'self' 'wasm-unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; font-src 'self' data: https://fonts.gstatic.com; connect-src 'self' https://api.onaria.ai.kr https://fonts.gstatic.com; worker-src 'self' blob:; object-src 'none'; base-uri 'self'; frame-ancestors 'none'");
  try {
    const pathname = decodeURIComponent(new URL(req.url, 'http://localhost').pathname);
    if (req.method !== 'GET' && req.method !== 'HEAD') { res.writeHead(405).end(); return; }
    if (pathname === '/' || pathname === '/webapp') { res.writeHead(302, { Location: '/webapp/' }).end(); return; }
    if (!pathname.startsWith('/webapp/')) { res.writeHead(404).end(); return; }
    const relative = pathname.slice('/webapp/'.length) || 'index.html';
    if (relative.split('/').some(part => part.startsWith('.'))) { res.writeHead(404).end(); return; }
    const file = resolve(root, relative);
    if (!file.startsWith(root + sep) || !(await stat(file)).isFile()) { res.writeHead(404).end(); return; }
    res.setHeader('Content-Type', types[extname(file)] || 'application/octet-stream');
    if (req.method === 'HEAD') { res.end(); return; }
    createReadStream(file).on('error', () => res.destroy()).pipe(res);
  } catch { res.writeHead(404).end(); }
});
server.listen(port, '127.0.0.1', () => console.log(`ONARIA preview: http://127.0.0.1:${port}/webapp/`));
for (const signal of ['SIGINT', 'SIGTERM']) process.once(signal, () => server.close());
