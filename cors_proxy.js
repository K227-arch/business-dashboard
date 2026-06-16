const http = require('http');
const https = require('https');

const TARGET = 'najod.k.frappe.cloud';
const PORT = 8088;

const server = http.createServer((req, res) => {
  const targetUrl = new URL(req.url, `https://${TARGET}`);
  
  const options = {
    hostname: TARGET,
    port: 443,
    path: targetUrl.pathname + targetUrl.search,
    method: req.method,
    headers: {
      ...req.headers,
      host: TARGET,
      'origin': `http://localhost:${PORT}`,
    },
  };

  const proxyReq = https.request(options, (proxyRes) => {
    res.writeHead(proxyRes.statusCode, {
      ...proxyRes.headers,
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': '*',
    });
    proxyRes.pipe(res);
  });

  proxyReq.on('error', (e) => {
    res.writeHead(500, { 'Access-Control-Allow-Origin': '*' });
    res.end(`Proxy error: ${e.message}`);
  });

  if (req.method === 'OPTIONS') {
    res.writeHead(204, {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': '*',
    });
    return res.end();
  }

  req.pipe(proxyReq);
});

server.listen(PORT, '127.0.0.1', () => {
  console.log(`CORS proxy running on http://127.0.0.1:${PORT} → https://${TARGET}`);
});
