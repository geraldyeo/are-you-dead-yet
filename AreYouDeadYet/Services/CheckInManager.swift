import Foundation
import Combine

class CheckInManager: ObservableObject {
    @Published private(set) var checkInHistory: [CheckIn] = []
    @Published private(set) var emergencyContacts: [EmergencyContact] = []

    private let checkInHistoryKey = "checkInHistory"
    private let emergencyContactsKey = "emergencyContacts"

    /// Maximum number of emergency contacts allowed
    static let maxContacts = 3

    var lastCheckIn: CheckIn? {
        checkInHistory.first
    }

    var hasCheckedInToday: Bool {
        guard let lastCheckIn = lastCheckIn else { return false }
        return Calendar.current.isDateInToday(lastCheckIn.date)
    }

    var daysSinceLastCheckIn: Int {
        guard let lastCheckIn = lastCheckIn else { return Int.max }
        let components = Calendar.current.dateComponents([.day], from: lastCheckIn.date, to: Date())
        return components.day ?? Int.max
    }

    /// Check if user can add more emergency contacts
    var canAddContact: Bool {
        emergencyContacts.count < Self.maxContacts
    }

    /// Number of remaining contact slots
    var remainingContactSlots: Int {
        max(0, Self.maxContacts - emergencyContacts.count)
    }

    init() {
        loadCheckInHistory()
        loadEmergencyContacts()
    }

    func checkIn() {
        let newCheckIn = CheckIn()
        checkInHistory.insert(newCheckIn, at: 0)

        // Keep only last 30 check-ins
        if checkInHistory.count > 30 {
            checkInHistory = Array(checkInHistory.prefix(30))
        }

        saveCheckInHistory()
        rescheduleNotifications()
    }

    /// Result of attempting to add a contact
    enum AddContactResult {
        case success
        case limitReached
        case duplicate(existingName: String)
    }

    /// Check if a contact is a duplicate (matches by phone or email)
    func isDuplicateContact(_ contact: EmergencyContact) -> EmergencyContact? {
        emergencyContacts.first { existing in
            // Match by phone number (if both have one)
            if let existingPhone = existing.phoneNumber,
               let newPhone = contact.phoneNumber,
               !existingPhone.isEmpty && !newPhone.isEmpty {
                // Normalize phone numbers for comparison (remove non-digits)
                let normalizedExisting = existingPhone.filter { $0.isNumber }
                let normalizedNew = newPhone.filter { $0.isNumber }
                if normalizedExisting == normalizedNew {
                    return true
                }
            }

            // Match by email (if both have one)
            if let existingEmail = existing.email,
               let newEmail = contact.email,
               !existingEmail.isEmpty && !newEmail.isEmpty {
                if existingEmail.lowercased() == newEmail.lowercased() {
                    return true
                }
            }

            return false
        }
    }

    /// Add an emergency contact with validation
    @discardableResult
    func addEmergencyContact(_ contact: EmergencyContact) -> AddContactResult {
        // Check limit
        guard canAddContact else {
            return .limitReached
        }

        // Check for duplicate
        if let existing = isDuplicateContact(contact) {
            return .duplicate(existingName: existing.name)
        }

        emergencyContacts.append(contact)
        saveEmergencyContacts()
        return .success
    }

    func removeEmergencyContacts(at offsets: IndexSet) {
        emergencyContacts.remove(atOffsets: offsets)
        saveEmergencyContacts()
    }

    func updateEmergencyContact(_ contact: EmergencyContact) {
        if let index = emergencyContacts.firstIndex(where: { $0.id == contact.id }) {
            emergencyContacts[index] = contact
            saveEmergencyContacts()
        }
    }

    private func loadCheckInHistory() {
        guard let data = UserDefaults.standard.data(forKey: checkInHistoryKey),
              let history = try? JSONDecoder().decode([CheckIn].self, from: data) else {
            return
        }
        checkInHistory = history
    }

    private func saveCheckInHistory() {
        guard let data = try? JSONEncoder().encode(checkInHistory) else { return }
        UserDefaults.standard.set(data, forKey: checkInHistoryKey)
    }

    private func loadEmergencyContacts() {
        guard let data = UserDefaults.standard.data(forKey: emergencyContactsKey),
              let contacts = try? JSONDecoder().decode([EmergencyContact].self, from: data) else {
            return
        }
        emergencyContacts = contacts
    }

    private func saveEmergencyContacts() {
        guard let data = try? JSONEncoder().encode(emergencyContacts) else { return }
        UserDefaults.standard.set(data, forKey: emergencyContactsKey)
    }

    private func rescheduleNotifications() {
        NotificationService.shared.scheduleCheckInReminder(for: Date())
    }
}
