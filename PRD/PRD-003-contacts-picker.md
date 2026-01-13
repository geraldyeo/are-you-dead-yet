# PRD-003: iOS Contacts Picker for Emergency Contacts

**Status:** Draft
**Author:** Gerald Yeo
**Created:** January 2025
**Last Updated:** January 2025

---

## Overview

### Problem Statement

The current design requires users to manually enter emergency contact details (name, phone, email). This is:
- Time-consuming and error-prone
- Friction that reduces completion rates
- Inconsistent with iOS UX patterns

### Solution

Use the native iOS Contacts picker to select emergency contacts directly from the user's address book. Limit to a maximum of 3 emergency contacts.

### Changes from Previous PRDs

| Item | PRD-002 | This PRD |
|------|---------|----------|
| Contact entry | Manual form input | iOS Contacts picker |
| Max contacts | 5 | **3** |
| Data source | User types info | Pull from address book |

---

## Goals & Success Metrics

### Goals

1. Reduce friction when adding emergency contacts
2. Eliminate manual data entry errors
3. Align with iOS UX patterns users already know
4. Keep contact list focused (max 3)

### Success Metrics

| Metric | Target |
|--------|--------|
| Time to add first contact | < 10 seconds |
| Contact setup completion rate | > 90% |
| Data entry errors | 0% (pulled from Contacts) |

---

## Features

### P0 - Must Have

#### 1. iOS Contacts Picker Integration

**User Experience:**
- Tap "Add Emergency Contact"
- Native iOS Contacts picker appears
- User selects a contact
- App imports name, phone, and email from address book
- User confirms and selects notification channels

**Technical Implementation:**
- Use `CNContactPickerViewController` from ContactsUI framework
- Request properties: `givenName`, `familyName`, `phoneNumbers`, `emailAddresses`
- Handle contacts with multiple phones/emails (let user choose or pick first)
- No permission prompt required (picker is privacy-preserving)

**Code Example:**
```swift
import ContactsUI

struct ContactPickerButton: UIViewControllerRepresentable {
    @Binding var selectedContact: EmergencyContact?

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        picker.predicateForEnablingContact = NSPredicate(
            format: "phoneNumbers.@count > 0 OR emailAddresses.@count > 0"
        )
        return picker
    }
}
```

#### 2. Maximum 3 Emergency Contacts

**User Experience:**
- Settings shows contact slots: "Emergency Contacts (1/3)"
- After 3 contacts, "Add Contact" button is disabled
- Clear message: "Maximum 3 contacts reached"
- User must remove a contact to add a new one

**Rationale:**
- 3 contacts is sufficient for most emergency scenarios
- Reduces notification costs per event
- Keeps UI clean and manageable
- Forces users to prioritize their most important contacts

**Technical Implementation:**
```swift
var canAddContact: Bool {
    emergencyContacts.count < 3
}
```

#### 3. Contact Data Handling

**What we import:**
| Field | Source | Required |
|-------|--------|----------|
| Name | `givenName` + `familyName` | Yes |
| Phone | First `phoneNumber` or user choice | No* |
| Email | First `emailAddress` or user choice | No* |

*At least one of phone or email is required

**What we DON'T import:**
- Profile photo (privacy, storage)
- Address (not needed)
- Birthday, notes, etc.

**Handling Multiple Numbers/Emails:**
- If contact has multiple phones: Show picker to choose one
- If contact has multiple emails: Show picker to choose one
- Store only the selected values

#### 4. Manual Email Fallback

**Scenario:** User selects a contact that has no email address in their address book.

**Problem:** Email is a free-tier notification channel. Without email, free users can only use Telegram (which requires setup).

**Solution:** Allow manual email entry when contact has no email.

**User Experience:**
```
1. User selects contact "Dad" from picker
2. Dad has phone but no email in Contacts
3. Confirmation sheet shows:
   - Name: Dad
   - Phone: +65 9123 4567
   - Email: (empty) [Add Email]
4. User taps "Add Email"
5. Email input field appears
6. User types: dad@example.com
7. Email field validates format
8. User proceeds to channel selection
```

**Technical Implementation:**
```swift
struct ContactConfirmationSheet: View {
    @State var contact: EmergencyContact
    @State var showEmailInput: Bool = false
    @State var manualEmail: String = ""

    var body: some View {
        // If no email from Contacts, show input field
        if contact.email == nil {
            if showEmailInput {
                TextField("Email address", text: $manualEmail)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
            } else {
                Button("Add Email") {
                    showEmailInput = true
                }
            }
        }
    }
}
```

**Validation:**
- Basic email format validation (contains @ and .)
- Show error for invalid format
- Email is optional but recommended for free tier

#### 5. Contact Updates

**Scenario:** User updates contact info in iOS Contacts app

**Behavior:**
- App does NOT auto-sync changes
- Contact info is copied at time of selection
- User can remove and re-add contact to update info
- Simpler implementation, clearer mental model

**Future consideration:** Add "Refresh from Contacts" button (P2)

### P1 - Should Have

#### 1. Duplicate Detection
- Warn if user tries to add same contact twice
- Match by phone number or email
- "This contact is already added"

#### 2. Contact Validation
- Verify contact has at least one valid phone or email
- Show error if contact has no usable contact methods
- Filter contacts in picker to only show valid ones

### P2 - Nice to Have

#### 1. Refresh from Contacts
- Button to re-sync contact info from address book
- Useful if phone number or email changes

#### 2. Quick Add from Recents
- Show recently contacted people as suggestions
- One-tap to add as emergency contact

---

## Technical Architecture

### Required Frameworks

```swift
import Contacts       // CNContact data model
import ContactsUI     // CNContactPickerViewController
```

### Permissions

**No permission prompt needed!**

The `CNContactPickerViewController` is privacy-preserving:
- User explicitly selects which contact to share
- App only receives data for selected contact
- No access to full address book
- No `NSContactsUsageDescription` required in Info.plist

### Updated EmergencyContact Model

```swift
struct EmergencyContact: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var phoneNumber: String?
    var email: String?
    var telegramChatId: String?
    var enabledChannels: Set<NotificationChannel>

    // Validation
    var isValid: Bool {
        phoneNumber != nil || email != nil
    }
}
```

### Contact Picker Implementation

```swift
import SwiftUI
import ContactsUI

struct ContactPicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) var dismiss
    var onSelectContact: (CNContact) -> Void

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        // Only show contacts with phone or email
        picker.predicateForEnablingContact = NSPredicate(
            format: "phoneNumbers.@count > 0 OR emailAddresses.@count > 0"
        )
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, CNContactPickerDelegate {
        let parent: ContactPicker

        init(_ parent: ContactPicker) {
            self.parent = parent
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            parent.onSelectContact(contact)
            parent.dismiss()
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            parent.dismiss()
        }
    }
}
```

### Converting CNContact to EmergencyContact

```swift
extension EmergencyContact {
    init(from cnContact: CNContact) {
        self.id = UUID()
        self.name = [cnContact.givenName, cnContact.familyName]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        self.phoneNumber = cnContact.phoneNumbers.first?.value.stringValue
        self.email = cnContact.emailAddresses.first?.value as String?
        self.telegramChatId = nil
        self.enabledChannels = [.email] // Default to email
    }
}
```

---

## User Flows

### Add First Emergency Contact

```
1. User opens Settings
2. Sees "Emergency Contacts (0/3)"
3. Taps "Add from Contacts"
4. iOS Contacts picker appears
5. User scrolls/searches for contact
6. Taps on "Mom"
7. Picker dismisses
8. Sheet appears showing:
   - Name: Mom
   - Phone: +65 9123 4567
   - Email: mom@example.com
   - Channel toggles (Email ✓, Telegram, SMS 🔒, WhatsApp 🔒)
9. User confirms channels
10. Taps "Save"
11. Contact appears in list: "Emergency Contacts (1/3)"
```

### Try to Add 4th Contact

```
1. User has 3 contacts already
2. "Add from Contacts" button is grayed out
3. Below button: "Maximum 3 contacts. Remove one to add another."
```

### Contact Has Multiple Phone Numbers

```
1. User selects contact "John" from picker
2. John has 2 phone numbers: Mobile, Work
3. Sheet appears: "Which phone number?"
   - Mobile: +65 9123 4567
   - Work: +65 6789 0123
4. User taps "Mobile"
5. Proceeds to channel selection
```

### Contact Has No Email (Manual Fallback)

```
1. User selects contact "Dad" from picker
2. Dad has phone (+65 9123 4567) but no email
3. Confirmation sheet shows:
   - Name: Dad
   - Phone: +65 9123 4567
   - Email: Not available [+ Add Email]
4. User taps "+ Add Email"
5. Text field appears for email input
6. User types: dad@example.com
7. Field validates email format (green checkmark)
8. User selects notification channels:
   - Email ✓ (now available)
   - Telegram (optional)
9. Taps "Add Contact"
10. Contact saved with manually entered email
```

---

## UI/UX Considerations

### Settings Screen Updates

```
┌─────────────────────────────────────┐
│ Settings                            │
├─────────────────────────────────────┤
│                                     │
│ EMERGENCY CONTACTS (2/3)            │
│ ┌─────────────────────────────────┐ │
│ │ 👤 Mom                          │ │
│ │    📧 Email ✓  ✈️ Telegram ✓    │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ 👤 Dad                          │ │
│ │    📧 Email ✓                   │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ ➕ Add from Contacts            │ │
│ └─────────────────────────────────┘ │
│                                     │
└─────────────────────────────────────┘

When at 3/3:

│ EMERGENCY CONTACTS (3/3)            │
│ ...                                 │
│ ┌─────────────────────────────────┐ │
│ │ ➕ Add from Contacts      ░░░░  │ │ (disabled)
│ │    Maximum 3 contacts           │ │
│ └─────────────────────────────────┘ │
```

### Contact Confirmation Sheet (With Email)

```
┌─────────────────────────────────────┐
│ Add Emergency Contact               │
├─────────────────────────────────────┤
│                                     │
│        👤                           │
│       Mom                           │
│                                     │
│ CONTACT INFO                        │
│ ┌─────────────────────────────────┐ │
│ │ 📱 +65 9123 4567                │ │
│ │ 📧 mom@example.com              │ │
│ └─────────────────────────────────┘ │
│                                     │
│ NOTIFICATION CHANNELS               │
│ ┌─────────────────────────────────┐ │
│ │ ☑ Email         (Free)          │ │
│ │ ☐ Telegram      (Free) [Setup]  │ │
│ │ ☐ SMS           (Premium) 🔒    │ │
│ │ ☐ WhatsApp      (Premium) 🔒    │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │         Add Contact             │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

### Contact Confirmation Sheet (No Email - Manual Fallback)

```
┌─────────────────────────────────────┐
│ Add Emergency Contact               │
├─────────────────────────────────────┤
│                                     │
│        👤                           │
│       Dad                           │
│                                     │
│ CONTACT INFO                        │
│ ┌─────────────────────────────────┐ │
│ │ 📱 +65 9123 4567                │ │
│ │ 📧 No email     [+ Add Email]   │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ⚠️ Add an email to enable free      │
│    notifications                    │
│                                     │
│ NOTIFICATION CHANNELS               │
│ ┌─────────────────────────────────┐ │
│ │ ☐ Email         (Free) ⚠️       │ │
│ │ ☐ Telegram      (Free) [Setup]  │ │
│ │ ☐ SMS           (Premium) 🔒    │ │
│ │ ☐ WhatsApp      (Premium) 🔒    │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │         Add Contact             │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘

After tapping "+ Add Email":

│ CONTACT INFO                        │
│ ┌─────────────────────────────────┐ │
│ │ 📱 +65 9123 4567                │ │
│ │ 📧 [dad@example.com        ] ✓  │ │
│ └─────────────────────────────────┘ │
```

---

## Design Decisions

### Why iOS Contacts Picker vs Manual Entry?

| Contacts Picker | Manual Entry |
|-----------------|--------------|
| 3-5 seconds to add | 30-60 seconds to type |
| Zero typos | Typos in phone/email |
| Familiar iOS pattern | Custom form |
| No permission prompt | N/A |
| Data already validated | Need validation |

**Decision:** Contacts picker is objectively better UX.

### Why Limit to 3 Contacts?

1. **Cost control** - Fewer contacts = lower per-event cost
2. **Focus** - Forces users to pick most important people
3. **UI simplicity** - Fits on one screen without scrolling
4. **Realistic** - 3 people is enough for emergency response
5. **Reduced from 5** - PRD-002 said 5, but 3 is sufficient

### Why No Auto-Sync with Contacts?

1. **Simplicity** - No background sync logic needed
2. **Predictability** - User knows exactly what data app has
3. **Privacy** - No ongoing access to Contacts database
4. **Edge cases** - Avoids issues when contact is deleted

### Why Manual Email Fallback?

**Problem:** Some contacts in iOS address book don't have email addresses, but email is a free-tier notification channel.

**Options considered:**
1. **Require email** - Only allow contacts with email (too restrictive)
2. **Skip email** - Allow contact without email, rely on Telegram/premium (poor free UX)
3. **Manual entry fallback** - Let user type email if missing (chosen)

**Decision:** Option 3 - Manual email fallback because:
- Keeps Contacts picker as primary flow (fast, error-free)
- Only shows manual input when needed (contact has no email)
- Ensures free tier users can always use email channel
- Minimal friction for edge case

---

## Impact on Other PRDs

### PRD-002 Updates Required

| Section | Change |
|---------|--------|
| Rate Limiting | Max contacts: 5 → **3** |
| Add Contact Flow | Manual entry → **Contacts picker** |
| UI Mockups | Update to show Contacts picker flow |

---

## Implementation Checklist

- [ ] Add ContactsUI framework to project
- [ ] Create `ContactPicker` SwiftUI wrapper
- [ ] Update `EmergencyContact` model with `init(from: CNContact)`
- [ ] Add multiple phone/email selection sheet
- [ ] Update `CheckInManager` to enforce 3 contact limit
- [ ] Update Settings UI with contact count (X/3)
- [ ] Add disabled state for "Add" button when at limit
- [ ] Handle edge case: contact with no phone or email
- [ ] Add manual email input field for contacts without email
- [ ] Add email format validation
- [ ] Show warning when contact has no email
- [ ] Update PRD-002 to reflect 3 contact limit

---

## References

- [CNContactPickerViewController Documentation](https://developer.apple.com/documentation/contactsui/cncontactpickerviewcontroller)
- [Contacts Framework](https://developer.apple.com/documentation/contacts)
- [PRD-002: Freemium Notification System](./PRD-002-freemium-notifications.md)
