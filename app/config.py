import os


class Config:
    SECRET_KEY = os.getenv("SECRET_KEY", default="devilously devious")  # TODO: prod ...

    ASSETS_DEBUG = True
