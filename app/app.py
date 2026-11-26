"""Application web en Python (Flask).

Elle sert la page de presentation (index.html + style.css, inchanges) et publie
ses propres metriques pour Prometheus sur /metrics.
"""
import os
import socket
import time

from flask import Flask, Response, g, request, send_from_directory
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Gauge, Histogram, generate_latest

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
VERSION = os.environ.get("APP_VERSION", "dev")
POD = socket.gethostname()   # dans Kubernetes : le nom du pod

app = Flask(__name__)

# ------------------------------------------------------------------ metriques
VISITES = Counter("app_visites_total", "Nombre de visites de la page d'accueil")
REQUETES = Counter("app_requetes_total", "Requetes HTTP recues", ["route", "code"])
DUREE = Histogram("app_duree_requete_secondes", "Temps de traitement des requetes", ["route"],
                  buckets=(0.001, 0.0025, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1))
INFO = Gauge("app_info", "Version de l'application deployee", ["version", "pod"])
INFO.labels(version=VERSION, pod=POD).set(1)


@app.before_request
def _debut():
    g.debut = time.perf_counter()


@app.after_request
def _fin(response):
    route = request.url_rule.rule if request.url_rule else "inconnue"
    if route != "/metrics":
        DUREE.labels(route=route).observe(time.perf_counter() - g.debut)
        REQUETES.labels(route=route, code=str(response.status_code)).inc()
    return response


# ------------------------------------------------------------------ routes
@app.route("/")
def accueil():
    VISITES.inc()
    return send_from_directory(BASE_DIR, "index.html")   # la page, telle quelle


@app.route("/style.css")
def style():
    return send_from_directory(BASE_DIR, "style.css")


@app.route("/health")
def health():
    """Utilisee par Kubernetes pour savoir si l'application est prete."""
    return {"status": "ok", "version": VERSION, "pod": POD}


@app.route("/metrics")
def metrics():
    """Lue par Prometheus toutes les 15 secondes."""
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000)
