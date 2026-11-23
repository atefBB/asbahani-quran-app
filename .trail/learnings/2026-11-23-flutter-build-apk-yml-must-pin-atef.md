---
title: flutter-build-apk.yml must pin JDK 17 for Gradle 8.14
author: Atef
date: 2026-11-23
branch: svg-pages
id: l-6a75f8aa
scope: repo
status: active
src: agent
touches:
  - ".github/workflows/flutter-build-apk.yml"
---

## Decided
- In `.github/workflows/flutter-build-apk.yml`, add `actions/setup-java@v4` with `distribution: temurin` and `java-version: '17'` before `subosito/flutter-action`.

## Tried and ruled out
- Relying on the `ubuntu-latest` default JDK: Ubuntu 26.04 ships Java 25, whose class file major 69 makes Gradle 8.14 (pinned in `android/gradle/wrapper/gradle-wrapper.properties`) fail in semantic analysis. Raising the Gradle version was not chosen because Flutter's Android toolchain targets JDK 17.

## Watch out
- Tag-triggered workflows check out the workflow file at the tag itself, so a fix pushed to a branch does not repair older tags. Cut a new tag to get a working release build.
