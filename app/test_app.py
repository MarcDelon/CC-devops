"""Tests automatiques executes par la CI (Jenkins et GitHub Actions)."""
from app import app


def client():
    app.config["TESTING"] = True
    return app.test_client()


def test_page_accueil():
    r = client().get("/")
    assert r.status_code == 200
    assert b"</html>" in r.data


def test_feuille_de_style():
    r = client().get("/style.css")
    assert r.status_code == 200


def test_health():
    r = client().get("/health")
    assert r.status_code == 200
    assert r.get_json()["status"] == "ok"


def test_metrics_compte_les_visites():
    c = client()
    c.get("/")
    r = c.get("/metrics")
    assert r.status_code == 200
    assert b"app_visites_total" in r.data
