# PRD-002: Freemium Emergency Notification System

**Status:** Draft
**Author:** Gerald Yeo
**Created:** January 2025
**Last Updated:** January 2025

---

## Overview

### Problem Statement

The current MVP logs emergency notifications to console only. To make the app production-ready, we need actual delivery mechanisms for emergency alerts. However, SMS and messaging app integrations have per-message costs that need to be sustainable.

### Solution

Implement a freemium notification system:
- **Free Tier**: Email + Telegram notifications (free/negligible cost to operate)
- **Premium Tier ($1.99)**: SMS + WhatsApp (paid messaging channels)

### Business Model

| Tier | Price | Notification Channels |
|------|-------|----------------------|
| Free | $0 | Email + Telegram |
| Premium | $1.99 (one-time) | Email + Telegram + SMS + WhatsApp |

**Why $1.99 one-time?**
- Low barrier to entry encourages conversion
- Better margin to cover SMS/WhatsApp costs sustainably
- Simple pricing, no subscription fatigue
- Users more likely to pay for peace of mind

**Why Email + Telegram in Free Tier?**
- Both are free/negligible to send
- Provides genuine value to free users
- Premium only gates channels that cost us money (SMS, WhatsApp)

### Rate Limiting

To prevent abuse and control costs, emergency notifications are rate limited:

| Limit | Value | Rationale |
|-------|-------|-----------|
| Max emergencies per week | 1 | Prevents accidental/abuse triggers |
| Cooldown after emergency | 7 days | User must check in to reset |
| Max contacts | 3 | Limits per-event cost exposure (see PRD-003) |

If rate limit is hit:
- User sees explanation in app
- Email-only fallback (lowest cost)
- Resets after cooldown period

---

## Goals & Success Metrics

### Goals

1. Enable real emergency notifications (not just logging)
2. Create sustainable revenue to cover messaging costs
3. Maximize free tier value while incentivizing upgrades
4. Support multiple messaging platforms users already use

### Success Metrics

| Metric | Target |
|--------|--------|
| Free → Premium conversion rate | > 15% |
| Email delivery success rate | > 99% |
| SMS delivery success rate | > 98% |
| Messaging app delivery rate | > 95% |
| Average revenue per user (ARPU) | > $0.15 |

---

## Features

### P0 - Must Have

#### 1. Email Notifications (Free Tier)

**User Experience:**
- All users can add emergency contacts with email addresses
- Email is sent automatically when emergency triggers
- Professional, clear email template with:
  - User's name
  - Time since last check-in
  - Last known location (Apple Maps link)
  - Clear call-to-action

**Technical Implementation:**
- Backend service required (SendGrid, AWS SES, or Resend)
- Transactional email (not marketing)
- HTML + plain text fallback
- Delivery tracking and retry logic

**Email Template:**
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

#### 2. Telegram Notifications (Free Tier)

**User Experience:**
- All users can connect Telegram contacts
- Emergency contacts receive Telegram message via bot
- Setup: User generates link, contact clicks to start bot

**Technical Implementation:**
- Telegram Bot API (free to send)
- Create bot via @BotFather
- User flow: Generate unique link → Contact clicks → Starts bot → Linked
- Store Telegram chat_id for each contact

#### 3. Premium Unlock (In-App Purchase)

**User Experience:**
- Clear upgrade prompt in Settings
- Shows benefits of premium (SMS + WhatsApp)
- Standard iOS in-app purchase flow
- One-time $1.99 payment
- Instant unlock, no restore needed (receipt validated)
- "Premium" badge in Settings after purchase

**Technical Implementation:**
- StoreKit 2 for in-app purchases
- Product ID: `com.after6ix.AreYouDeadYet.premium`
- Receipt validation (on-device or server)
- Persist unlock state in UserDefaults + Keychain (backup)

#### 4. SMS Notifications (Premium)

**User Experience:**
- Premium users can add phone numbers for SMS
- SMS sent when emergency triggers
- Concise message with location link

**Technical Implementation:**
- Backend service required (Twilio)
- International SMS support
- Cost: ~$0.01-0.05 per SMS depending on country
- Character limit awareness (160 chars or concatenated)

**SMS Template:**
```
ALERT: [User Name] hasn't checked in for [X] days.
They may need help. Last location: [maps.apple.com/...]
```

#### 5. WhatsApp Notifications (Premium)

**User Experience:**
- Premium users can add WhatsApp numbers
- Message sent via WhatsApp Business API
- Rich message with location

**Technical Implementation:**
- WhatsApp Business API (via Twilio or Meta directly)
- Requires business verification
- Template messages must be pre-approved
- Cost: ~$0.005-0.05 per message

#### 6. Signal Notifications (Coming Soon)

**User Experience:**
- Premium users can add Signal numbers
- Message sent via Signal

**Technical Implementation:**
- Signal doesn't have official business API
- Options:
  - Use signal-cli (self-hosted, complex)
  - Wait for official API
  - Consider as "coming soon" initially
- **Recommendation:** Launch as "Coming Soon" in v1

#### 7. Rate Limiting (Abuse Prevention)

**User Experience:**
- Max 1 emergency notification per 7 days
- Max 5 emergency contacts
- Clear messaging when limit is reached
- Cooldown timer visible in app

**Technical Implementation:**
- Track last emergency timestamp in UserDefaults
- Backend enforces rate limits
- If limit exceeded: Email-only fallback (lowest cost)
- Rate limit resets after successful check-in post-cooldown

### P1 - Should Have

#### 1. Notification Preferences per Contact
- Choose which channels to use per contact
- Example: Mom gets SMS + Email, Friend gets Telegram only

#### 2. Delivery Status Dashboard
- Show delivery status for each notification
- Retry failed notifications
- "Last test sent" timestamp

#### 3. Test Notification
- Send test notification to verify setup works
- Available for all configured channels
- Rate limited (1 test per channel per day)

### P2 - Nice to Have

#### 1. Notification History
- Log of all sent notifications
- Delivery status and timestamps

#### 2. Multiple Premium Tiers
- Future: Family plan, annual subscription options

---

## Technical Architecture

### System Overview

```
┌─────────────────┐         ┌──────────────────────────────────┐
│   iOS App       │         │         Backend Service           │
│                 │         │                                    │
│  ┌───────────┐  │  HTTPS  │  ┌─────────────────────────────┐  │
│  │ Emergency │──┼────────▶│  │    Notification Service     │  │
│  │ Trigger   │  │         │  │                             │  │
│  └───────────┘  │         │  │  ┌─────┐ ┌─────┐ ┌───────┐ │  │
│                 │         │  │  │Email│ │ SMS │ │WhatsApp│ │  │
│  ┌───────────┐  │         │  │  └──┬──┘ └──┬──┘ └───┬───┘ │  │
│  │ StoreKit  │  │         │  │     │       │        │      │  │
│  │ Purchase  │  │         │  └─────┼───────┼────────┼──────┘  │
│  └───────────┘  │         │        │       │        │         │
└─────────────────┘         └────────┼───────┼────────┼─────────┘
                                     ▼       ▼        ▼
                              ┌──────────────────────────────┐
                              │      Third-Party Services     │
                              │                               │
                              │  SendGrid   Twilio   WhatsApp │
                              │  (Email)    (SMS)    (Meta)   │
                              │                               │
                              │  Telegram Bot    Signal-cli   │
                              │  (Free API)      (Future)     │
                              └──────────────────────────────┘
```

### Backend Requirements

**New Backend Service Needed:**
- REST API endpoint: `POST /api/emergency-notify`
- Authentication: Device token or API key
- Payload: User info, contacts, location, channels

**Recommended Stack:**
- Serverless (AWS Lambda, Vercel, or Cloudflare Workers)
- Low maintenance, pay-per-use
- Easy integration with notification providers

**API Contract:**
```json
POST /api/emergency-notify
{
  "user_name": "Gerald",
  "last_check_in": "2025-01-10T14:30:00Z",
  "location": {
    "latitude": 1.3521,
    "longitude": 103.8198
  },
  "contacts": [
    {
      "name": "Mom",
      "email": "mom@example.com",
      "phone": "+6591234567",
      "channels": ["email", "sms", "whatsapp"]
    }
  ],
  "is_premium": true
}
```

### iOS Changes

**New Files:**
```
Services/
├── PurchaseManager.swift      # StoreKit 2 handling
├── NotificationAPIService.swift # Backend API client
└── EmergencyContactService.swift # Updated to call API

Models/
└── EmergencyContact.swift     # Add channel preferences
```

**Updated EmergencyContact Model:**
```swift
struct EmergencyContact: Codable, Identifiable {
    let id: UUID
    var name: String
    var email: String?
    var phoneNumber: String?
    var telegramChatId: String?
    var enabledChannels: Set<NotificationChannel>
}

enum NotificationChannel: String, Codable, CaseIterable {
    case email
    case sms
    case whatsapp
    case telegram
    case signal
}
```

### Third-Party Service Costs

| Service | Provider | Cost per Message | Notes |
|---------|----------|------------------|-------|
| Email | SendGrid | Free (100/day) or $0.001 | Transactional tier |
| SMS | Twilio | $0.01-0.08 | Varies by country |
| WhatsApp | Twilio/Meta | $0.005-0.05 | Template messages |
| Telegram | Telegram API | Free | Bot API is free |
| Signal | signal-cli | Free (self-hosted) | Complex setup |

**Cost Analysis (per emergency event):**
- Average contacts per user: 2-3
- Average channels per contact: 2
- Cost per event (premium): ~$0.12-0.18
- Cost per event (free): ~$0.002 (email only)
- Net revenue after Apple cut (30%): ~$1.39
- Break-even: ~8-12 premium emergency events per user
- Rate limit (1/week) ensures sustainable cost structure

---

## User Flows

### Free User: Add Contact with Email/Telegram

```
1. User opens Settings
2. Taps "Add Emergency Contact"
3. Enters name and email (required)
4. Optionally sets up Telegram (free)
5. Sees note: "Upgrade to Premium for SMS & WhatsApp"
6. Saves contact
7. Email + Telegram channels available
```

### Free User: Upgrade to Premium

```
1. User sees "Upgrade to Premium" banner in Settings
2. Taps banner
3. Sees benefits:
   - SMS notifications
   - WhatsApp messages
4. Taps "Unlock for $1.99"
5. iOS payment sheet appears
6. Completes purchase
7. Confetti animation (optional)
8. Premium badge appears
9. SMS/WhatsApp options now available for contacts
```

### Premium User: Add Contact with Multiple Channels

```
1. User opens Settings (has Premium badge)
2. Taps "Add Emergency Contact"
3. Enters:
   - Name (required)
   - Email (optional)
   - Phone (optional)
   - At least one contact method required
4. Selects channels:
   - ☑ Email (free)
   - ☑ Telegram (free)
   - ☑ SMS (premium)
   - ☑ WhatsApp (premium)
   - ☐ Signal (coming soon)
5. Saves contact
```

### Telegram Setup Flow (Free for All Users)

```
1. User adds contact with Telegram
2. App generates unique link: aydy.app/tg/abc123
3. User sends link to emergency contact
4. Contact clicks link → Opens Telegram → Starts bot
5. Bot confirms: "You're now connected as emergency contact for [User]"
6. App receives webhook → Stores chat_id
7. Contact shows "Telegram: Connected" in app
```

### Emergency Trigger Flow

```
1. 48 hours pass without check-in
2. Background task fires
3. Check rate limit (max 1 per 7 days)
4. If rate limited → Email-only fallback
5. App gets current location
6. App calls backend: POST /api/emergency-notify
7. Backend processes each contact:
   - For each enabled channel:
     - Email → SendGrid (free)
     - Telegram → Bot API (free)
     - SMS → Twilio (premium only)
     - WhatsApp → Twilio/Meta (premium only)
8. Backend returns delivery status
9. App shows critical local notification
10. Rate limit cooldown starts (7 days)
```

---

## Design Decisions

### Why One-Time $1.99 vs Subscription?

| One-Time | Subscription |
|----------|--------------|
| Lower friction to purchase | Recurring revenue |
| No subscription fatigue | Predictable income |
| Matches user mental model ("I paid for the app") | More complex to manage |
| Simpler implementation | Churn management needed |

**Decision:** One-time purchase for MVP at $1.99 (better margin than $0.99). Can add subscription tier later for power users (family plans, etc.).

### Why Email + Telegram in Free Tier?

- Both are free/negligible to send
- Provides genuine value to free users
- Premium only gates channels that cost money (SMS, WhatsApp)
- Increases trust and conversion by offering real functionality for free

### Why SMS + WhatsApp are Premium?

- SMS costs $0.01-0.08 per message
- WhatsApp costs $0.005-0.05 per message
- Premium revenue covers these operational costs
- Users who need SMS/WhatsApp are willing to pay for reliability

### Why Rate Limiting?

- Prevents abuse (accidental or intentional)
- Controls cost exposure per user
- 1 emergency per 7 days is reasonable for real emergencies
- Email fallback ensures user is never completely blocked

### Why Signal is "Coming Soon"?

- No official business API
- Self-hosted signal-cli is complex
- Legal/ToS considerations
- Can add later when solution matures

---

## UI/UX Considerations

### Settings Screen Updates

```
┌─────────────────────────────────────┐
│ Settings                            │
├─────────────────────────────────────┤
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ ⭐ Upgrade to Premium    $1.99  │ │
│ │                                 │ │
│ │ Unlock SMS & WhatsApp           │ │
│ │ notifications for your contacts │ │
│ └─────────────────────────────────┘ │
│                                     │
│ EMERGENCY CONTACTS                  │
│ ┌─────────────────────────────────┐ │
│ │ 👤 Mom                          │ │
│ │    📧 Email ✓                   │ │
│ │    ✈️ Telegram ✓                │ │
│ │    📱 SMS 🔒                    │ │
│ │    💬 WhatsApp 🔒               │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ ➕ Add Contact                  │ │
│ └─────────────────────────────────┘ │
│                                     │
│ RATE LIMIT                          │
│ ┌─────────────────────────────────┐ │
│ │ ✓ Available (resets in 7 days)  │ │
│ └─────────────────────────────────┘ │
│                                     │
└─────────────────────────────────────┘

After Premium Purchase:

┌─────────────────────────────────────┐
│ Settings                     ⭐ PRO │
├─────────────────────────────────────┤
│                                     │
│ EMERGENCY CONTACTS                  │
│ ┌─────────────────────────────────┐ │
│ │ 👤 Mom                          │ │
│ │    📧 Email ✓                   │ │
│ │    ✈️ Telegram ✓                │ │
│ │    📱 SMS ✓                     │ │
│ │    💬 WhatsApp ✓                │ │
│ └─────────────────────────────────┘ │
│                                     │
└─────────────────────────────────────┘
```

### Add Contact Sheet

```
┌─────────────────────────────────────┐
│ Add Emergency Contact               │
├─────────────────────────────────────┤
│                                     │
│ Name                                │
│ ┌─────────────────────────────────┐ │
│ │ Mom                             │ │
│ └─────────────────────────────────┘ │
│                                     │
│ Email                               │
│ ┌─────────────────────────────────┐ │
│ │ mom@example.com                 │ │
│ └─────────────────────────────────┘ │
│                                     │
│ Phone                               │
│ ┌─────────────────────────────────┐ │
│ │ +65 9123 4567                   │ │
│ └─────────────────────────────────┘ │
│                                     │
│ NOTIFICATION CHANNELS               │
│ ┌─────────────────────────────────┐ │
│ │ ☑ Email         (Free)          │ │
│ │ ☐ Telegram      (Free) [Setup]  │ │
│ │ ☑ SMS           (Premium) 🔒    │ │
│ │ ☑ WhatsApp      (Premium) 🔒    │ │
│ │ ☐ Signal        [Coming Soon]   │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │           Save Contact          │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

---

## Implementation Phases

### Phase 1: Backend + Email (Week 1-2)
- [ ] Set up backend service (serverless)
- [ ] Integrate SendGrid for email
- [ ] Create email templates
- [ ] Update iOS app to call backend API
- [ ] Test email delivery

### Phase 2: In-App Purchase (Week 2-3)
- [ ] Set up App Store Connect product
- [ ] Implement StoreKit 2 in app
- [ ] Add premium UI elements
- [ ] Test purchase flow

### Phase 3: SMS + WhatsApp (Week 3-4)
- [ ] Integrate Twilio for SMS
- [ ] Integrate WhatsApp Business API
- [ ] Update contact model for channels
- [ ] Premium-gate these features
- [ ] Test international delivery

### Phase 4: Telegram (Week 4-5)
- [ ] Create Telegram bot
- [ ] Build linking flow
- [ ] Implement webhook handling
- [ ] Test end-to-end

### Phase 5: Polish + Launch (Week 5-6)
- [ ] Add test notification feature
- [ ] Error handling and retry logic
- [ ] Analytics and monitoring
- [ ] App Store review

---

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| SMS costs exceed revenue | Revenue loss | Rate limiting (1/week), $1.99 price point |
| WhatsApp API approval delayed | Launch delay | Launch with Email + Telegram + SMS first |
| Low conversion rate | Revenue below costs | Free tier has real value (Email + Telegram), incentivizes trust |
| Delivery failures | User trust lost | Implement retries, multi-channel fallback |
| Backend downtime during emergency | Critical failure | Use reliable provider, health monitoring |
| Rate limit abuse complaints | User frustration | Clear UI explanation, email fallback always works |

---

## Open Questions

1. Should premium be lifetime or per-device?
2. Do we need server-side receipt validation or is on-device sufficient?
3. Should free users see a "test" button for email?
4. What happens if premium user's SMS fails? Auto-fallback to email?
5. Do we need a web dashboard for delivery monitoring?

---

## Appendix

### Competitive Analysis

| App | Free Tier | Paid Tier |
|-----|-----------|-----------|
| Life360 | Location sharing | $5/mo - crash detection |
| bSafe | SOS button | $3/mo - live GPS |
| Snug Safety | 3 contacts | $2/mo - unlimited |

**Our positioning:** Simpler, cheaper, one-time payment.

### SMS Cost by Country (Twilio)

| Country | Cost per SMS |
|---------|--------------|
| USA | $0.0079 |
| UK | $0.04 |
| Singapore | $0.0435 |
| Australia | $0.055 |
| India | $0.04 |

### References

- [StoreKit 2 Documentation](https://developer.apple.com/documentation/storekit/in-app_purchase)
- [Twilio SMS API](https://www.twilio.com/docs/sms)
- [WhatsApp Business API](https://developers.facebook.com/docs/whatsapp)
- [Telegram Bot API](https://core.telegram.org/bots/api)
- [SendGrid Email API](https://docs.sendgrid.com/)
