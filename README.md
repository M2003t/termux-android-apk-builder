# Termux AppForge

Build native Android APKs entirely on-device with Termux, no PC or Android Studio required. GUI tooling for compiling, packaging, signing and installing Nim, Raylib and other native Android projects.

## Current Features
- Native Android APK builds directly on the phone
- Nim and Raylib/Naylib support
- APK packaging, alignment and signing
- Automated APK verification
- Runtime smoke testing
- Clean build workflow
- End-to-end validation from source to installed app

## Validation Workflow
- Clean
- Build
- Verify
- Install
- Runtime Smoke Test

## Local Data
- The `local_data/` folder stores local settings, API configurations, shortcuts and other device-specific data.
- It is created automatically when needed and is excluded from GitHub using `.gitignore`.

## Project Status
- Early development
- Core Android build and validation workflow is working
- GUI development is the next major stage
