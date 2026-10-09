#!/bin/bash
set -e

echo "=== 1. Création des réseaux ==="
docker network create demo_front || true
docker network create demo_back || true

echo -e "\n=== 2. Lancement de la base (demo_back uniquement) ==="
docker run -d --name demo-db \
  --network demo_back \
  -v "$(pwd)/db/init.sql:/docker-entrypoint-initdb.d/init.sql:ro" \
  -e POSTGRES_USER=demo \
  -e POSTGRES_PASSWORD=demo \
  -e POSTGRES_DB=demo \
  postgres:16-alpine

echo -e "\n=== 3. Attente de la base de données ==="
until docker exec demo-db pg_isready -U demo; do
  sleep 2
done

echo -e "\n=== 4. Lancement de l'API (demo_front + demo_back) ==="
# On la lance sur demo_front
docker run -d --name demo-api \
  -p 8080:3000 \
  --network demo_front \
  -e PGHOST=demo-db \
  -e PGUSER=demo \
  -e PGPASSWORD=demo \
  -e PGDATABASE=demo \
  demo-api:1.0

# On la connecte AUSSI à demo_back pour qu'elle puisse joindre la DB
docker network connect demo_back demo-api

sleep 3

echo -e "\n=== 5. Vérification 1 : L'API joint la base ==="
docker exec demo-api getent hosts demo-db

echo -e "\n=== 6. Vérification 2 : Un conteneur tiers ne joint pas la base ==="
docker run --rm --network demo_front alpine sh -c 'nc -zv demo-db 5432 || echo "--> Echec de connexion attendu : isolement réussi !"' || true

echo -e "\n=== 7. Adresses IPv4 des conteneurs ==="
echo "demo-db :"
docker inspect -f '{{range $net, $conf := .NetworkSettings.Networks}}{{$net}}: {{$conf.IPAddress}}{{"\n"}}{{end}}' demo-db
echo "demo-api :"
docker inspect -f '{{range $net, $conf := .NetworkSettings.Networks}}{{$net}}: {{$conf.IPAddress}}{{"\n"}}{{end}}' demo-api

echo -e "\n=== 8. Vérification 3 : Appel API ==="
curl -s localhost:8080/products

echo -e "\n\n=== 9. Nettoyage ==="
docker rm -f demo-api demo-db
docker network rm demo_front demo_back
