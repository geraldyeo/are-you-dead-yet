import Foundation
import Combine

class CheckInManager: ObservableObject {
    @Published private(set) var checkInHistory: [CheckIn] = []
    @Published private(set) var emergencyContacts: [EmergencyContact] = []

    private let checkInHistoryKey = "checkInHistory"
    private let emergencyContactsKey = "emergencyContacts"

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

    func addEmergencyContact(_ contact: EmergencyContact) {
        emergencyContacts.append(contact)
        saveEmergencyContacts()
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
