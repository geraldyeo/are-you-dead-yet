import Foundation

struct EmergencyContact: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var phoneNumber: String
    var email: String?

    init(id: UUID = UUID(), name: String, phoneNumber: String, email: String? = nil) {
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
        self.email = email
    }
}
