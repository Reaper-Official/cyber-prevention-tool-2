# 🛠️ Scripts Utilitaires PhishGuard

Ce dossier contient tous les scripts pour gérer PhishGuard facilement.

## 📋 Liste des scripts

### 🚀 Gestion de l'application

| Script | Description | Usage |
|--------|-------------|-------|
| `start.sh` | Démarrer l'application | `./scripts/start.sh` |
| `stop.sh` | Arrêter l'application | `./scripts/stop.sh` |
| `logs.sh` | Afficher les logs | `./scripts/logs.sh` |
| `health-check.sh` | Vérifier la santé du système | `./scripts/health-check.sh` |

### 💾 Backup & Restauration

| Script | Description | Usage |
|--------|-------------|-------|
| `backup.sh` | Sauvegarder la base de données | `./scripts/backup.sh` |
| `restore.sh` | Restaurer depuis un backup | `./scripts/restore.sh` |

### 🤖 IA & Tests

| Script | Description | Usage |
|--------|-------------|-------|
| `test-ai.sh` | Tester les providers IA | `./scripts/test-ai.sh` |

### 🛠️ Développement

| Script | Description | Usage |
|--------|-------------|-------|
| `setup-dev.sh` | Configurer l'environnement dev | `./scripts/setup-dev.sh` |

### 🧹 Maintenance

| Script | Description | Usage |
|--------|-------------|-------|
| `clean.sh` | Nettoyer complètement | `./scripts/clean.sh` |
| `update.sh` | Mettre à jour l'application | `./scripts/update.sh` |

## 🚀 Exemples d'utilisation

### Démarrage rapide
```bash
./scripts/start.sh
```

### Voir les logs en temps réel
```bash
./scripts/logs.sh --follow
./scripts/logs.sh --service backend
```

### Backup automatique
```bash
# Backup simple
./scripts/backup.sh

# Backup dans cron (tous les jours à 2h)
0 2 * * * cd /opt/phishguard && ./scripts/backup.sh
```

### Test des providers IA
```bash
./scripts/test-ai.sh
```

### Vérification de santé
```bash
# Check manuel
./scripts/health-check.sh

# En monitoring (chaque minute)
watch -n 60 ./scripts/health-check.sh
```

### Arrêt avec suppression des données
```bash
./scripts/stop.sh --volumes
```

### Nettoyage complet
```bash
./scripts/clean.sh
```

### Mise à jour
```bash
./scripts/update.sh
```

## 🔧 Configuration

### Variables d'environnement

Les scripts utilisent les variables du fichier `.env` :

```env
POSTGRES_USER=phishguard
POSTGRES_PASSWORD=xxx
POSTGRES_DB=phishguard
```

### Personnalisation

Vous pouvez modifier les variables en haut de chaque script :

```bash
# Exemple dans backup.sh
BACKUP_DIR="./backups"          # Dossier de backup
DB_CONTAINER="phishguard-postgres"  # Nom du conteneur
```

## 📊 Automatisation

### Backup automatique (cron)

```bash
# Éditer le crontab
crontab -e

# Ajouter ces lignes
# Backup tous les jours à 2h du matin
0 2 * * * cd /opt/phishguard && ./scripts/backup.sh >> /var/log/phishguard-backup.log 2>&1

# Health check toutes les heures
0 * * * * cd /opt/phishguard && ./scripts/health-check.sh >> /var/log/phishguard-health.log 2>&1
```

### Monitoring avec systemd

Créer un service de monitoring :

```bash
# /etc/systemd/system/phishguard-monitor.service
[Unit]
Description=PhishGuard Health Monitor
After=docker.service

[Service]
Type=oneshot
ExecStart=/opt/phishguard/scripts/health-check.sh
StandardOutput=journal

[Install]
WantedBy=multi-user.target
```

```bash
# /etc/systemd/system/phishguard-monitor.timer
[Unit]
Description=Run PhishGuard Health Check every 5 minutes

[Timer]
OnBootSec=5min
OnUnitActiveSec=5min

[Install]
WantedBy=timers.target
```

Activer :
```bash
sudo systemctl enable phishguard-monitor.timer
sudo systemctl start phishguard-monitor.timer
```

## 🐛 Dépannage

### Script ne s'exécute pas

```bash
# Vérifier les permissions
chmod +x scripts/*.sh

# Vérifier la syntaxe
bash -n scripts/start.sh
```

### Erreur "command not found"

Assurez-vous d'être dans le répertoire racine du projet :

```bash
cd /opt/phishguard
./scripts/start.sh
```

### Problème de connexion Docker

```bash
# Vérifier Docker
sudo systemctl status docker

# Ajouter l'utilisateur au groupe docker
sudo usermod -aG docker $USER
newgrp docker
```

## 📝 Notes

- Tous les scripts utilisent `set -e` pour arrêter en cas d'erreur
- Les backups sont automatiquement compressés (.gz)
- Les logs sont colorés pour meilleure lisibilité
- Les anciens backups (>7 jours) sont automatiquement supprimés

## 🔗 Liens utiles

- [Documentation principale](../README.md)
- [Configuration IA](../docs/ai-config.md)
- [Troubleshooting](../docs/troubleshooting.md)

---

**💡 Astuce** : Ajoutez `alias pg='cd /opt/phishguard && ./scripts'` dans votre `~/.bashrc` pour un accès rapide !
