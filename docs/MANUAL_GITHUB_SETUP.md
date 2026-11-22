# Manual GitHub setup and build

## Prepare the local project

1. Install Flutter 3.50.0 stable (Dart 3.14.0) and run `flutter doctor -v`.
2. Extract the source ZIP into a normal development folder.
3. From that folder, run `scripts/bootstrap_platforms.ps1` on Windows or `scripts/bootstrap_platforms.sh` on macOS/Linux.
4. Run `flutter pub get`, `dart format lib test`, `flutter analyze --fatal-warnings` and `flutter test` locally.

## Create and publish the repository

1. Create a new empty repository named `GenSolar-Pro-Engineering-Next`.
2. In GitHub Desktop choose **Add an Existing Repository** and select the extracted source directory.
3. Publish to the new repository and push the `main` branch.
4. Open **Actions → GenSolar Pro Engineering – Cross-platform CI**.

## What CI does

The `validate` job generates platform runner boilerplate, resolves packages, formats Dart source, analyzes warnings and runs unit/workflow regression tests. Each platform job then builds its own Android, iOS unsigned, Web, Windows, macOS or Linux output. The iOS job requires a macOS runner and remains unsigned until signing is configured.

Download an APK or other platform package only when its matching job completed successfully and its artifact exists. A green validation job alone is not a platform build. An uploaded debug APK is for testing, not Play Store distribution.

## Production requirements not included

Production signing keys, Google/Apple provisioning, API keys, map/weather credentials, backend endpoints and cloud service-account secrets are not embedded in the source. Configure them through protected GitHub secrets and platform-specific project configuration only after those integrations have been implemented and reviewed.
