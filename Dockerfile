# ============================================================
# Dockerfile - IC GROUP Web Vitrine
# Image : ic-webapp:1.0
# ============================================================

# 1) Image de base
FROM python:3.6-alpine

# 2) Répertoire de travail
WORKDIR /opt

# 3) Copier les fichiers de l'application
COPY app.py .
COPY templates/ templates/
COPY static/ static/

# 4) Installer Flask 1.1.2
RUN pip install flask==1.1.2

# 5) Variables d'environnement (URLs des applications internes)
ENV ODOO_URL=""
ENV PGADMIN_URL=""

# 6) Exposer le port utilisé par l'application
EXPOSE 8080

# 7) Lancer l'application
ENTRYPOINT ["python", "app.py"]
