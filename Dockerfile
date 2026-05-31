# syntax=docker/dockerfile:1

# --- Stage 1: compile SCSS -> compiled.css with Dart Sass ---------------------
FROM node:22-slim AS assets
WORKDIR /build
COPY app/static/scss ./scss
RUN npx --yes sass@1.100.0 scss/main.scss compiled.css --no-source-map --style=compressed

# --- Stage 2: runtime ---------------------------------------------------------
FROM python:3.13-slim AS runtime

# Bring in the uv binary for fast, reproducible installs.
COPY --from=ghcr.io/astral-sh/uv:0.11 /uv /uvx /bin/

ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PATH="/app/.venv/bin:$PATH" \
    PYTHONPATH=/app

WORKDIR /app

# Install runtime dependencies from the lockfile (no dev deps).
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev

# Application source.
COPY . .

# Prebuilt CSS from the assets stage (no Sass/libsass needed at runtime).
COPY --from=assets /build/compiled.css app/static/styles/compiled.css

# Run as a non-root user.
RUN useradd --create-home --uid 1000 appuser && chown -R appuser:appuser /app
USER appuser

EXPOSE 8080

# Cloud Run injects $PORT (8080). gunicorn must bind 0.0.0.0 and honour it.
CMD ["sh", "-c", "exec gunicorn --bind 0.0.0.0:${PORT:-8080} --workers 2 --threads 4 --timeout 30 mhsb:app"]
