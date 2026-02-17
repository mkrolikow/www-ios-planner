import SwiftUI

struct MainCalendarScreen: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var selectedDate = Date()
    @State private var events: [EventDTO] = []
    @State private var types: [EventTypeDTO] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                MonthCalendarView { date in
                    selectedDate = date
                    Task { await loadDay(date: date) }
                }
                .frame(height: 360)

                EventListView(date: selectedDate, events: events)
            }
            .padding()
            .navigationTitle("Kalendarz")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Wyloguj") { auth.logout() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("+") {
                        // tu podepniemy EventEditorView
                    }
                }
            }
            .task {
                _ = await NotificationScheduler.shared.requestPermission()
                await loadTypes()
                await loadDay(date: selectedDate)
            }
        }
    }

    func loadTypes() async {
        do {
            let access = try await auth.ensureAccessToken()
            types = try await APIClient.shared.getTypes(accessToken: access)
        } catch { /* obsłuż UI później */ }
    }

    func loadDay(date: Date) async {
        do {
            let cal = Calendar.current
            let from = cal.startOfDay(for: date)
            let to = cal.date(byAdding: .day, value: 0, to: from)! // ten sam dzień
            let access = try await auth.ensureAccessToken()
            let list = try await APIClient.shared.getEvents(
                accessToken: access,
                from: ymd(from),
                to: ymd(to)
            )
            events = list
        } catch { /* obsłuż UI później */ }
    }

    func ymd(_ d: Date) -> String {
        let f = DateFormatter()
        f.calendar = .current
        f.locale = .current
        f.timeZone = TimeZone(secondsFromGMT: 0) // backend trzyma UTC
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: d)
    }
}
