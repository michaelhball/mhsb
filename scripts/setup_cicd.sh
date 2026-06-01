#!/usr/bin/env bash
# scripts/setup_cicd.sh — ONE-TIME setup for keyless (Workload Identity Federation)
# auto-deploy of mhsb to Cloud Run from GitHub Actions. No service-account keys.
#
# Run this yourself, once, as your PERSONAL Google account with the personal
# gcloud config active:
#     gcloud config configurations activate mhsb
#     ./scripts/setup_cicd.sh
#
# It is safe to re-run — pool/provider/SA creation is guarded, grants are idempotent.
# When it finishes it prints two values; set them as GitHub repository VARIABLES
# (repo Settings -> Secrets and variables -> Actions -> Variables tab):
#     WIF_PROVIDER   DEPLOY_SA
# Then push the deploy workflow (.github/workflows/ci.yml) to main.
set -euo pipefail

PROJECT_ID="${PROJECT_ID:-mhsb-prod}"
REPO="${REPO:-michaelhball/mhsb}"           # owner/repo — scopes the per-repo binding
GITHUB_ORG="${GITHUB_ORG:-${REPO%%/*}}"     # repo owner — gates entry into the pool
POOL="${POOL:-github}"
PROVIDER="${PROVIDER:-mhsb}"
SA_NAME="${SA_NAME:-gh-deploy}"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

# Guardrail: this is a personal project — don't run it from a work account.
ACCOUNT="$(gcloud auth list --filter=status:ACTIVE --format='value(account)' 2>/dev/null || true)"
if [[ "$ACCOUNT" == *merantix.com || "$ACCOUNT" == *vara.ai ]] && [[ "${ALLOW_WORK_ACCOUNT:-}" != "1" ]]; then
  echo "ERROR: active account '$ACCOUNT' is a work account. Switch to your personal config:" >&2
  echo "       gcloud config configurations activate mhsb" >&2
  exit 1
fi

# Numeric project number — used verbatim in the provider resource name AND the
# principalSet. A PROJECT_ID substitution would make the binding silently never match.
PROJECT_NUMBER="$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')"
COMPUTE_SA="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"

echo "Account   : ${ACCOUNT:-<none>}"
echo "Project   : $PROJECT_ID ($PROJECT_NUMBER)"
echo "Repo      : $REPO   (org gate: $GITHUB_ORG)"
echo "Deploy SA : $SA_EMAIL"
echo

# 0) APIs that WIF + SA impersonation need.
gcloud services enable iamcredentials.googleapis.com sts.googleapis.com --project="$PROJECT_ID"

# 1) Workload Identity Pool (idempotent).
if ! gcloud iam workload-identity-pools describe "$POOL" \
      --project="$PROJECT_ID" --location=global >/dev/null 2>&1; then
  gcloud iam workload-identity-pools create "$POOL" \
    --project="$PROJECT_ID" --location=global --display-name="GitHub Actions Pool"
else echo "Pool '$POOL' already exists."; fi

# 2) GitHub OIDC provider — attribute-mapping + the MANDATORY attribute-condition
#    (CEL '=='), which pins the pool to your org so no other GitHub repo can enter.
if ! gcloud iam workload-identity-pools providers describe "$PROVIDER" \
      --project="$PROJECT_ID" --location=global --workload-identity-pool="$POOL" >/dev/null 2>&1; then
  gcloud iam workload-identity-pools providers create-oidc "$PROVIDER" \
    --project="$PROJECT_ID" --location=global --workload-identity-pool="$POOL" \
    --display-name="GitHub mhsb provider" \
    --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" \
    --attribute-condition="assertion.repository_owner == '${GITHUB_ORG}'" \
    --issuer-uri="https://token.actions.githubusercontent.com"
else echo "Provider '$PROVIDER' already exists."; fi

# 3) Dedicated deploy service account (idempotent).
if ! gcloud iam service-accounts describe "$SA_EMAIL" --project="$PROJECT_ID" >/dev/null 2>&1; then
  gcloud iam service-accounts create "$SA_NAME" \
    --project="$PROJECT_ID" --display-name="GitHub Actions deploy SA (mhsb)"
else echo "Service account '$SA_EMAIL' already exists."; fi

# 4) Least-privilege deploy roles (idempotent).
# 4a) Cloud Run deploy-from-source: bundles run.services.create/update, GCS source
#     staging upload, cloudbuild.builds.create, and run.services.setIamPolicy (for
#     --allow-unauthenticated). No run.admin / storage.* / cloudbuild.* needed.
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${SA_EMAIL}" --role="roles/run.sourceDeveloper" --condition=None >/dev/null
# 4b) actAs the runtime identity (the default Compute Engine SA) — granted ON THAT SA
#     resource, not project-wide.
gcloud iam service-accounts add-iam-policy-binding "$COMPUTE_SA" \
  --project="$PROJECT_ID" --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/iam.serviceAccountUser" --condition=None >/dev/null
# 4c) Optional but harmless — avoids serviceusage.services.use denials.
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${SA_EMAIL}" --role="roles/serviceusage.serviceUsageConsumer" --condition=None >/dev/null

# 5) Allow ONLY ${REPO} to impersonate the deploy SA (per-repo principalSet, using
#    attribute.repository/<owner/repo> and PROJECT_NUMBER).
gcloud iam service-accounts add-iam-policy-binding "$SA_EMAIL" \
  --project="$PROJECT_ID" --role="roles/iam.workloadIdentityUser" --condition=None \
  --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL}/attribute.repository/${REPO}" >/dev/null

# 6) Print the values for the GitHub repo Variables.
WIF_PROVIDER="$(gcloud iam workload-identity-pools providers describe "$PROVIDER" \
  --project="$PROJECT_ID" --location=global --workload-identity-pool="$POOL" --format='value(name)')"
echo
echo "================ Set these as GitHub repo Variables on ${REPO} ================"
echo "  WIF_PROVIDER = ${WIF_PROVIDER}"
echo "  DEPLOY_SA    = ${SA_EMAIL}"
echo "==============================================================================="
echo "(Settings -> Secrets and variables -> Actions -> Variables tab. Or with gh CLI:"
echo "  gh variable set WIF_PROVIDER -b '${WIF_PROVIDER}' -R ${REPO}"
echo "  gh variable set DEPLOY_SA    -b '${SA_EMAIL}' -R ${REPO} )"
