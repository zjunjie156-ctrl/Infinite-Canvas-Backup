# Public Website Deployment

This project is a FastAPI app. GitHub stores the code; runtime canvas data should live on the machine or server that runs the app.

## Local Public Tunnel

1. Start the app:

   ```powershell
   python main.py
   ```

2. Start a Cloudflare quick tunnel:

   ```powershell
   .\tools\cloudflared.exe tunnel --url http://127.0.0.1:3000
   ```

3. Send friends the `/canvas` URL from the tunnel domain.

## Server Deployment

The included `Dockerfile` can run the app on a cloud server:

```bash
docker build -t infinite-canvas .
docker run -d --name infinite-canvas -p 3000:3000 \
  -v infinite-canvas-data:/app/data \
  -v infinite-canvas-assets:/app/assets \
  -v infinite-canvas-output:/app/output \
  infinite-canvas
```

For a real domain, put Caddy, Nginx, or Cloudflare Tunnel in front of port `3000`.

## Do Not Commit

Keep these local-only:

- `API/.env`
- `data/`
- `assets/`
- `output/`
- `history.json`
- `python/`
- `tools/`
- `tmp-*`
