# Vite Workspace Template

This Coder workspace template creates a development environment with Vite + React, specifically designed to test subdomain routing through the NGINX boundary.

## Purpose

This template tests the critical path for workspace app access:

```
Windows Client → NGINX Boundary → Coder → Workspace → Vite Dev Server
                    ↓
         Wildcard subdomain routing
         *.coder.example.com
```

## How It Works

### Subdomain Routing

When you click the "Vite Dev Server" app in Coder, it generates a URL like:

```
https://5173-myworkspace-myuser.coder.example.com
```

This URL flows through:
1. **DNS** - Wildcard `*.coder.example.com` resolves to the NLB
2. **NLB** - Forwards to NGINX Ingress Controller
3. **NGINX** - Routes based on `Host` header to Coder service
4. **Coder** - Proxies to the workspace agent on port 5173
5. **Vite** - Serves the React app with hot module replacement

### Why `--host` Matters

The Vite dev server is started with `--host` flag:

```bash
npm run dev -- --host
```

Without this flag, Vite only binds to `127.0.0.1`, making it inaccessible from outside the container. With `--host`, it binds to `0.0.0.0`, allowing the Coder agent to proxy requests to it.

## Using the Template

### 1. Push to Coder

```bash
cd templates/vite-workspace
coder templates push vite-workspace
```

### 2. Create Workspace

```bash
coder create my-vite --template vite-workspace
```

Or use the Coder dashboard.

### 3. Access Vite Dev Server

1. Open your workspace in the Coder dashboard
2. Click the "Vite Dev Server" app icon
3. The app opens in a new tab via subdomain URL

### 4. Test Hot Reload

1. Open the VS Code app (or SSH into workspace)
2. Edit `~/vite-app/src/App.jsx`
3. Changes should appear immediately in the browser

## Testing Through NGINX Boundary

From the Windows test client:

1. RDP into the Windows machine
2. Open Chrome
3. Navigate to `https://coder.<your-domain>`
4. Create this workspace
5. Click the Vite app icon
6. Verify the URL is a subdomain (not path-based)
7. Make a code change and verify hot reload works

If hot reload doesn't work:
- WebSocket upgrade might not be configured
- Check NGINX ingress logs for connection upgrade issues

## Template Structure

```
vite-workspace/
├── main.tf      # Terraform resources
└── README.md    # This file
```

## Resources Created

| Resource | Description |
|----------|-------------|
| `coder_agent` | Agent running in workspace, handles connections |
| `coder_app` (vite) | Vite dev server app with subdomain routing |
| `coder_app` (code) | VS Code web IDE |
| `kubernetes_pod` | Actual workspace container |

## Troubleshooting

### App shows "Waiting for app to become ready"

The Vite dev server might not have started yet. Check:

```bash
coder ssh my-vite
cat /tmp/vite.log
```

### "502 Bad Gateway" from NGINX

The Coder agent might not be proxying correctly. Verify:
1. Agent is running: Check workspace status in Coder
2. Vite is running: `curl localhost:5173` from inside workspace
3. Port is correct: Check `coder_app.vite.url`

### Hot reload not working

WebSocket connections might be blocked. Check:
1. NGINX config has websocket upgrade support
2. Browser console for WebSocket errors
3. NGINX ingress logs for upgrade failures
