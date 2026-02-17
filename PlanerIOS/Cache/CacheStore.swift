import Foundation

final class CacheStore {
    static let shared = CacheStore()

    private let fm = FileManager.default

    private func baseDir() -> URL {
        let dir = fm.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let appDir = dir.appendingPathComponent("planer-cache", isDirectory: true)
        if !fm.fileExists(atPath: appDir.path) {
            try? fm.createDirectory(at: appDir, withIntermediateDirectories: true)
        }
        return appDir
    }

    // MARK: - Types
    private func typesURL() -> URL {
        baseDir().appendingPathComponent("types.json")
    }

    func loadTypes() -> [EventTypeDTO] {
        let url = typesURL()
        guard let data = try? Data(contentsOf: url) else { return [] }
        return (try? JSONDecoder().decode([EventTypeDTO].self, from: data)) ?? []
    }

    func saveTypes(_ types: [EventTypeDTO]) {
        let url = typesURL()
        guard let data = try? JSONEncoder().encode(types) else { return }
        try? data.write(to: url, options: [.atomic])
    }

    // MARK: - Events for range
    private func eventsURL(from: String, to: String) -> URL {
        baseDir().appendingPathComponent("events_\(from)_\(to).json")
    }

    func loadEvents(from: String, to: String) -> [EventDTO] {
        let url = eventsURL(from: from, to: to)
        guard let data = try? Data(contentsOf: url) else { return [] }
        return (try? JSONDecoder().decode([EventDTO].self, from: data)) ?? []
    }

    func saveEvents(_ events: [EventDTO], from: String, to: String) {
        let url = eventsURL(from: from, to: to)
        guard let data = try? JSONEncoder().encode(events) else { return }
        try? data.write(to: url, options: [.atomic])
    }
}
