# CLAUDE.md

Guidance for AI agents (and humans) working in this repo. For full setup and
deployment, see [DEVELOPMENT.md](DEVELOPMENT.md).

## What this is

A small, server-rendered Flask personal site (mhsb.me) — no database, no JS
framework. `create_app()` in `app/__init__.py` builds the app; routes are in a
single `main` blueprint (`app/routes.py`); page content (the SoundCloud mixes)
is a Python list in `app/music.py`; views are Jinja templates in
`app/templates/`; styling is SCSS compiled to CSS by Dart Sass.

## Commands

```bash
uv sync                                    # install deps (Python 3.13)
uv run flask --app mhsb run --debug        # dev server (http://127.0.0.1:5000)
./scripts/build_css.sh                     # compile SCSS -> compiled.css (needs Dart Sass)
uv run pytest                              # tests
uv run ruff check . && uv run ruff format  # lint + format
```

## Key files

| Path | Role |
|------|------|
| `mhsb.py` | WSGI entry: `app = create_app()` (`gunicorn mhsb:app`) |
| `app/__init__.py` | `create_app()` factory; error handlers; security headers |
| `app/routes.py` | the `main` blueprint — all routes |
| `app/music.py` | `MIXES` — site content |
| `app/config.py` | config; `SECRET_KEY` from env |
| `app/static/scss/` | `@use` modules + `main.scss` entry |
| `Dockerfile` | Cloud Run image (Dart Sass build + gunicorn) |
| `scripts/deploy.sh` | manual Cloud Run deploy (`gcloud run deploy --source=.`, upsert) |
| `scripts/setup_cicd.sh` | one-time WIF identity setup for CI auto-deploy |
| `.github/workflows/ci.yml` | CI (`check`) + auto-deploy (`deploy`, on push to `main`) |

## Conventions

- **uv** for everything; `uv.lock` is committed. Runtime deps are minimal
  (Flask, python-dotenv, gunicorn); dev tools live in the `dev` group.
- **ruff** lints and formats. Line length 120; rules `E,F,I,W,TID,UP,B`;
  **absolute imports only** (relative imports are banned); target `py313`.
- Tests are Flask test-client smoke tests in `tests/` (run via `uv run pytest`).

## Gotchas

- **`app/static/styles/compiled.css` is generated and gitignored** — never edit
  or commit it. Rebuild from SCSS with `./scripts/build_css.sh` (or
  `sass --watch …`). A fresh clone has no CSS until built; Dart Sass must be
  installed.
- **`.flaskenv` is gitignored** — run with `flask --app mhsb run --debug`, or
  recreate it (see DEVELOPMENT.md).
- Footer icons are **inline SVGs** (Font Awesome Free); there is no Font Awesome
  dependency. `app/static/styles/home.css` is a separate hand-written file; its
  `.cv-button::before` uses an inline data-URI SVG (a download icon shown on
  hover) — no web font involved.
- **projects / movies / blog** nav items are intentionally disabled; no routes.
- `SECRET_KEY` has an insecure dev default; production supplies it via the
  environment / Secret Manager (the app warns otherwise).
- The GitHub repo is `michaelhball/mhsb`; the local working directory is
  `mhsb2`. Same project.
- **Deployed on Google Cloud Run** (project `mhsb-prod`, region `europe-west1`,
  service `mhsb`) via the `Dockerfile` (gunicorn `mhsb:app`, bound to
  `0.0.0.0:$PORT`). Pushes to `main` auto-deploy through the `deploy` job in
  `.github/workflows/ci.yml` (keyless Workload Identity Federation); manual
  deploys / rollbacks use `./scripts/deploy.sh`. `mhsb.me` is mapped to the
  service (DNS cut over from PythonAnywhere). See [DEVELOPMENT.md](DEVELOPMENT.md) §8.
