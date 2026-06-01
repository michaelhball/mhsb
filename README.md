# mhsb

My personal website & portfolio — live at **[mhsb.me](https://mhsb.me)**.

A small, server-rendered [Flask](https://flask.palletsprojects.com/) app: no
database, no JavaScript framework. Pages are Jinja templates; styling is SCSS
compiled to CSS with [Dart Sass](https://sass-lang.com/dart-sass/); the Python
environment and dependencies are managed with [uv](https://docs.astral.sh/uv/).
Containerised and deployed on Google Cloud Run; pushes to `main` auto-deploy via
GitHub Actions (see [DEVELOPMENT.md](DEVELOPMENT.md)).

## Quick start

```bash
uv sync                 # create .venv and install dependencies (Python 3.13)
./scripts/build_css.sh  # compile SCSS -> app/static/styles/compiled.css (uses Dart Sass, or npx)
uv run flask --app mhsb run --debug
```

Then open <http://127.0.0.1:5000>. While editing styles, run Dart Sass in watch
mode in another terminal:

```bash
sass --watch app/static/scss/main.scss:app/static/styles/compiled.css
```

See **[DEVELOPMENT.md](DEVELOPMENT.md)** for setup from a fresh machine, the
content/asset workflow, and the Google Cloud Run deploy + DNS runbook.

## Layout

| Path | What |
|------|------|
| `mhsb.py` | WSGI entry point (`gunicorn mhsb:app`) |
| `app/__init__.py` | `create_app()` application factory |
| `app/routes.py` | the `main` blueprint (all routes) |
| `app/music.py` | the list of SoundCloud mixes (site content) |
| `app/config.py` | configuration (env-driven `SECRET_KEY`) |
| `app/templates/` | Jinja templates |
| `app/static/scss/` | SCSS partials + `main.scss` entry point |
| `tests/` | pytest smoke tests |
| `Dockerfile` | Cloud Run image (Dart Sass build + gunicorn) |

## Checks

```bash
uv run pytest          # tests
uv run ruff check .    # lint
uv run ruff format .   # format
```

## License

[MIT](LICENSE)
