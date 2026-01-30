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
