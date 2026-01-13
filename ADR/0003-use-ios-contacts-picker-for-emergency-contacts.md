# 3. Use iOS Contacts picker for emergency contacts

Date: 2026-01-13

## Status

Accepted

## Context

Users need to add emergency contacts to the app. The original design required manual entry of contact details (name, phone number, email) via a form.

**Problems with manual entry:**
- Time-consuming (30-60 seconds per contact)
- Error-prone (typos in phone numbers, emails)
- Poor UX compared to native iOS patterns
- Requires validation logic for each field

**Options considered:**

1. **Manual form entry** - User types all contact details
2. **iOS Contacts picker** - User selects from address book
3. **Import all contacts** - Bulk import with selection checkboxes

## Decision

We will use the **iOS Contacts picker** (`CNContactPickerViewController`) for adding emergency contacts, with a **maximum of 3 contacts**.

**Key decisions:**

1. **Use `CNContactPickerViewController`** - Native iOS picker, familiar UX
2. **No permission prompt required** - Picker is privacy-preserving by design
3. **Import only selected fields** - Name, phone, email (not photos, addresses, etc.)
4. **Maximum 3 contacts** - Reduced from 5 to control costs and simplify UX
5. **No auto-sync** - Contact info is copied once, not kept in sync
6. **Manual email fallback** - If contact has no email, allow user to type one

**Technical approach:**

```swift
import ContactsUI

// CNContactPickerViewController requires no permission prompt
// User explicitly chooses which contact to share
// App only receives data for the selected contact
```

## Consequences

### Positive

- **Faster setup** - 3-5 seconds vs 30-60 seconds per contact
- **Zero typos** - Data pulled directly from user's address book
- **Familiar UX** - Native iOS pattern users already know
- **No permission prompt** - Privacy-preserving picker doesn't require authorization
- **No validation needed** - Phone/email already validated in Contacts app
- **Simpler code** - No form validation, keyboard handling, etc.

### Negative

- **No auto-sync** - If user updates contact in address book, app doesn't reflect changes
- **UIKit wrapper needed** - `CNContactPickerViewController` requires `UIViewControllerRepresentable` in SwiftUI
- **Multiple phone/email handling** - Need UI to let user choose when contact has multiple numbers
- **Manual email fallback needed** - Contacts without email require manual input for free-tier notifications

### Trade-offs

| Manual Entry | Contacts Picker |
|--------------|-----------------|
| Works without existing contacts | Requires contact in address book |
| Full control over data | Limited to Contacts fields |
| More code to maintain | Less code, native component |
| Higher error rate | Zero errors |

**Decision:** The benefits of Contacts picker far outweigh the drawbacks. Users who don't have contacts in their address book are edge cases.

## References

- [PRD-003: iOS Contacts Picker](../PRD/PRD-003-contacts-picker.md)
- [CNContactPickerViewController Documentation](https://developer.apple.com/documentation/contactsui/cncontactpickerviewcontroller)
