import Foundation

@MainActor
final class CalendarViewModel: ObservableObject {
    @Published var types: [EventTypeDTO] = []
    @Published var events: [EventDTO] = []
    @Published var error: String?

    private let auth: AuthViewModel

    init(auth: AuthViewModel) {
        self.auth = auth
    }

    func loadTypes() async {
        // 4) offline cache: pokaż od razu cache
        let cached = CacheStore.shared.loadTypes()
        if !cached.isEmpty { self.types = cached }

        error = nil
        do {
            let access = try await auth.ensureAccessToken()
            let fresh = try await APIClient.shared.getTypes(accessToken: access)
            self.types = fresh
            CacheStore.shared.saveTypes(fresh)
        } catch {
            // jeśli sieć padła, zostaje cache
            self.error = error.localizedDescription
        }
    }

    func loadEvents(from: Date, toExclusive: Date) async {
        error = nil

        let fromStr = DateUtils.ymdUTC(from)
        let toInclusive = Calendar.current.date(byAdding: .day, value: -1, to: toExclusive) ?? from
        let toStr = DateUtils.ymdUTC(toInclusive)

        // 4) offline cache: pokaż od razu cache dla zakresu
        let cached = CacheStore.shared.loadEvents(from: fromStr, to: toStr)
        if !cached.isEmpty { self.events = cached }

        do {
            let access = try await auth.ensureAccessToken()
            let fresh = try await APIClient.shared.getEvents(accessToken: access, from: fromStr, to: toStr)
            self.events = fresh
            CacheStore.shared.saveEvents(fresh, from: fromStr, to: toStr)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func createEvent(_ payload: EventUpsert) async {
        error = nil
        do {
            let access = try await auth.ensureAccessToken()
            try await APIClient.shared.createEvent(accessToken: access, payload: payload)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func updateEvent(id: Int, payload: EventUpsert) async {
        error = nil
        do {
            let access = try await auth.ensureAccessToken()
            try await APIClient.shared.updateEvent(accessToken: access, id: id, payload: payload)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func deleteEvent(id: Int) async {
        error = nil
        do {
            let access = try await auth.ensureAccessToken()
            try await APIClient.shared.deleteEvent(accessToken: access, id: id)
            NotificationScheduler.shared.cancel(eventId: id)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func syncNotificationsForLoadedEvents() {
        for e in events {
            guard let start = DateUtils.parseISO(e.startAt) else { continue }
            NotificationScheduler.shared.cancel(eventId: e.id)
            NotificationScheduler.shared.schedule15MinBefore(eventId: e.id, title: e.title, startDate: start)
        }
    }
}
