# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

"Are You Dead Yet?" is an iOS app that serves as a "dead man's switch" - users tap a big green button daily to confirm they're alive. If they miss a day, they get a reminder notification. If they miss 2 consecutive days, their emergency contacts are notified with the user's last known location.

## Build & Run Commands

```bash
# Open in Xcode
open AreYouDeadYet.xcodeproj

# Build from command line
xcodebuild -project AreYouDeadYet.xcodeproj -scheme AreYouDeadYet -sdk iphonesimulator build

# Run tests (when added)
xcodebuild -project AreYouDeadYet.xcodeproj -scheme AreYouDeadYet -sdk iphonesimulator test
```

## Architecture

**SwiftUI + MVVM pattern** with service layer for business logic.

### Key Components

- **AreYouDeadYetApp.swift** - App entry point, manages background task registration
- **CheckInManager** - Central state management for check-ins and emergency contacts (uses UserDefaults for persistence)
- **NotificationService** - Handles local notification scheduling and delivery
- **LocationService** - CoreLocation wrapper for obtaining user location
- **EmergencyContactService** - Handles emergency contact notification (currently logs; needs backend integration for production)

### Data Flow

```
User taps button → CheckInManager.checkIn() → Saves to UserDefaults → Reschedules notifications
                                            ↓
Background task fires → Checks last check-in date → Triggers notification or emergency alert
```

## Required Capabilities & Permissions

The app requires these iOS permissions (configured in Info.plist):
- **Location (Always)** - To share location with emergency contacts
- **Notifications** - For check-in reminders
- **Background Modes**: fetch, processing, location

## Key Implementation Notes

- Check-in history is limited to 30 entries
- Background tasks use `BGTaskScheduler` with identifiers:
  - `com.after6ix.AreYouDeadYet.checkInReminder` (24h)
  - `com.after6ix.AreYouDeadYet.emergencyCheck` (48h)
- Emergency contact notifications currently only log to console - production use requires backend service integration (e.g., Twilio for SMS, SendGrid for email)
- All data persists via UserDefaults (consider migrating to Core Data or SwiftData for larger datasets)

## TODO for Production

1. Implement actual SMS/email sending via backend service
2. Add App Icon (currently placeholder in Assets.xcassets)
3. Add unit tests
4. Consider CloudKit sync for multi-device support
5. Add onboarding flow for first-time users
