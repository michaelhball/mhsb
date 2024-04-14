from flask import Flask
from flask_font_awesome import FontAwesome

from app.config import Config

app = Flask(__name__)
app.config.from_object(Config)

font_awesome = FontAwesome(app)

from app import routes  # noqa: E402, F401
