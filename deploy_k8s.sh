#!/bin/bash
# ============================================================
# deploy_k8s.sh
# Déploiement complet de la stack IC GROUP sur Minikube
# Usage : bash deploy_k8s.sh
# ============================================================

set -e

echo "========================================"
echo " IC GROUP - Déploiement Kubernetes"
echo "========================================"

# Vérifier que minikube tourne
if ! minikube status | grep -q "Running"; then
  echo "⚠️  Minikube n'est pas démarré. Lancement..."
  minikube start
fi

MINIKUBE_IP=$(minikube ip)
echo " Minikube IP : $MINIKUBE_IP"
echo "========================================"

# 1) Namespace
echo ""
echo "[1/5] Création du namespace icgroup..."
kubectl apply -f k8s/namespace.yaml
echo "   ✅ Namespace créé"

# 2) Secrets
echo ""
echo "[2/5] Application des secrets..."
kubectl apply -f k8s/secret.yaml
echo "   ✅ Secrets créés"

# 3) PostgreSQL
echo ""
echo "[3/5] Déploiement PostgreSQL..."
kubectl apply -f k8s/odoo/postgres.yaml
echo "   ⏳ Attente démarrage PostgreSQL (20s)..."
sleep 20
kubectl wait --for=condition=ready pod -l app=postgres -n icgroup --timeout=120s
echo "   ✅ PostgreSQL prêt"

# 4) Odoo
echo ""
echo "[4/5] Déploiement Odoo..."
kubectl apply -f k8s/odoo/odoo.yaml
echo "   ⏳ Attente démarrage Odoo (30s)..."
sleep 30
kubectl wait --for=condition=ready pod -l app=odoo -n icgroup --timeout=180s
echo "   ✅ Odoo prêt"

# 5) pgAdmin
echo ""
echo "[5/5] Déploiement pgAdmin..."
kubectl apply -f k8s/pgadmin/pgadmin.yaml
kubectl wait --for=condition=ready pod -l app=pgadmin -n icgroup --timeout=120s
echo "   ✅ pgAdmin prêt"

# Site vitrine
echo ""
echo "[+] Déploiement Site Vitrine IC GROUP..."
kubectl apply -f k8s/ic-webapp/deployment.yaml
kubectl wait --for=condition=ready pod -l app=ic-webapp -n icgroup --timeout=120s
echo "   ✅ Site vitrine prêt"

# Résumé
echo ""
echo "========================================"
echo " ✅ Stack IC GROUP déployée avec succès !"
echo "========================================"
echo ""
echo " 🌐 URLs d'accès :"
echo "   Site vitrine : http://${MINIKUBE_IP}:30080"
echo "   Odoo         : http://${MINIKUBE_IP}:30069"
echo "   pgAdmin      : http://${MINIKUBE_IP}:30200"
echo ""
echo " 📋 État des pods :"
kubectl get pods -n icgroup
echo ""
echo " 📋 État des services :"
kubectl get services -n icgroup
echo "========================================"
