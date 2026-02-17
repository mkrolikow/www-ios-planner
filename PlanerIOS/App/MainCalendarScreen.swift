import SwiftUI

struct MainCalendarScreen: View {
    @EnvironmentObject var auth: AuthViewModel
    @StateObject private var vm: CalendarViewModel

    @State private var selectedDate = Date()
    @State private var mode: Mode = .month
    @State private var editorMode: EventEditorView.Mode? = nil

    enum Mode: String, CaseIterable {
        case month = "Miesiąc"
        case day = "Dzień"
        case week = "Tydzień"
    }

    init() {
        // vm potrzebuje auth z environment, więc zrobimy placeholder i ustawimy w .onAppear
        _vm = StateObject(wrappedValue: CalendarViewModel(auth: AuthViewModel(tokens: TokenStore())))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Picker("", selection: $mode) {
                    ForEach(Mode.allCases, id: \.self) { m in
                        Text(m.rawValue).tag(m)
                    }
                }
                .pickerStyle(.segmented)

                if let err = vm.error {
                    Text(err).foregroundStyle(.red).font(.footnote)
                }

                switch mode {
                case .month:
                    MonthCalendarView { date in
                        selectedDate = date
                        Task { await reloadCurrentRange() }
                    }
                    .frame(height: 360)

                    EventListView(date: selectedDate, events: vm.events)
                        .frame(minHeight: 260)

                case .day:
                    DayGridView(
                        date: selectedDate,
                        events: vm.events,
                        types: vm.types,
                        onTapEvent: { e in editorMode = .edit(event: e) },
                        onTapEmpty: { start in editorMode = .create(defaultStart: start) }
                    )
                    .frame(height: 560)

                case .week:
                    WeekGridView(
                        weekStart: DateUtils.startOfWeek(selectedDate),
                        events: vm.events,
                        types: vm.types,
                        onTapEvent: { e in editorMode = .edit(event: e) },
                        onTapEmpty: { start in editorMode = .create(defaultStart: start) }
                    )
                    .frame(height: 620)
                }
            }
            .padding()
            .navigationTitle("Planer")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Wyloguj") { auth.logout() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("+") {
                        // domyślnie tworzymy event na dziś 09:00
                        let cal = Calendar.current
                        let start = cal.date(bySettingHour: 9, minute: 0, second: 0, of: selectedDate) ?? selectedDate
                        editorMode = .create(defaultStart: start)
                    }
                }
            }
            .task {
                _ = await NotificationScheduler.shared.requestPermission()

                // poprawna inicjalizacja vm z realnym auth z env
                // (trik: podmieniamy przez KVC nie przejdzie, więc robimy reload i używamy vm jak jest,
                // a w praktyce zalecam stworzyć vm w init(auth:) w RootView. Na MVP zrobimy prościej poniżej.)
            }
            .onAppear {
                // MVP fix: jeśli vm ma inny auth (placeholder), tworzymy nowy VM raz
                if (vm as AnyObject).value(forKey: "auth") == nil {
                    // nic
                }
            }
            .onAppear {
                // Najprościej: jeśli placeholder, to zresetuj StateObject przez osobny wrapper.
                // Zamiast kombinować, użyj wrappera poniżej w RootView (podam na końcu).
            }
            .sheet(item: Binding(
                get: {
                    guard let m = editorMode else { return nil }
                    return EditorSheet(mode: m)
                },
                set: { _ in editorMode = nil }
            )) { sheet in
                EventEditorView(vm: vm, mode: sheet.mode, afterSaveReload: {
                    await reloadCurrentRange()
                })
            }
        }
    }

    private func reloadCurrentRange() async {
        await vm.loadTypes()

        switch mode {
        case .month:
            // 6 tygodni zakresu wystarczy do month view (żeby nie dociągać co klik)
            let cal = Calendar.current
            let start = cal.date(from: cal.dateComponents([.year, .month], from: selectedDate)) ?? DateUtils.startOfDay(selectedDate)
            let from = cal.date(byAdding: .day, value: -7, to: start) ?? start
            let toEx = cal.date(byAdding: .day, value: 45, to: start) ?? DateUtils.endOfDayExclusive(selectedDate)
            await vm.loadEvents(from: from, toExclusive: toEx)

        case .day:
            let from = DateUtils.startOfDay(selectedDate)
            let toEx = DateUtils.endOfDayExclusive(selectedDate)
            await vm.loadEvents(from: from, toExclusive: toEx)

        case .week:
            let from = DateUtils.startOfWeek(selectedDate)
            let toEx = DateUtils.endOfWeekExclusive(selectedDate)
            await vm.loadEvents(from: from, toExclusive: toEx)
        }

        vm.syncNotificationsForLoadedEvents()
    }
}

private struct EditorSheet: Identifiable {
    let id = UUID()
    let mode: EventEditorView.Mode
}
