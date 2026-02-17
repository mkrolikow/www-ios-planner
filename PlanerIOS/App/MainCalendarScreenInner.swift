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

                // 3) Nawigacja datą
                dateNavBar()

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
            .onChange(of: mode) { _, _ in
                Task { await reloadCurrentRange() }
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

    @ViewBuilder
    private func dateNavBar() -> some View {
        HStack(spacing: 10) {
            Button {
                shiftDate(-1)
            } label: { Image(systemName: "chevron.left") }
            .buttonStyle(.bordered)

            Button("Dziś") {
                selectedDate = Date()
                Task { await reloadCurrentRange() }
            }
            .buttonStyle(.bordered)

            Button {
                shiftDate(1)
            } label: { Image(systemName: "chevron.right") }
            .buttonStyle(.bordered)

            Spacer()

            Text(titleForSelectedDate())
                .font(.headline)
        }
    }

    private func titleForSelectedDate() -> String {
        switch mode {
        case .month:
            return selectedDate.formatted(.dateTime.year().month(.wide))
        case .day:
            return selectedDate.formatted(.dateTime.weekday(.wide).day().month(.wide).year())
        case .week:
            let start = DateUtils.startOfWeek(selectedDate)
            let end = Calendar.current.date(byAdding: .day, value: 6, to: start) ?? start
            return "\(start.formatted(.dateTime.day().month(.abbreviated))) – \(end.formatted(.dateTime.day().month(.abbreviated).year()))"
        }
    }

    private func shiftDate(_ dir: Int) {
        let cal = Calendar.current
        switch mode {
        case .month:
            selectedDate = cal.date(byAdding: .month, value: dir, to: selectedDate) ?? selectedDate
        case .day:
            selectedDate = cal.date(byAdding: .day, value: dir, to: selectedDate) ?? selectedDate
        case .week:
            selectedDate = cal.date(byAdding: .day, value: 7 * dir, to: selectedDate) ?? selectedDate
        }
        Task { await reloadCurrentRange() }
    }

    private func reloadCurrentRange() async {
        await vm.loadTypes()

        switch mode {
        case .month:
            let cal = Calendar.current
            let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: selectedDate)) ?? DateUtils.startOfDay(selectedDate)
            let from = cal.date(byAdding: .day, value: -7, to: monthStart) ?? monthStart
            let toEx = cal.date(byAdding: .day, value: 45, to: monthStart) ?? DateUtils.endOfDayExclusive(selectedDate)
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
