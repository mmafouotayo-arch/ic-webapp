#!/bin/bash
# ============================================================
# build_and_test.sh - IC GROUP Web Vitrine
# Usage : bash build_and_test.sh [dockerhub_username]
# ============================================================

set -e

IMAGE_NAME="ic-webapp"
TAG="1.0"
CONTAINER_NAME="test-ic-webapp"
DOCKERHUB_USER="${1:-votre_username}"
PORT="8888"   # Port local (alternatif à 8080 si déjà occupé)

ODOO_URL=$(awk '/ODOO_URL/ {print $2}' releases.txt)
PGADMIN_URL=$(awk '/PGADMIN_URL/ {print $2}' releases.txt)
VERSION=$(awk '/version/ {print $2}' releases.txt)

echo "========================================"
echo " IC GROUP - Build & Test Docker Image"
echo "========================================"
echo " Image      : $IMAGE_NAME:$TAG"
echo " ODOO_URL   : $ODOO_URL"
echo " PGADMIN_URL: $PGADMIN_URL"
echo " Version    : $VERSION"
echo " Port local : $PORT -> 8080 (interne)"
echo "========================================"

# Nettoyage préalable
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo ""
  echo "⚠️  Container existant détecté, suppression..."
  docker rm -f ${CONTAINER_NAME}
fi

# 1) BUILD
echo ""
echo "[1/4] Build de l'image..."
docker build -t ${IMAGE_NAME}:${TAG} .
echo "   ✅ Image buildée : ${IMAGE_NAME}:${TAG}"

# 2) Lancer le container de test
echo ""
echo "[2/4] Lancement du container de test..."
docker run -d \
  --name ${CONTAINER_NAME} \
  -p ${PORT}:8080 \
  -e ODOO_URL=${ODOO_URL} \
  -e PGADMIN_URL=${PGADMIN_URL} \
  ${IMAGE_NAME}:${TAG}

echo "   Attente du démarrage (5s)..."
sleep 5

# 3) Test HTTP
echo ""
echo "[3/4] Test de disponibilité (http://localhost:${PORT})..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:${PORT})

if [ "$HTTP_CODE" == "200" ]; then
  echo "   ✅ Succès ! Code HTTP : $HTTP_CODE"
  echo "   🌐 Ouvrez : http://localhost:${PORT}"
else
  echo "   ❌ Échec ! Code HTTP reçu : $HTTP_CODE"
  docker logs ${CONTAINER_NAME}
  docker rm -f ${CONTAINER_NAME}
  exit 1
fi

# Suppression container de test
echo ""
echo "   Suppression du container de test..."
docker rm -f ${CONTAINER_NAME}
echo "   ✅ Container supprimé"

# 4) Push Docker Hub
echo ""
echo "[4/4] Push vers Docker Hub..."
docker tag ${IMAGE_NAME}:${TAG} ${DOCKERHUB_USER}/${IMAGE_NAME}:${TAG}
docker push ${DOCKERHUB_USER}/${IMAGE_NAME}:${TAG}

echo ""
echo "========================================"
echo " ✅ Pipeline terminé avec succès !"
echo "    https://hub.docker.com/r/${DOCKERHUB_USER}/${IMAGE_NAME}"
echo "========================================"
