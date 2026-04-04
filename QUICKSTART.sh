#!/bin/bash

# Planora Quick Start Guide

## Prerequisites
# ✓ Flutter SDK (installed at ~/.local/opt/flutter)
# ✓ Android SDK (installed at ~/Android/Sdk)
# ✓ Android Emulator (planora_api36 - already created)

## Environment Setup (if needed)
export FLUTTER_HOME="$HOME/.local/opt/flutter"
export ANDROID_SDK_ROOT="$HOME/Android/Sdk"
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$FLUTTER_HOME/bin:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"

# Or source it from ~/.bashrc (already added):
# source ~/.bashrc

## Running the App

# List available devices
flutter devices

# Run on emulator
flutter run -d emulator-5554

# Run on physical device (replace with your device ID)
# flutter run -d <device-id>

# Run with verbose output for debugging
# flutter run -v

## Building Release

# Build APK
flutter build apk --release

# Build App Bundle (for Google Play)
flutter build appbundle --release

## Project Commands

# Get latest dependencies
flutter pub get

# Check Flutter/Android setup
flutter doctor -v

# Clean build
flutter clean
flutter pub get

## File Organization

lib/
├── main.dart                 # Entry point
├── app.dart                  # Root widget
├── database/
│   └── database_service.dart # SQLite setup
├── models/
│   ├── trip.dart
│   ├── place.dart
│   ├── itinerary_item.dart
│   └── trip_document.dart
├── screens/
│   ├── home_screen.dart     # Main screen: trips list + "Start a Journey" button
│   └── trip_details_screen.dart
├── services/
│   ├── trips_data_source.dart      # Database operations
│   ├── trips_repository.dart       # Data access abstraction
│   ├── trips_controller.dart       # Trips list logic
│   └── trip_details_controller.dart # Trip details logic
└── widgets/                  # For future reusable components

## Core Features Implemented

✓ Trip creation with start/end dates
✓ Place management (add/list per trip)
✓ Itinerary planning (day-by-day activities)
✓ Document references (local file paths)
✓ Offline SQLite database
✓ Clean architecture with separation of concerns

## Trip Model

{
  "id": 1,
  "name": "Europe Adventure",
  "start_date": "2025-06-01T00:00:00.000Z",
  "end_date": "2025-06-15T00:00:00.000Z",
  "created_at": "2025-05-20T15:30:00.000Z"
}

## Next Phase Ideas

- Add offline maps (OpenStreetMap)
- Trip photo gallery
- Import/export functionality
- Search and filters
- Trip templates
- Collaborator sharing (local)
