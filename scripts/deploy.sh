#!/usr/bin/env bash
# Deploy mhsb to Google Cloud Run. Mirrors DEVELOPMENT.md §8, with a guardrail
# against deploying this PERSONAL site into a WORK GCP account/project.
#
# One-time, interactive (run yourself as your PERSONAL Google account):
#   gcloud auth login
#
# Then:
#   PROJECT_ID=mhsb-prod ./scripts/deploy.sh
#
# Env vars:
#   PROJECT_ID     (required) target GCP project id (must be a PERSONAL project)
#   REGION         (default europe-west1 — domain-mapping eligible)
#   SERVICE        (default mhsb)
#   MIN_INSTANCES  (default 0 — scale to zero, ~$0/mo, ~1-3s cold start)
#   MAX_INSTANCES  (default 2)
#   SECRET_NAME    (default flask-secret-key)
#   ALLOW_WORK_ACCOUNT=1  override the work-account guardrail (don't)
set -euo pipefail
cd "$(dirname "$0")/.."

PROJECT_ID="${PROJECT_ID:?set PROJECT_ID to your personal GCP project id}"
REGION="${REGION:-europe-west1}"
SERVICE="${SERVICE:-mhsb}"
MIN_INSTANCES="${MIN_INSTANCES:-0}"
MAX_INSTANCES="${MAX_INSTANCES:-2}"
SECRET_NAME="${SECRET_NAME:-flask-secret-key}"

# --- Guardrail: never deploy a personal site from a work account -------------
ACCOUNT="$(gcloud auth list --filter=status:ACTIVE --format='value(account)' 2>/dev/null || true)"
echo "Active gcloud account : ${ACCOUNT:-<none>}"
echo "Target project        : $PROJECT_ID"
echo "Region / service      : $REGION / $SERVICE"
echo "Scaling               : min=$MIN_INSTANCES max=$MAX_INSTANCES"
if [[ -z "${ACCOUNT:-}" ]]; then
  echo "ERROR: no active gcloud account. Run: gcloud auth login" >&2
  exit 1
fi
if [[ "$ACCOUNT" == *merantix.com || "$ACCOUNT" == *vara.ai ]] && [[ "${ALLOW_WORK_ACCOUNT:-}" != "1" ]]; then
  echo "ERROR: active account '$ACCOUNT' looks like a WORK account." >&2
  echo "mhsb.me is a personal site. Run 'gcloud auth login' (or" >&2
  echo "'gcloud config set account <you>@gmail.com') with your personal" >&2
  echo "account, or set ALLOW_WORK_ACCOUNT=1 to override (you almost never want to)." >&2
  exit 1
fi
read -r -p "Deploy to '$PROJECT_ID' as '$ACCOUNT'? [y/N] " ok
[[ "$ok" == [yY] ]] || { echo "Aborted."; exit 1; }

# --- 1. Project setup + required APIs ----------------------------------------
gcloud config set project "$PROJECT_ID"
gcloud config set run/region "$REGION"
gcloud services enable \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  artifactregistry.googleapis.com \
  secretmanager.googleapis.com \
  cloudresourcemanager.googleapis.com

# Default compute service account — used by Cloud Build (for --source deploys)
# and as the Cloud Run runtime identity.
PROJECT_NUMBER="$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')"
COMPUTE_SA="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"

# On newer projects the default compute SA lacks Cloud Build permissions, so a
# --source deploy can't read the staged source or push the image. Grant the
# build-builder role (idempotent).
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${COMPUTE_SA}" \
  --role="roles/cloudbuild.builds.builder" >/dev/null
echo "Granted cloudbuild.builds.builder to ${COMPUTE_SA}."

# --- 2. Production SECRET_KEY in Secret Manager (idempotent) ------------------
if ! gcloud secrets describe "$SECRET_NAME" >/dev/null 2>&1; then
  echo "Creating secret '$SECRET_NAME' ..."
  python3 -c "import secrets; print(secrets.token_hex(32))" \
    | gcloud secrets create "$SECRET_NAME" --data-file=-
else
  echo "Secret '$SECRET_NAME' already exists — leaving its value untouched."
fi
gcloud secrets add-iam-policy-binding "$SECRET_NAME" \
  --member="serviceAccount:${COMPUTE_SA}" \
  --role="roles/secretmanager.secretAccessor" >/dev/null
echo "Granted secretAccessor on '$SECRET_NAME' to the default compute service account."

# --- 3. Deploy (Cloud Build builds the repo Dockerfile; no local Docker) -----
gcloud run deploy "$SERVICE" \
  --source=. \
  --allow-unauthenticated \
  --port=8080 \
  --cpu=1 --memory=512Mi \
  --min-instances="$MIN_INSTANCES" --max-instances="$MAX_INSTANCES" \
  --set-secrets="SECRET_KEY=${SECRET_NAME}:latest"

# --- 4. Smoke test -----------------------------------------------------------
URL="$(gcloud run services describe "$SERVICE" --format='value(status.url)')"
echo "Service URL: $URL"
curl -sf "$URL/"      >/dev/null && echo "home  OK"
curl -sf "$URL/music" >/dev/null && echo "music OK"

echo
echo "Deployed. DNS cutover for mhsb.me (GoDaddy) is a separate manual step —"
echo "do it only after the URL above checks out. See DEVELOPMENT.md §8."
