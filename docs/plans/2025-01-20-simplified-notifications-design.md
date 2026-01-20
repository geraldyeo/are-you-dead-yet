# Simplified Emergency Notifications Design

**Status:** Approved
**Author:** Gerald Yeo
**Created:** 2025-01-20

---

## Overview

This design replaces PRD-002's freemium model with a simpler approach: launch with only free-to-operate notification channels (Email + Telegram). No premium tier, no SMS, no WhatsApp, no in-app purchases.

### Rationale

At expected scale (10-50 users in first 6 months), neither freemium nor paid-upfront breaks even on backend costs. Instead of subsidizing $20-40/month for SMS/WhatsApp infrastructure, we launch with zero marginal cost per notification:

- SendGrid free tier: 100 emails/day ($0)
- Telegram Bot API: Unlimited ($0)
- Cloudflare Workers: Free tier sufficient ($0)

Premium features (SMS, WhatsApp) become Phase 2—built only if users request them.

### What's Deferred (Not Deleted)

- StoreKit / premium unlock
- Twilio SMS integration
- WhatsApp Business API
- Premium UI elements

### What's Kept from PRD-002

- Backend architecture (serverless)
- Email via SendGrid
- Telegram bot flow
- Rate limiting (1 emergency/week)
- 3 contact limit (from PRD-003)
- Core notification flow and templates

---

## Architecture

```
┌─────────────────┐         ┌──────────────────────────────┐
│   iOS App       │         │     Backend (Cloudflare)     │
│                 │  HTTPS  │                              │
│  Emergency      │────────▶│  POST /api/emergency-notify  │
│  Trigger        │         │                              │
│                 │         │  ┌────────┐    ┌──────────┐  │
│  Telegram       │◀────────│  │ Email  │    │ Telegram │  │
│  Link Setup     │ webhook │  │SendGrid│    │ Bot API  │  │
└─────────────────┘         │  └────────┘    └──────────┘  │
                            └──────────────────────────────┘
```

### Backend Endpoints

1. **POST /api/emergency-notify** - Called when emergency triggers
   - Receives: user name, contacts, location, last check-in time
   - Sends: emails and Telegram messages to all contacts
   - Returns: delivery status per contact

2. **POST /api/telegram-webhook** - Receives Telegram bot events
   - Handles: contact clicking the setup link and starting the bot
   - Stores: chat_id for that contact
   - Returns: confirmation to Telegram

### Authentication

Device token generated on first app launch, included in all requests. Simple but sufficient for MVP scale.

### Stack

- **Backend:** Cloudflare Workers
- **Database:** Cloudflare D1 (SQLite)
- **Email:** SendGrid (free tier)
- **Messaging:** Telegram Bot API (free)

---

## Data Model

### EmergencyContact (iOS)

```swift
struct EmergencyContact: Codable, Identifiable {
    let id: UUID
    var name: String
    var email: String?              // For email notifications
    var telegramChatId: String?     // Set after Telegram linking
    var telegramLinkToken: String?  // For pending Telegram setup
}
```

### Contact Requirements

- Name is required
- At least one of: email OR telegramChatId
- Max 3 contacts

### Database Schema (D1)

```sql
CREATE TABLE telegram_links (
  token TEXT PRIMARY KEY,
  device_id TEXT NOT NULL,
  contact_id TEXT NOT NULL,
  chat_id TEXT,
  created_at INTEGER NOT NULL
);
```

---

## Emergency Flow

```
1. 48 hours without check-in
         ↓
2. Background task fires
         ↓
3. Check rate limit (1 per 7 days)
         ↓ (if allowed)
4. Get current location
         ↓
5. POST to /api/emergency-notify
   {
     "user_name": "Gerald",
     "last_check_in": "2025-01-18T10:00:00Z",
     "location": { "lat": 1.35, "lng": 103.82 },
     "contacts": [
       { "name": "Mom", "email": "mom@example.com" },
       { "name": "Friend", "telegram_chat_id": "123456" }
     ]
   }
         ↓
6. Backend sends email via SendGrid + Telegram via Bot API
         ↓
7. App shows local notification confirming alerts sent
```

---

## Telegram Setup Flow

1. User adds contact with name (no Telegram yet)
2. User taps "Set up Telegram" for that contact
3. App generates unique token: `abc123xyz`
4. App shows shareable link: `https://t.me/AreYouDeadYetBot?start=abc123xyz`
5. User sends this link to their contact (via iMessage, WhatsApp, etc.)
6. Contact clicks link → Opens Telegram → Sees "Start" button
7. Contact taps Start → Bot receives `/start abc123xyz`
8. Backend webhook:
   - Looks up token `abc123xyz`
   - Stores the contact's `chat_id`
   - Sends confirmation: "You're now an emergency contact for [User]"
9. Next time app syncs, it sees `telegramChatId` is now set

### Edge Cases

- Link expires after 7 days (contact must request new one)
- Contact can unlink by blocking the bot
- If contact clicks link twice, just update the chat_id

---

## Error Handling

### Notification Delivery Failures

| Scenario | Handling |
|----------|----------|
| Email bounces | Log failure, no retry (bad address) |
| Email temp failure | Retry 2x with backoff, then give up |
| Telegram chat_id invalid | Mark contact as "needs re-linking" |
| Telegram rate limited | Retry after delay (rare at this scale) |
| Backend unreachable | App retries 3x, then shows local notification asking user to manually contact someone |

### Rate Limiting

- 1 emergency per 7 days (abuse prevention)
- If rate limited: show clear message in app with countdown
- Rate limit resets after 7 days OR after next successful check-in (whichever comes first)

### Contact Edge Cases

| Scenario | Handling |
|----------|----------|
| Contact has no email AND no Telegram linked | Block save, show "Add at least one contact method" |
| User deletes contact mid-Telegram-setup | Webhook ignores orphaned tokens |
| All notifications fail | App shows critical local alert: "Emergency contacts couldn't be reached. Please contact someone manually." |

### Location Failures

- If location unavailable: send notifications anyway, omit location
- Message says "Location unavailable" instead of map link

### Offline Scenarios

- Emergency triggers but no network: queue request, retry when online
- If still offline after 1 hour: show local notification urging manual contact

---

## iOS Implementation

### Files to Modify

| File | Changes |
|------|---------|
| `EmergencyContact.swift` | Simplify model (remove phone, channels) |
| `EmergencyContactService.swift` | Call backend API instead of logging |
| `CheckInManager.swift` | Add rate limit tracking |
| Settings UI | Update contact UI, add Telegram setup |

### New Files

| File | Purpose |
|------|---------|
| `NotificationAPIService.swift` | HTTP client for backend |
| `TelegramLinkView.swift` | UI for sharing Telegram setup link |
| `RateLimitView.swift` | Shows cooldown status |

### UserDefaults Additions

```swift
// Rate limiting
"lastEmergencyTriggerDate": Date?

// Device identification
"deviceToken": String  // Generated once on first launch
```

### Not Needed

- `PurchaseManager.swift` - No StoreKit
- Premium UI components
- Phone number input/validation
- Channel selection toggles

---

## Backend Implementation

### Project Structure

```
backend/
├── wrangler.toml          # Cloudflare config
├── src/
│   ├── index.ts           # Router
│   ├── emergency.ts       # POST /api/emergency-notify
│   ├── telegram.ts        # POST /api/telegram-webhook + link management
│   ├── email.ts           # SendGrid integration
│   └── types.ts           # Shared types
└── package.json
```

### Environment Variables

```
SENDGRID_API_KEY=SG.xxx
TELEGRAM_BOT_TOKEN=123456:ABC-xxx
```

### API Responses

```typescript
// POST /api/emergency-notify response
{
  "success": true,
  "results": [
    { "contact": "Mom", "email": "sent", "telegram": "not_configured" },
    { "contact": "Friend", "email": "not_configured", "telegram": "sent" }
  ]
}

// Error case
{
  "success": false,
  "error": "rate_limited",
  "retry_after": "2025-01-25T10:00:00Z"
}
```

### Free Tier Limits

- Workers: 100k requests/day
- D1: 5M rows read/day, 100k writes/day

---

## Message Templates

### Email

```
Subject: URGENT: [User Name] may need help

[User Name] uses "Are You Dead Yet?" to check in daily.
They haven't checked in for [X] days, which triggered this alert.

Last known location:
[Apple Maps Link]

Please try to contact them or check on their wellbeing.

---
This is an automated emergency alert from Are You Dead Yet?
```

### Telegram

```
🚨 EMERGENCY ALERT

[User Name] hasn't checked in for [X] days.

They may need help. Please try to contact them.

📍 Last known location:
[Apple Maps Link]
```

---

## Testing Strategy

### iOS App Testing

| What | How |
|------|-----|
| Contact CRUD | Unit tests on `CheckInManager` |
| Rate limit logic | Unit tests with mocked dates |
| API client | Unit tests with mocked URLSession |
| Telegram link generation | Unit test token generation |
| UI flows | Manual testing on simulator |

### Backend Testing

| What | How |
|------|-----|
| Emergency endpoint | Integration tests with test SendGrid/Telegram credentials |
| Telegram webhook | Unit tests with sample payloads |
| D1 queries | Local testing with `wrangler dev` |

### End-to-End Testing (Manual)

1. Add contact with email → trigger emergency → verify email received
2. Add contact with Telegram → complete linking → trigger emergency → verify Telegram message
3. Trigger emergency → try again within 7 days → verify rate limit blocks
4. Trigger with no network → verify retry behavior
5. Trigger with location off → verify message sent without location

### Test Credentials

- SendGrid: Use sandbox mode or a test email you control
- Telegram: Create a second bot for testing, message yourself

---

## Phase 2 (Future)

Only build if users request:

- SMS notifications (Twilio)
- WhatsApp notifications (Twilio/Meta)
- Premium tier with StoreKit
- Notification preferences per contact
- Delivery status dashboard

---

## Open Questions

1. Should Telegram link tokens be single-use or reusable?
2. Do we need a "test notification" feature for MVP?
3. Should rate limit reset on any check-in, or only after cooldown expires?
