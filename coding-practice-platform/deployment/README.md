Deployment (Docker Compose)

This folder contains declarative deployment configs for the coding practice platform.

Quick start
1) Copy environment file:
   cp env.example .env

2) Start services:
   docker compose -f docker-compose.prod.yml --env-file .env up -d --build

3) Check status:
   docker compose -f docker-compose.prod.yml --env-file .env ps

Notes
- Edit .env to change exposed ports, memory limits, or project name.
- The scoring API binds to 0.0.0.0 inside the container so it is reachable via port mapping.

Public access without a domain (Cloudflare Tunnel)
1) Start the tunnel stack:
   docker compose -f docker-compose.tunnel.yml --env-file .env up -d --build

2) Get the public URL:
   docker compose -f docker-compose.tunnel.yml --env-file .env logs -f tunnel

Cloudflare will print a https://*.trycloudflare.com URL. Share that with students.

Public access without stopping the running app (tunnel-only)
1) Ensure the app is running on the host at http://localhost:3000 (e.g., `make start` in the repo).

2) Start the tunnel-only stack:
   docker compose -f docker-compose.tunnel-only.yml --env-file .env up -d

3) Get the public URL:
   docker compose -f docker-compose.tunnel-only.yml --env-file .env logs -f tunnel
