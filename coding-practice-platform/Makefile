.PHONY: start stop restart logs status install clean

# Start all services
start: start-piston start-api start-frontend
	@echo "\n✓ Platform running at http://localhost:3000"
	@echo "  VS Code Proxy: http://<host>:8081/proxy/3000/\n"

start-piston:
	@echo "[1/3] Starting Piston..."
	@cd piston-setup && docker compose up -d 2>/dev/null

start-api:
	@echo "[2/3] Starting Scoring API..."
	@pkill -f "node src/server.js" 2>/dev/null || true
	@cd scoring-api && PISTON_URL=http://localhost:2000 nohup npm start > /tmp/scoring-api.log 2>&1 &
	@sleep 2

start-frontend:
	@echo "[3/3] Starting Frontend..."
	@lsof -ti :3000 | xargs kill -9 2>/dev/null || true
	@cd frontend && nohup python3 -m http.server 3000 > /tmp/frontend.log 2>&1 &
	@sleep 1

# Stop all services
stop:
	@echo "Stopping services..."
	@pkill -f "node src/server.js" 2>/dev/null || true
	@lsof -ti :3000 | xargs kill -9 2>/dev/null || true
	@cd piston-setup && docker compose down 2>/dev/null || true
	@echo "✓ Stopped"

# Restart all services
restart: stop start

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
