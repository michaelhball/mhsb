"""Flask configuration.

In production (e.g. Cloud Run) set ``SECRET_KEY`` via the environment /
Secret Manager. The fallback below is for local development only.
"""

import os

DEV_SECRET_KEY = "dev-insecure-change-me"


class Config:
    SECRET_KEY = os.environ.get("SECRET_KEY", DEV_SECRET_KEY)
