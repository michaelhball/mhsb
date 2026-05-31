#!/usr/bin/env bash
# Compile SCSS -> app/static/styles/compiled.css with Dart Sass.
#
# Uses the `sass` binary if installed (brew install sass/sass/sass, or
# npm install -g sass); otherwise falls back to `npx sass` (needs Node).
# Dev tip — watch for changes instead:
#   sass --watch app/static/scss/main.scss:app/static/styles/compiled.css
set -euo pipefail
cd "$(dirname "$0")/.."
if command -v sass >/dev/null 2>&1; then
  SASS=(sass)
else
  SASS=(npx --yes sass@1.100.0)
fi
"${SASS[@]}" app/static/scss/main.scss app/static/styles/compiled.css --no-source-map --style=compressed
echo "Built app/static/styles/compiled.css"
