---
title: Release signing uses four standard CI secrets
author: Atef
date: 2026-11-26
branch: svg-pages
id: l-d0038ab4
scope: repo
status: active
src: agent
touches:
  - ".github/workflows/flutter-build-apk.yml"
  - android/app/build.gradle
  - handover.md
  - pubspec.lock
  - pubspec.yaml
---

## Decided
- Tag builds sign the release APK with an upload key: CI decodes `KEYSTORE_BASE64` into `android/app/upload-keystore.jks` and writes `android/key.properties` from `KEYSTORE_PASSWORD`, `KEY_ALIAS` and `KEY_PASSWORD`. The workflow fails with a named list if any secret is missing.
- Local builds keep `signingConfigs.debug` when `android/key.properties` is absent, so `flutter run --release` still works without secrets.

## Tried and ruled out
- A silent CI fallback to debug signing was considered; rejected because a "release" APK could look properly signed while still carrying the debug key.

## Watch out
- Tag-triggered workflows check out the workflow file at the tag, so signing changes only apply to a newly cut tag (same caveat as the JDK 17 learning).
- This machine has no Android SDK, so `flutter build apk --release` cannot be verified locally; the Gradle signing path only runs in CI.

In the code: `.github/workflows/flutter-build-apk.yml`, `android/app/build.gradle`.
