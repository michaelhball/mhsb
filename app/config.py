"""Flask configuration.

In production (e.g. Cloud Run) set ``SECRET_KEY`` via the environment /
Secret Manager. The fallback below is for local development only.
"""

import os

DEV_SECRET_KEY = "dev-insecure-change-me"


class Config:
    SECRET_KEY = os.environ.get("SECRET_KEY", DEV_SECRET_KEY)
    # Flask-Assets: rebuild on change in dev, serve the prebuilt bundle in prod.
    ASSETS_DEBUG = bool(int(os.environ.get("FLASK_DEBUG") or "0"))
