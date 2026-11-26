FROM python:3.12-slim

WORKDIR /app

# Dependances (couche mise en cache tant que requirements.txt ne change pas)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Code de l'application + page HTML/CSS
COPY . .

# Version affichee dans /health et dans les metriques (passee par le pipeline)
ARG APP_VERSION=dev
ENV APP_VERSION=${APP_VERSION}

# Utilisateur non root
RUN useradd --create-home appuser
USER appuser

EXPOSE 8000
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "1", "--threads", "4", "app:app"]
