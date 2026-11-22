#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  echo 'Flutter SDK is not installed or not on PATH.' >&2
  exit 1
fi

flutter create \
  --platforms=android,ios,web,windows,macos,linux \
  --org com.gensolar \
  --project-name gensolar_pro_engineering \
  .
flutter pub get

echo 'GenSolar platform runner folders generated. Review flutter doctor before building native targets.'
