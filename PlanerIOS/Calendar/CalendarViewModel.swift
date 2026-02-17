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
        error = nil
        do {
            let access = try await auth.ensureAccessToken()
            types = try await APIClient.shared.getTypes(accessToken: access)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func loadEvents(from: Date, toExclusive: Date) async {
        error = nil
        do {
            let access = try await auth.ensureAccessToken()
            let fromStr = DateUtils.ymdUTC(from)
            // API ma "to" jako inclusive YYYY-MM-DD, więc bierzemy dzień przed exclusive:
            let toInclusive = Calendar.current.date(byAdding: .day, value: -1, to: toExclusive) ?? from
            let toStr = DateUtils.ymdUTC(toInclusive)
            events = try await APIClient.shared.getEvents(accessToken: access, from: fromStr, to: toStr)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func createEvent(_ payload: EventUpsert) async {
        error = nil
        do {
            let access = try await auth.ensureAccessToken()
            try await APIClient.shared.createEvent(accessToken: access, payload: payload)

            // Po create: najprościej odświeżyć zakres widoku (caller to zrobi),
            // a notyfikacje ustawimy na podstawie odświeżonej listy eventów.
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

    // Po załadowaniu/zmianie eventów możesz zsynchronizować powiadomienia lokalne
    func syncNotificationsForLoadedEvents() {
        for e in events {
            guard let start = DateUtils.parseISO(e.startAt) else { continue }
            NotificationScheduler.shared.cancel(eventId: e.id)
            NotificationScheduler.shared.schedule15MinBefore(eventId: e.id, title: e.title, startDate: start)
        }
    }

    func typeColor(for typeId: Int?) -> String {
        guard let id = typeId, let t = types.first(where: { $0.id == id }) else { return "#007AFF" }
        return t.color_hex
    }
}
