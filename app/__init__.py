"""Application factory for the mhsb personal website (mhsb.me)."""

from flask import Flask, render_template, Response

from app.config import Config, DEV_SECRET_KEY


def create_app(config: type[Config] = Config) -> Flask:
    app = Flask(__name__)
    app.config.from_object(config)

    if not app.debug and app.config["SECRET_KEY"] == DEV_SECRET_KEY:
        app.logger.warning("SECRET_KEY is the insecure development default; set SECRET_KEY in the environment.")

    from app.routes import bp

    app.register_blueprint(bp)
    _register_error_handlers(app)
    _register_security_headers(app)
    return app


def _register_error_handlers(app: Flask) -> None:
    @app.errorhandler(404)
    def not_found(error: Exception) -> tuple[str, int]:
        return render_template("404.html"), 404

    @app.errorhandler(500)
    def server_error(error: Exception) -> tuple[str, int]:
        return render_template("500.html"), 500


def _register_security_headers(app: Flask) -> None:
    @app.after_request
    def set_security_headers(response: Response) -> Response:
        response.headers.setdefault("X-Content-Type-Options", "nosniff")
        response.headers.setdefault("Referrer-Policy", "strict-origin-when-cross-origin")
        response.headers.setdefault("X-Frame-Options", "SAMEORIGIN")
        response.headers.setdefault("Strict-Transport-Security", "max-age=31536000; includeSubDomains")
        return response
