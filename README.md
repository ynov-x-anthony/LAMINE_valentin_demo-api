# Demo API - Docker Compose

Le fil rouge des quêtes Docker.

## Prérequis
- Docker et Docker Compose installés.

## Installation et lancement
1. Copier le fichier `.env.example` en `.env` (il contient les variables d'environnement non sensibles) :
   ```bash
   cp .env.example .env
   ```
2. Créer le dossier secrets et le fichier contenant le mot de passe de la base de données :
   ```bash
   mkdir -p secrets
   echo "mon_super_secret" > secrets/db_password.txt
   ```
3. Lancer la stack avec Docker Compose :
   ```bash
   docker compose up -d --build
   ```

## URLs
- API : http://localhost:8080
- Adminer : http://localhost:8081

## Vérification de l'état
```bash
$ docker compose ps
NAME                 IMAGE               COMMAND                  SERVICE   STATUS                    PORTS
demo-api-adminer-1   adminer:4           "entrypoint.sh doc..."   adminer   Up                        0.0.0.0:8081->8080/tcp
demo-api-api-1       demo-api-api        "docker-entrypoint..."   api       Up                        0.0.0.0:8080->3000/tcp
demo-api-db-1        postgres:16-alpine  "docker-entrypoint..."   db        Up (healthy)              5432/tcp
```

## Comment repartir de zéro
Pour supprimer les conteneurs et effacer les données de la base (volumes), exécutez :
```bash
docker compose down -v
```
