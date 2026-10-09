#!/bin/bash
set -e

echo "=== 1. Construction de l'image de l'API ==="
docker build -t demo-api:1.0 ./api

echo -e "\n=== 2. Création du réseau et du volume ==="
docker network create demo_net || true
docker volume create demo_pgdata

echo -e "\n=== 3. Lancement de la base de données ==="
docker run -d --name demo-db \
  --network demo_net \
  -v demo_pgdata:/var/lib/postgresql/data \
  -v "$(pwd)/db/init.sql:/docker-entrypoint-initdb.d/init.sql:ro" \
  -e POSTGRES_USER=demo \
  -e POSTGRES_PASSWORD=demo \
  -e POSTGRES_DB=demo \
  postgres:16-alpine

echo -e "\n=== 4. Attente de la disponibilité de la base ==="
until docker exec demo-db pg_isready -U demo; do
  echo "En attente de PostgreSQL..."
  sleep 2
done
echo "PostgreSQL est prêt !"

echo -e "\n=== 5. Lancement de l'API ==="
docker run -d --name api \
  -p 8080:3000 \
  --network demo_net \
  -e PGHOST=demo-db \
  -e PGUSER=demo \
  -e PGPASSWORD=demo \
  -e PGDATABASE=demo \
  demo-api:1.0

echo "Attente du démarrage de l'API..."
sleep 3

echo -e "\n=== 6. Ajout d'un produit ==="
echo "Produits avant ajout :"
curl -s localhost:8080/products
echo -e "\n\nAjout de la casquette..."
curl -s -X POST -H 'content-type: application/json' \
  -d '{"name":"Casquette Démo","price_cents":1200}' localhost:8080/products

echo -e "\n\n=== 7. Suppression et recréation de la base de données ==="
docker rm -f demo-db

docker run -d --name demo-db \
  --network demo_net \
  -v demo_pgdata:/var/lib/postgresql/data \
  -v "$(pwd)/db/init.sql:/docker-entrypoint-initdb.d/init.sql:ro" \
  -e POSTGRES_USER=demo \
  -e POSTGRES_PASSWORD=demo \
  -e POSTGRES_DB=demo \
  postgres:16-alpine

echo "Attente du redémarrage de PostgreSQL..."
until docker exec demo-db pg_isready -U demo; do
  sleep 2
done

echo -e "\n=== 8. Vérification de la persistance ==="
echo "Produits après recréation de la base :"
curl -s localhost:8080/products

echo -e "\n\n=== 9. Vérification finale ==="
docker volume ls | grep demo_pgdata

echo -e "\n=== 10. Nettoyage ==="
docker rm -f api demo-db
docker network rm demo_net
# docker volume rm demo_pgdata
