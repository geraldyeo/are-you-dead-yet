import Foundation

struct CheckIn: Codable, Identifiable {
    let id: UUID
    let date: Date

    init(id: UUID = UUID(), date: Date = Date()) {
        self.id = id
        self.date = date
    }
}
