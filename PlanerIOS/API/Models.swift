import Foundation

struct UserDTO: Codable {
    let id: Int
    let email: String
    let name: String?
    let role: String
}

struct LoginResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let user: UserDTO
}

struct RefreshResponse: Codable {
    let accessToken: String
}

struct EventTypeDTO: Codable, Identifiable {
    let id: Int
    let user_id: Int?
    let name: String
    let color_hex: String
}

struct EventDTO: Codable, Identifiable {
    let id: Int
    let title: String
    let notes: String?
    let typeId: Int?
    let startAt: String
    let endAt: String
    let allDay: Bool
    let type: EventTypeMini?

    struct EventTypeMini: Codable {
        let id: Int
        let name: String
        let colorHex: String
    }
}

struct EventUpsert: Codable {
    let title: String
    let notes: String?
    let typeId: Int?
    let startAt: String
    let endAt: String
    let allDay: Bool
}
