"""WSGI entry point: ``flask --app mhsb run`` and ``gunicorn mhsb:app``."""

from app import create_app

app = create_app()
