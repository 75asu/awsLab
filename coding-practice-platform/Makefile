.PHONY: start stop restart logs status install clean prod-up prod-down prod-logs prod-reset tunnel-up tunnel-down tunnel-logs

# Start all services
start: start-piston start-api start-frontend
	@echo "\n✓ Platform running at http://localhost:3000"
	@echo "  VS Code Proxy: http://<host>:8081/proxy/3000/\n"

start-piston:
	@echo "[1/3] Starting Piston..."
	@cd piston-setup && docker compose up -d 2>/dev/null

start-api:
	@echo "[2/3] Starting Scoring API..."
	@cd scoring-api && HOST=127.0.0.1 PISTON_URL=http://localhost:2000 nohup npm start > /tmp/scoring-api.log 2>&1 & echo $$! > /tmp/scoring-api.pid
	@sleep 2

start-frontend:
	@echo "[3/3] Starting Frontend..."
	@cd frontend && nohup python3 -m http.server 3000 > /tmp/frontend.log 2>&1 & echo $$! > /tmp/frontend.pid
	@sleep 1

# Stop all services
stop:
	@echo "Stopping services..."
	@if [ -f /tmp/scoring-api.pid ]; then kill $$(cat /tmp/scoring-api.pid) 2>/dev/null || true; rm -f /tmp/scoring-api.pid; fi
	@if [ -f /tmp/frontend.pid ]; then kill $$(cat /tmp/frontend.pid) 2>/dev/null || true; rm -f /tmp/frontend.pid; fi
	@cd piston-setup && docker compose down 2>/dev/null || true
	@echo "✓ Stopped"

# Restart all services
restart: stop start

# Production (Docker)
prod-up:
	@echo "Starting Docker stack..."
	@docker compose up -d --build
	@echo "✓ Docker stack up (frontend: http://localhost:3000)"

prod-down:
	@docker compose down
	@echo "✓ Docker stack stopped"

prod-logs:
	@docker compose logs -f

prod-reset:
	@docker compose down
	@docker compose up -d --build
	@echo "✓ Docker stack rebuilt and started"

# Public tunnel (Docker only)
tunnel-up:
	@echo "Starting Cloudflare tunnel..."
	@cd deployment && cp -n env.example .env >/dev/null 2>&1 || true
	@cd deployment && sed -i 's|EXISTING_NETWORK=.*|EXISTING_NETWORK=coding-practice-platform_default|' .env
	@cd deployment && sed -i 's|ORIGIN_URL=.*|ORIGIN_URL=http://frontend:3000|' .env
	@cd deployment && docker rm -f coding-practice-tunnel >/dev/null 2>&1 || true
	@cd deployment && docker compose -f docker-compose.tunnel-only.yml --env-file .env up -d
	@echo "✓ Tunnel started. Run: make tunnel-logs"

tunnel-down:
	@cd deployment && docker compose -f docker-compose.tunnel-only.yml --env-file .env down
	@echo "✓ Tunnel stopped"

tunnel-logs:
	@cd deployment && docker compose -f docker-compose.tunnel-only.yml --env-file .env logs -f tunnel

# View logs
logs:
	@echo "=== Scoring API ===" && tail -20 /tmp/scoring-api.log 2>/dev/null || true
	@echo "\n=== Frontend ===" && tail -10 /tmp/frontend.log 2>/dev/null || true

logs-api:
	@tail -f /tmp/scoring-api.log

logs-piston:
	@docker logs -f piston_api

# Check status
status:
	@echo "Services:"
	@curl -s http://localhost:2000/api/v2/runtimes > /dev/null && echo "  Piston:      ✓ running" || echo "  Piston:      ✗ stopped"
	@curl -s http://localhost:3001/health > /dev/null && echo "  Scoring API: ✓ running" || echo "  Scoring API: ✗ stopped"
	@curl -s http://localhost:3000 > /dev/null && echo "  Frontend:    ✓ running" || echo "  Frontend:    ✗ stopped"

# Install dependencies
install:
	@echo "Installing dependencies..."
	@cd scoring-api && npm install
	@cd piston-setup && mkdir -p data/piston/packages
	@cd piston-setup/cli && npm install
	@echo "✓ Dependencies installed"

# Install language runtimes
install-langs:
	@echo "Installing language runtimes..."
	@cd piston-setup && node cli/index.js ppman install python java gcc node
	@echo "✓ Languages installed"

# Clean up
clean: stop
	@rm -f /tmp/scoring-api.log /tmp/frontend.log
	@echo "✓ Cleaned"

# Help
help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  start         Start all services"
	@echo "  stop          Stop all services"
	@echo "  restart       Restart all services"
	@echo "  status        Check service status"
	@echo "  logs          View recent logs"
	@echo "  logs-api      Follow API logs"
	@echo "  logs-piston   Follow Piston logs"
	@echo "  install       Install dependencies"
	@echo "  install-langs Install language runtimes"
	@echo "  clean         Stop and clean up"
