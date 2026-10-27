# Demo API - Architecture Microservices & CD

Le fil rouge des quêtes Docker.

## Architecture
L'application se compose de 4 conteneurs interconnectés :
- **api** : API REST catalogue (Express, Node 22, image durcie multi-étapes).
- **notifier** : Microservice de notification (Express, Node 22, image durcie, écoute sur le réseau `back` uniquement).
- **db** : Base de données PostgreSQL 16 (persistance via volume nommé, secrets Docker).
- **adminer** : Interface web d'administration de la base.

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

## URLs & Ports
- API : http://localhost:8080
- Adminer : http://localhost:8081
- Notifier : joignable uniquement en interne par l'API sur `http://notifier:4000/notify`

## Vérification de l'état
```bash
$ docker compose ps
```

## Tester le microservice notifier
Ajouter un produit déclenche automatiquement une notification asynchrone (best-effort) vers le microservice `notifier` :
```bash
curl -s -X POST localhost:8080/products -H "Content-Type: application/json" -d '{"name":"Clavier meca","price_cents":5900}'
docker compose logs notifier | tail -5
```

## Comment repartir de zéro
Pour supprimer les conteneurs et effacer les données de la base (volumes), exécutez :
```bash
docker compose down -v
```
