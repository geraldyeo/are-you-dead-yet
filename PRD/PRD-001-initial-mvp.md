# PRD-001: Are You Dead Yet? - Initial MVP

**Status:** Completed
**Author:** Gerald Yeo
**Created:** January 2025
**Last Updated:** January 2025

---

## Overview

### Problem Statement

People living alone, elderly individuals, or those in high-risk situations need a simple way to signal they're okay on a daily basis. If something happens to them, their loved ones may not find out for days.

### Solution

"Are You Dead Yet?" is a "dead man's switch" mobile app. Users tap a button daily to confirm they're alive. If they miss check-ins, the app escalates from gentle reminders to notifying emergency contacts with the user's last known location.

### Target Users

- Solo travelers and adventurers
- Elderly individuals living alone
- People with medical conditions
- Remote workers in isolated locations
- Anyone who wants peace of mind for their loved ones

---

## Goals & Success Metrics

### Goals

1. Provide a frictionless daily check-in experience (< 3 seconds)
2. Ensure reliable notification delivery to emergency contacts
3. Maintain user privacy while enabling location sharing in emergencies

### Success Metrics

| Metric | Target |
|--------|--------|
| Daily active check-in rate | > 80% of users |
| Time to complete check-in | < 3 seconds |
| App crash rate | < 0.1% |
| Notification delivery rate | > 99% |

---

## Features

### P0 - Must Have (Implemented)

#### 1. Daily Check-In Button
- Large, prominent green button on main screen
- Single tap to confirm "I'm alive"
- Visual feedback on successful check-in
- Disabled state after daily check-in to prevent accidental re-taps
- Displays time since last check-in

#### 2. Check-In Status Indicators
- **Green checkmark**: Checked in today
- **Orange clock**: 1 day since last check-in (reminder sent)
- **Red warning**: 2+ days (emergency contacts notified)
- **Blue heart**: First-time user, no check-ins yet

#### 3. Emergency Contacts Management
- Add multiple emergency contacts
- Required fields: Name, Phone number
- Optional field: Email
- Edit and delete contacts
- Stored locally on device

#### 4. Local Notifications
- 24-hour reminder if check-in missed
- Time-sensitive notification priority
- Critical alert for emergency notification
- Badge count management

#### 5. Background Task Processing
- 24-hour background task for check-in reminders
- 48-hour background task for emergency escalation
- Runs even when app is closed

#### 6. Location Services
- Request "Always" location permission
- Capture location when emergency is triggered
- Generate Apple Maps link for emergency contacts

#### 7. Settings Screen
- View emergency contacts list
- View recent check-in history (last 10)
- Location permission status and request
- App version and info

### P1 - Should Have (Not Implemented)

#### 1. Actual SMS/Email Delivery
- Current state: Logs to console only
- Needs: Backend service integration (Twilio, SendGrid)

#### 2. Onboarding Flow
- First-time user tutorial
- Permission request explanations
- Emergency contact setup wizard

#### 3. Custom Check-In Window
- Allow users to set custom reminder times
- Configurable grace period before emergency

### P2 - Nice to Have (Future)

#### 1. Multi-Device Sync
- CloudKit integration
- Check-in from any device

#### 2. Apple Watch App
- Quick check-in from wrist
- Complications for check-in status

#### 3. Widget Support
- Home screen widget for quick check-in
- Status display widget

---

## Technical Architecture

### Platform
- iOS 15.0+
- SwiftUI
- MVVM architecture

### Data Storage
- UserDefaults for persistence
- JSON encoding/decoding for complex objects
- Maximum 30 check-in history entries

### Background Processing
- BGTaskScheduler for background tasks
- Task identifiers:
  - `com.after6ix.AreYouDeadYet.checkInReminder` (24h)
  - `com.after6ix.AreYouDeadYet.emergencyCheck` (48h)

### Required Permissions
| Permission | Purpose |
|------------|---------|
| Notifications | Send check-in reminders and emergency alerts |
| Location (Always) | Share location with emergency contacts |
| Background App Refresh | Run check-in monitoring tasks |

### Key Components
```
AreYouDeadYetApp.swift    - App entry, background task registration
CheckInManager.swift       - Central state management
NotificationService.swift  - Local notification handling
LocationService.swift      - CoreLocation wrapper
EmergencyContactService.swift - Emergency alert dispatch
```

---

## User Flows

### Daily Check-In Flow
```
1. User opens app
2. Sees large green "I'M ALIVE" button
3. Taps button
4. Sees confirmation alert
5. Button changes to disabled state with checkmark
6. 24-hour timer resets
```

### Missed Check-In Flow
```
1. 24 hours pass without check-in
2. Background task fires
3. User receives reminder notification
4. If user checks in → timer resets
5. If another 24 hours pass → emergency flow triggers
```

### Emergency Flow
```
1. 48 hours pass without check-in
2. Background task fires
3. App requests current location
4. For each emergency contact:
   - Prepare message with location link
   - Log notification (actual send requires backend)
5. Send critical local notification to user
```

---

## Design Decisions

### Why a Single Big Button?
- Minimizes friction for daily use
- Works for users with limited dexterity
- Clear, unambiguous primary action
- Reduces cognitive load

### Why 24/48 Hour Intervals?
- 24h reminder is gentle nudge, not intrusive
- 48h escalation prevents false alarms from busy days
- Balances safety with avoiding alert fatigue

### Why Local Storage Only?
- MVP simplicity
- Privacy-first approach
- No account creation friction
- Works offline

---

## Known Limitations

1. **Emergency notifications are mocked** - SMS/email requires backend integration
2. **No cross-device sync** - Check-ins are device-specific
3. **Background task timing is approximate** - iOS manages task scheduling
4. **Location accuracy varies** - Depends on device and conditions

---

## Future Considerations

1. Backend service for reliable SMS/email delivery
2. Web dashboard for emergency contacts to view status
3. Integration with health apps (detect falls, heart rate anomalies)
4. Customizable check-in schedules
5. Multiple "switches" for different contact groups

---

## Appendix

### File Structure
```
AreYouDeadYet/
├── AreYouDeadYetApp.swift
├── ContentView.swift
├── Info.plist
├── Models/
│   ├── CheckIn.swift
│   └── EmergencyContact.swift
├── Services/
│   ├── CheckInManager.swift
│   ├── NotificationService.swift
│   ├── LocationService.swift
│   └── EmergencyContactService.swift
└── Views/
    ├── CheckInView.swift
    └── SettingsView.swift
```

### References
- [Apple BGTaskScheduler Documentation](https://developer.apple.com/documentation/backgroundtasks)
- [UNUserNotificationCenter Documentation](https://developer.apple.com/documentation/usernotifications)
- [CoreLocation Documentation](https://developer.apple.com/documentation/corelocation)
