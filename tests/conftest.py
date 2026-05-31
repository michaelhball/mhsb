import pytest

from app import create_app
from app.config import Config


class _TestConfig(Config):
    TESTING = True
    SECRET_KEY = "test-secret"


@pytest.fixture
def app():
    return create_app(_TestConfig)


@pytest.fixture
def client(app):
    return app.test_client()
