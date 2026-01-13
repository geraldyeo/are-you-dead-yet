import Foundation
import CoreLocation
import MessageUI

class EmergencyContactService {
    static let shared = EmergencyContactService()

    private init() {}

    func notifyEmergencyContacts(with location: CLLocation?) {
        let contacts = loadEmergencyContacts()

        guard !contacts.isEmpty else {
            print("No emergency contacts configured")
            return
        }

        let locationString: String
        if let location = location {
            let mapsURL = "https://maps.apple.com/?ll=\(location.coordinate.latitude),\(location.coordinate.longitude)"
            locationString = "Last known location: \(mapsURL)"
        } else {
            locationString = "Location unavailable"
        }

        let message = """
        URGENT: This is an automated message from "Are You Dead Yet?" app.

        The user has not checked in for 2 consecutive days.

        \(locationString)

        Please try to contact them or check on their wellbeing.
        """

        for contact in contacts {
            sendSMS(to: contact.phoneNumber, message: message)

            if let email = contact.email {
                sendEmail(to: email, subject: "URGENT: Check-in Alert", body: message)
            }
        }

        NotificationService.shared.sendEmergencyAlert()
    }

    private func loadEmergencyContacts() -> [EmergencyContact] {
        guard let data = UserDefaults.standard.data(forKey: "emergencyContacts"),
              let contacts = try? JSONDecoder().decode([EmergencyContact].self, from: data) else {
            return []
        }
        return contacts
    }

    private func sendSMS(to phoneNumber: String, message: String) {
        // In a real app, this would use a backend service like Twilio
        // For now, we'll use URL scheme to open Messages app (requires user interaction)
        let smsURL = "sms:\(phoneNumber)&body=\(message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"

        if let url = URL(string: smsURL) {
            // Note: This will only work when app is in foreground
            // For background notifications, you'd need a backend service
            DispatchQueue.main.async {
                // UIApplication.shared.open(url) // Uncomment for actual SMS
                print("Would send SMS to \(phoneNumber): \(message)")
            }
        }
    }

    private func sendEmail(to email: String, subject: String, body: String) {
        // In a real app, this would use a backend service like SendGrid
        // For now, we'll use URL scheme to open Mail app
        let mailURL = "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"

        if let url = URL(string: mailURL) {
            DispatchQueue.main.async {
                // UIApplication.shared.open(url) // Uncomment for actual email
                print("Would send email to \(email): \(subject)")
            }
        }
    }
}
