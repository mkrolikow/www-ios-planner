import Foundation

final class APIClient {
    static let shared = APIClient()

    // ustaw swój backend:
    private let baseURL = URL(string: "http://localhost:8080")!

    private var urlSession: URLSession { .shared }

    func login(email: String, password: String) async throws -> LoginResponse {
        let url = baseURL.appendingPathComponent("/api/auth/login")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(["email": email, "password": password])
        return try await send(req, as: LoginResponse.self)
    }

    func refresh(refreshToken: String) async throws -> RefreshResponse {
        let url = baseURL.appendingPathComponent("/api/auth/refresh")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(["refreshToken": refreshToken])
        return try await send(req, as: RefreshResponse.self)
    }

    func getTypes(accessToken: String) async throws -> [EventTypeDTO] {
        let url = baseURL.appendingPathComponent("/api/types")
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return try await send(req, as: [EventTypeDTO].self)
    }

    func getEvents(accessToken: String, from: String, to: String) async throws -> [EventDTO] {
        var comps = URLComponents(url: baseURL.appendingPathComponent("/api/events"), resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            URLQueryItem(name: "from", value: from),
            URLQueryItem(name: "to", value: to)
        ]
        var req = URLRequest(url: comps.url!)
        req.httpMethod = "GET"
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return try await send(req, as: [EventDTO].self)
    }

    func createEvent(accessToken: String, payload: EventUpsert) async throws {
        let url = baseURL.appendingPathComponent("/api/events")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        req.httpBody = try JSONEncoder().encode(payload)
        _ = try await sendRaw(req)
    }

    func updateEvent(accessToken: String, id: Int, payload: EventUpsert) async throws {
        let url = baseURL.appendingPathComponent("/api/events/\(id)")
        var req = URLRequest(url: url)
        req.httpMethod = "PUT"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        req.httpBody = try JSONEncoder().encode(payload)
        _ = try await sendRaw(req)
    }

    func deleteEvent(accessToken: String, id: Int) async throws {
        let url = baseURL.appendingPathComponent("/api/events/\(id)")
        var req = URLRequest(url: url)
        req.httpMethod = "DELETE"
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        _ = try await sendRaw(req)
    }

    // MARK: - helpers
    private func send<T: Decodable>(_ req: URLRequest, as: T.Type) async throws -> T {
        let (data, resp) = try await urlSession.data(for: req)
        try assertOK(resp, data)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func sendRaw(_ req: URLRequest) async throws -> Data {
        let (data, resp) = try await urlSession.data(for: req)
        try assertOK(resp, data)
        return data
    }

    private func assertOK(_ resp: URLResponse, _ data: Data) throws {
        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        if !(200...299).contains(http.statusCode) {
            let msg = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            throw NSError(domain: "API", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
        }
    }
}
