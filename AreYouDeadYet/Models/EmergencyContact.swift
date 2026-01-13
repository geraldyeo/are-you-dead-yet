import Foundation
import Contacts

// MARK: - Notification Channel

enum NotificationChannel: String, Codable, CaseIterable, Identifiable {
    case email
    case telegram
    case sms
    case whatsapp

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .email: return "Email"
        case .telegram: return "Telegram"
        case .sms: return "SMS"
        case .whatsapp: return "WhatsApp"
        }
    }

    var isPremium: Bool {
        switch self {
        case .email, .telegram: return false
        case .sms, .whatsapp: return true
        }
    }

    var systemImage: String {
        switch self {
        case .email: return "envelope.fill"
        case .telegram: return "paperplane.fill"
        case .sms: return "message.fill"
        case .whatsapp: return "phone.bubble.fill"
        }
    }
}

// MARK: - Emergency Contact

struct EmergencyContact: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var phoneNumber: String?
    var email: String?
    var telegramChatId: String?
    var enabledChannels: Set<NotificationChannel>

    /// Validation: contact must have at least one way to reach them
    var isValid: Bool {
        phoneNumber != nil || email != nil
    }

    /// Check if contact has a specific notification channel available
    func canUseChannel(_ channel: NotificationChannel) -> Bool {
        switch channel {
        case .email:
            return email != nil && !email!.isEmpty
        case .telegram:
            return telegramChatId != nil && !telegramChatId!.isEmpty
        case .sms, .whatsapp:
            return phoneNumber != nil && !phoneNumber!.isEmpty
        }
    }

    init(
        id: UUID = UUID(),
        name: String,
        phoneNumber: String? = nil,
        email: String? = nil,
        telegramChatId: String? = nil,
        enabledChannels: Set<NotificationChannel> = [.email]
    ) {
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
        self.email = email
        self.telegramChatId = telegramChatId
        self.enabledChannels = enabledChannels
    }

    /// Initialize from a CNContact (iOS Contacts framework)
    init(from cnContact: CNContact, phoneNumber: String? = nil, email: String? = nil) {
        self.id = UUID()

        // Combine given name and family name
        let nameParts = [cnContact.givenName, cnContact.familyName].filter { !$0.isEmpty }
        self.name = nameParts.joined(separator: " ")

        // Use provided values or pick first available
        if let phone = phoneNumber {
            self.phoneNumber = phone
        } else {
            self.phoneNumber = cnContact.phoneNumbers.first?.value.stringValue
        }

        if let emailAddr = email {
            self.email = emailAddr
        } else {
            self.email = cnContact.emailAddresses.first?.value as String?
        }

        self.telegramChatId = nil

        // Default to email if available
        if self.email != nil {
            self.enabledChannels = [.email]
        } else {
            self.enabledChannels = []
        }
    }
}

