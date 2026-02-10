# HAProxy Configuration for OpenClaw Gateway

Production-ready reverse proxy config with TLS termination, rate limiting, IP allowlisting, and WebSocket support.

## Why HAProxy

- 30-35% better CPU/memory efficiency than Nginx
- Superior multithreaded TLS performance
- Native `timeout tunnel` for long-lived WebSocket connections
- Consistent latency under load
- Powerful ACL system for IP allowlisting

## Quick Setup

### 1. Install HAProxy

```bash
# Ubuntu/Debian
sudo apt-get install haproxy

# macOS
brew install haproxy
```

### 2. Generate a TLS Certificate

**Self-signed (development):**

```bash
openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem \
  -days 365 -nodes -subj "/CN=openclaw.local"
sudo mkdir -p /etc/haproxy/certs
sudo bash -c 'cat cert.pem key.pem > /etc/haproxy/certs/openclaw.pem'
sudo chmod 600 /etc/haproxy/certs/openclaw.pem
rm cert.pem key.pem
```

**Let's Encrypt (production):**

```bash
sudo certbot certonly --standalone -d openclaw.example.com
sudo bash -c 'cat /etc/letsencrypt/live/openclaw.example.com/fullchain.pem \
    /etc/letsencrypt/live/openclaw.example.com/privkey.pem \
    > /etc/haproxy/certs/openclaw.pem'
sudo chmod 600 /etc/haproxy/certs/openclaw.pem
```

Auto-renew (add to crontab):

```
0 3 * * * certbot renew --quiet --deploy-hook "cat /etc/letsencrypt/live/openclaw.example.com/fullchain.pem /etc/letsencrypt/live/openclaw.example.com/privkey.pem > /etc/haproxy/certs/openclaw.pem && systemctl reload haproxy"
```

### 3. Configure IP Allowlist

Edit `allowlist.txt` with your trusted networks, or edit the `allowed_ips` ACL directly in `haproxy.cfg`.

### 4. Deploy

```bash
# Copy config
sudo cp haproxy.cfg /etc/haproxy/haproxy.cfg
sudo cp allowlist.txt /etc/haproxy/allowlist.txt

# Test configuration
sudo haproxy -f /etc/haproxy/haproxy.cfg -c

# Start
sudo systemctl start haproxy
sudo systemctl enable haproxy
```

## Ports

| Port | Service |
|---|---|
| 80 | HTTP (redirects to 443) |
| 443 | HTTPS (TLS-terminated proxy to OpenClaw) |
| 8404 | HAProxy stats dashboard (optional) |

## Configuration Details

### Rate Limiting

Default: 100 requests per 10 seconds per IP. Adjust in the `ft_openclaw` frontend:

```
http-request deny deny_status 429 if { sc_http_req_rate(0) gt 100 }
```

### WebSocket

The `timeout tunnel 1h` setting keeps WebSocket connections alive for up to 1 hour of inactivity. Adjust as needed.

### Security Headers

Applied automatically on all responses:
- `Strict-Transport-Security` (HSTS)
- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: SAMEORIGIN`
- `X-XSS-Protection`
- `Referrer-Policy`

### Stats Dashboard

Available at `http://localhost:8404/stats` with credentials `admin:changeme`. Change or remove this section in production.

## Monitoring

```bash
# Check status
sudo systemctl status haproxy

# View logs
journalctl -u haproxy -f

# Stats via socket
echo "show stats" | sudo socat stdio /run/haproxy/admin.sock

# Test connection
curl -k https://localhost/
```

## OpenClaw Gateway Config

The `direct/openclaw.json` is pre-configured to trust the HAProxy loopback addresses (`127.0.0.1`, `::1`) via `trustedProxies`. No changes needed if HAProxy runs on the same host.

If HAProxy runs on a different host, add its IP to `trustedProxies` in `openclaw.json`.
