.PHONY: help start stop logs test clean

help:
	@echo "PhishGuard Multi-IA - Commandes:"
	@echo "  make start   - Démarrer"
	@echo "  make stop    - Arrêter"
	@echo "  make logs    - Voir les logs"
	@echo "  make test    - Test IA"
	@echo "  make clean   - Nettoyer"

start:
	docker-compose up -d
	@echo "✅ PhishGuard démarré: http://localhost:8080"

stop:
	docker-compose down

logs:
	docker-compose logs -f

test:
	@echo "🧪 Test des providers IA disponibles..."
	@curl -s http://localhost:3000/health || echo "❌ Backend non accessible"

clean:
	docker-compose down -v
	docker system prune -af
