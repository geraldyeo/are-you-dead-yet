# Are You Dead Yet?

A "dead man's switch" iOS app that helps ensure your loved ones are notified if something happens to you.

## How It Works

1. **Daily Check-In**: Tap the big green button once a day to confirm you're okay
2. **Gentle Reminder**: Miss a day? You'll get a notification reminder
3. **Emergency Alert**: Miss two consecutive days? Your emergency contacts are automatically notified with your last known location

## Features

- Simple one-tap daily check-in
- Configurable emergency contacts
- Location sharing with emergency contacts
- Check-in history tracking
- Background monitoring with smart notifications

## Requirements

- iOS 17.0+
- Xcode 15.0+

## Permissions

The app requires the following permissions:
- **Location (Always)** - To share your location with emergency contacts if needed
- **Notifications** - For check-in reminders
- **Background App Refresh** - To monitor check-in status

## Installation

1. Clone this repository
2. Open `AreYouDeadYet.xcodeproj` in Xcode
3. Build and run on your device or simulator

## Architecture

Built with **SwiftUI** using the **MVVM** pattern with a service layer:

- `CheckInManager` - Central state management
- `NotificationService` - Local notification scheduling
- `LocationService` - CoreLocation integration
- `EmergencyContactService` - Emergency contact notifications

## License

MIT License
