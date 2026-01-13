import Foundation
import UserNotifications

class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published var isAuthorized = false

    private let center = UNUserNotificationCenter.current()

    init() {
        checkAuthorizationStatus()
    }

    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
            }
            if let error = error {
                print("Notification authorization error: \(error)")
            }
        }
    }

    func checkAuthorizationStatus() {
        center.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    func scheduleCheckInReminder(for lastCheckInDate: Date) {
        // Cancel existing reminders
        center.removePendingNotificationRequests(withIdentifiers: ["checkInReminder"])

        // Schedule reminder for 24 hours after last check-in
        let reminderDate = Calendar.current.date(byAdding: .day, value: 1, to: lastCheckInDate)!

        let content = UNMutableNotificationContent()
        content.title = "Are You Dead Yet?"
        content.body = "You haven't checked in today. Tap to confirm you're still alive!"
        content.sound = .default
        content.badge = 1

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(identifier: "checkInReminder", content: content, trigger: trigger)

        center.add(request) { error in
            if let error = error {
                print("Error scheduling reminder: \(error)")
            }
        }
    }

    func sendMissedCheckInReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Check In Required!"
        content.body = "You missed your daily check-in. Please open the app and tap the button."
        content.sound = .defaultCritical
        content.badge = 1
        content.interruptionLevel = .timeSensitive

        let request = UNNotificationRequest(
            identifier: "missedCheckIn-\(UUID().uuidString)",
            content: content,
            trigger: nil // Deliver immediately
        )

        center.add(request)
    }

    func sendEmergencyAlert() {
        let content = UNMutableNotificationContent()
        content.title = "Emergency Alert Sent"
        content.body = "Your emergency contacts have been notified with your location."
        content.sound = .defaultCritical
        content.interruptionLevel = .critical

        let request = UNNotificationRequest(
            identifier: "emergencyAlert-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        center.add(request)
    }

    func clearBadge() {
        center.setBadgeCount(0)
    }
}
