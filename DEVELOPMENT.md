# Development & deployment

How to work on this project from a fresh machine, and how to deploy it to
Google Cloud Run.

## 1. Prerequisites

| Tool | Why | Install |
|------|-----|---------|
| [git](https://git-scm.com/) | clone the repo | — |
| [uv](https://docs.astral.sh/uv/) | Python, venv & dependency management | `curl -LsSf https://astral.sh/uv/install.sh \| sh` |
| [Dart Sass](https://sass-lang.com/dart-sass/) | compile SCSS → CSS | `brew install sass/sass/sass` or `npm install -g sass` |
| [`gcloud`](https://cloud.google.com/sdk/docs/install) | deploy (only if deploying) | per-OS installer |

uv installs the correct Python (3.13, pinned in `.python-version`) for you — no
system Python required. `scripts/build_css.sh` uses the `sass` binary if it's
installed and otherwise falls back to `npx sass`, so **either Dart Sass or
Node** is enough to build the CSS.

## 2. Clone & install

```bash
git clone git@github.com:michaelhball/mhsb.git    # or: https://github.com/michaelhball/mhsb.git
cd mhsb
uv sync            # creates .venv and installs everything from uv.lock (incl. Python 3.13)
```

## 3. Environment & config

There are **no required environment variables for local development.** Two
things worth knowing:

- **`.flaskenv` is gitignored**, so a fresh clone won't have it. Either pass the
  flags on the command line (see below), or recreate it:

  ```ini
  # .flaskenv
  FLASK_APP=mhsb.py
  FLASK_DEBUG=1
  ```

- **`SECRET_KEY`** is read from the environment (`app/config.py`). Locally it
  falls back to an insecure dev default; in production you **must** set it (see
  §8). The app logs a warning if the default is used outside debug mode.

## 4. Run locally

The CSS is compiled, not committed, so build it before the app will look
styled. Keep Dart Sass watching in one terminal:

```bash
sass --watch app/static/scss/main.scss:app/static/styles/compiled.css
```

…or build it once with `./scripts/build_css.sh`. Then run the app:

```bash
uv run flask --app mhsb run --debug            # http://127.0.0.1:5000
# or, if you created .flaskenv:   uv run flask run
# choose a port:                  uv run flask --app mhsb run --debug -p 5001
```

## 5. How styling works

- SCSS lives in `app/static/scss/`. **`main.scss`** is the entry point; it
  `@use`s `_base`, `_footer`, `_mixes`, `_nav`, which in turn pull in `_vars`
  (`@use 'vars' as *`).
- Dart Sass compiles `main.scss` → `app/static/styles/compiled.css`, which
  `base.html` links directly. `compiled.css` is generated and **gitignored**.
- `app/static/styles/home.css` is a separate, hand-written stylesheet linked
  only by `home.html` (it is not part of the SCSS bundle).
- Footer icons are inline SVGs (Font Awesome Free) — there is no Font Awesome
  dependency or web font to load.

## 6. Editing content

- **Add a mix:** append an entry to `MIXES` in `app/music.py`:
  - `id` — the SoundCloud track id, from the track's *Share → Embed* code (the
    number in `api.soundcloud.com/tracks/<id>`).
  - `color` — a hex colour without `#` for the embedded player (e.g. sample the
    artwork with macOS Digital Colour Meter).
  - `image_url` — add the artwork to `app/static/images/` and point to it.
  - `tags` — a few lowercase tags (the music page filters by up to two).
- The **projects / movies / blog** nav items are intentionally disabled —
  greyed out and non-clickable via the `disabled` class; there are no routes
  behind them.

## 7. Quality checks

```bash
uv run ruff check .          # lint
uv run ruff format .         # format
uv run pytest                # tests
uv run pre-commit install    # enable git hooks (run once)
```

CI (`.github/workflows/ci.yml`) runs the same checks on every push and PR.

## 8. Deploy to Google Cloud Run

The app is containerised (`Dockerfile`) and served by gunicorn. Deploys are
manual via `gcloud`; the live site only changes when you deploy and switch DNS.

### One-time project setup

```bash
gcloud auth login
export PROJECT_ID=mhsb-prod          # your GCP project id
export REGION=europe-west1           # a domain-mapping-eligible region
gcloud config set project "$PROJECT_ID"
gcloud config set run/region "$REGION"
gcloud services enable run.googleapis.com cloudbuild.googleapis.com \
  artifactregistry.googleapis.com secretmanager.googleapis.com
```

### Store the production SECRET_KEY in Secret Manager

```bash
python3 -c "import secrets; print(secrets.token_hex(32))" | \
  gcloud secrets create flask-secret-key --data-file=-
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')
gcloud secrets add-iam-policy-binding flask-secret-key \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
```

### Deploy

```bash
gcloud run deploy mhsb \
  --source=. \
  --allow-unauthenticated \
  --port=8080 \
  --cpu=1 --memory=512Mi \
  --min-instances=0 --max-instances=2 \
  --set-secrets=SECRET_KEY=flask-secret-key:latest
```

`--source=.` builds the repo's `Dockerfile` with Cloud Build (no local Docker
needed) and rolls out a revision, printing a `*.run.app` URL. Smoke-test it:

```bash
URL=$(gcloud run services describe mhsb --format='value(status.url)')
curl -sf "$URL/" >/dev/null && echo "home OK"
curl -sf "$URL/music" >/dev/null && echo "music OK"
```

`--min-instances=0` scales to zero (≈ $0/month; the first request after idle
pays a ~1–3s cold start). For an always-warm instance (≈ $1–2/month):

```bash
gcloud run services update mhsb --min-instances=1
```

### Point mhsb.me (GoDaddy) at Cloud Run

Do this **after** the `*.run.app` URL works, to avoid downtime.

1. Verify ownership and create the domain mappings:

   ```bash
   gcloud domains verify mhsb.me
   gcloud beta run domain-mappings create --service=mhsb --domain=mhsb.me
   gcloud beta run domain-mappings create --service=mhsb --domain=www.mhsb.me
   ```

2. Get the exact DNS records Google wants:

   ```bash
   gcloud beta run domain-mappings describe --domain=mhsb.me \
     --format='value(status.resourceRecords)'
   ```

   For an **apex** domain (`mhsb.me`) these are four `A` records and four `AAAA`
   records — apex domains can't use a CNAME. They are Google's IPs, typically:

   - `A`: `216.239.32.21`, `216.239.34.21`, `216.239.36.21`, `216.239.38.21`
   - `AAAA`: `2001:4860:4802:32::15`, `2001:4860:4802:34::15`,
     `2001:4860:4802:36::15`, `2001:4860:4802:38::15`

   For `www.mhsb.me` it's a single `CNAME` → `ghs.googlehosted.com.`
   **Use exactly what `describe` prints** — don't assume the values above.

3. In **GoDaddy** → *My Products* → `mhsb.me` → **DNS** → *Manage DNS*:
   - **Remove** the records currently pointing the site at PythonAnywhere (the
     apex `A` record and the `www` record).
   - **Add** each `A` record: Type `A`, Name `@`, Value = a Google IP (four
     records). Default TTL (1 hour) is fine.
   - **Add** each `AAAA` record: Type `AAAA`, Name `@`, Value = a Google IPv6.
   - **Add** the `www` record: Type `CNAME`, Name `www`, Value
     `ghs.googlehosted.com.`
   - Ensure GoDaddy domain **Forwarding** is off — it can override these.

4. Wait for DNS to propagate (minutes to a few hours). Google then
   auto-provisions a managed TLS certificate and `https://mhsb.me` goes live.
   Track progress with the `describe` command above.

Once mhsb.me serves from Cloud Run, you can retire the PythonAnywhere app.

### Updating the deployed site

Re-run `gcloud run deploy mhsb --source=. …`. This can later be automated with a
GitHub Actions deploy job using
[Workload Identity Federation](https://github.com/google-github-actions/auth);
it's left manual for now since it needs GCP-side setup (a service account +
identity pool) that can't be scripted from the repo alone.
