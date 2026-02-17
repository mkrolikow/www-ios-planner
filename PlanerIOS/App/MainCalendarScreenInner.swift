import SwiftUI

struct MainCalendarScreenInner: View {
    @EnvironmentObject var auth: AuthViewModel
    @ObservedObject var vm: CalendarViewModel

    @State private var selectedDate = Date()
    @State private var mode: Mode = .month
    @State private var editorMode: EventEditorView.Mode? = nil

    enum Mode: String, CaseIterable {
        case month = "Miesiąc"
        case day = "Dzień"
        case week = "Tydzień"
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
                        let cal = Calendar.current
                        let start = cal.date(bySettingHour: 9, minute: 0, second: 0, of: selectedDate) ?? selectedDate
                        editorMode = .create(defaultStart: start)
                    }
                }
            }
            .task {
                _ = await NotificationScheduler.shared.requestPermission()
                await reloadCurrentRange()
            }
            .sheet(item: Binding(
                get: { editorMode.map { EditorSheet(mode: $0) } },
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
