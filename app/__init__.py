from flask import Flask
from flask_assets import Bundle, Environment
from flask_font_awesome import FontAwesome

from app.config import Config

app = Flask(__name__)
app.config.from_object(Config)

font_awesome = FontAwesome(app)

# Flask-Assets setup to enable SCSS
assets = Environment(app)
scss_bundle = Bundle("scss/*.scss", output="styles/compiled.css", filters=["libsass"])
assets.register("scss_all", scss_bundle)
scss_bundle.build()

from app import routes  # noqa: E402, F401
