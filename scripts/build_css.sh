#!/usr/bin/env bash
# Compile SCSS -> app/static/styles/compiled.css with Dart Sass.
#
# Requires the Dart Sass `sass` binary on PATH:
#   brew install sass/sass/sass      # macOS
#   npm install -g sass              # any platform
# In dev you can instead watch for changes:
#   sass --watch app/static/scss/main.scss:app/static/styles/compiled.css
set -euo pipefail
cd "$(dirname "$0")/.."
sass app/static/scss/main.scss app/static/styles/compiled.css --no-source-map --style=compressed
echo "Built app/static/styles/compiled.css"
