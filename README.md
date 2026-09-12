# Termux AppForge

Termux AppForge is an open-source Android development environment designed to build native Android applications entirely on a phone, without requiring a PC or Android Studio.

The project began as a GUI layer for controlling an existing Termux installation. During development and end-to-end testing, the architecture evolved toward a more powerful goal: integrating the official Termux terminal technology directly into AppForge and building a dedicated mobile development interface around it.

The upstream Termux source is tracked directly from the official Termux GitHub project to preserve transparent source provenance and make upstream changes easy to follow.

## Vision

Termux AppForge aims to combine the proven terminal foundation of Termux with a purpose-built graphical development environment.

Instead of treating Termux as an external application controlled through Android intents, AppForge is being designed around its own integrated runtime and terminal sessions.

The planned architecture separates:

- Terminal execution and session management
- Shell and development toolchains
- Terminal emulation
- Mobile input and touch interaction
- AppForge's graphical development interface

This allows AppForge to build its own user experience while preserving the reliability of the underlying terminal technology.

## Planned Terminal Architecture

The project is moving toward direct integration with the official Termux terminal components.

The intended architecture is:

AppForge UI
→ Session Manager
→ Termux terminal-emulator core
→ PTY / shell
→ Development tools

AppForge will control its own interface behavior, including:

- Touch scrolling and gestures
- Android software keyboard integration
- Multiple simultaneous terminal sessions
- A configurable session limit
- Terminal tabs and split views
- Hardware button shortcuts
- Build controls integrated directly into the UI

The terminal backend remains independent from the graphical interface, allowing the UI to evolve without replacing the underlying terminal execution model.

## Upstream Termux

Official Termux source is tracked under:

`vendor/termux-app`

Upstream project:

`termux/termux-app`

Termux itself separates the Android application and terminal emulator from its package ecosystem. AppForge currently tracks the application source for terminal integration research and development.

Future runtime work may also integrate or consume components from the official Termux package ecosystem for tools such as shells, Git, compilers and other native development utilities.

Termux AppForge is an independent project and is not an official Termux project.

## Current Features

- Native Android APK builds directly on the phone
- Nim and Raylib/Naylib support
- APK packaging, alignment and signing
- Automated APK verification
- Runtime smoke testing
- Clean build workflow
- End-to-end validation from source to installed app
- Native Android diagnostics for terminal integration
- Build ID traceability across build and runtime validation

## Validation Workflow

- Clean
- Build
- Verify
- Install
- Runtime Smoke Test

## Current Development Direction

The original prototype communicated with the external Termux application through Android RUN_COMMAND intents.

End-to-end testing exposed permission and integration limitations in that architecture.

The project is now transitioning toward a self-contained design where AppForge directly integrates terminal functionality and manages its own terminal sessions, interface and development workflow.

This removes the dependency on controlling an external Termux installation and creates a foundation for a standalone mobile development environment.

## Local Data

The `local_data/` folder stores local settings, API configurations, shortcuts and other device-specific data.

It is created automatically when needed and is excluded from GitHub using `.gitignore`.

## Project Status

Early development.

The Android build, packaging, signing, verification and runtime validation pipeline is operational.

Current work is focused on integrating the terminal runtime architecture and replacing the external Termux command bridge with direct terminal-session control.

## Attribution

Termux AppForge uses and studies components from the official Termux open-source ecosystem.

Termux:
https://github.com/termux/termux-app

Original Termux code remains subject to its respective upstream licenses and copyright notices.

Termux AppForge is an independent project and is not affiliated with or endorsed by the Termux maintainers.
