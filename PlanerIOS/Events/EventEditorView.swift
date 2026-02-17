import SwiftUI

struct EventEditorView: View {
    enum Mode {
        case create(defaultStart: Date)
        case edit(event: EventDTO)
    }

    @Environment(\.dismiss) private var dismiss

    @ObservedObject var vm: CalendarViewModel
    let mode: Mode
    let afterSaveReload: () async -> Void

    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var typeId: Int? = nil
    @State private var allDay: Bool = false
    @State private var start: Date = Date()
    @State private var end: Date = Date().addingTimeInterval(3600)

    @State private var err: String?
    @State private var saving = false

    var body: some View {
        NavigationStack {
            Form {
                if let err { Text(err).foregroundStyle(.red) }

                Section("Szczegóły") {
                    TextField("Tytuł", text: $title)
                    Toggle("Cały dzień", isOn: $allDay)

                    Picker("Typ", selection: Binding(
                        get: { typeId ?? -1 },
                        set: { typeId = ($0 == -1) ? nil : $0 }
                    )) {
                        Text("(Brak typu)").tag(-1)
                        ForEach(vm.types, id: \.id) { t in
                            HStack {
                                Circle()
                                    .fill(Color(hex: t.color_hex) ?? .blue)
                                    .frame(width: 10, height: 10)
                                Text(t.name)
                            }.tag(t.id)
                        }
                    }
                }

                Section("Czas") {
                    if allDay {
                        DatePicker("Data", selection: $start, displayedComponents: .date)
                        DatePicker("Koniec (data)", selection: $end, displayedComponents: .date)
                    } else {
                        DatePicker("Start", selection: $start, displayedComponents: [.date, .hourAndMinute])
                        DatePicker("Koniec", selection: $end, displayedComponents: [.date, .hourAndMinute])
                    }
                }

                Section("Notatki") {
                    TextEditor(text: $notes).frame(minHeight: 120)
                }

                if case .edit(let ev) = mode {
                    Section {
                        Button(role: .destructive) {
                            Task { await delete(ev) }
                        } label: {
                            Text("Usuń wydarzenie")
                        }
                    }
                }
            }
            .navigationTitle(titleForMode())
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Anuluj") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(saving ? "..." : "Zapisz") {
                        Task { await save() }
                    }
                    .disabled(saving)
                }
            }
            .onAppear { hydrate() }
        }
    }

    private func titleForMode() -> String {
        switch mode {
        case .create: return "Dodaj wydarzenie"
        case .edit: return "Edytuj wydarzenie"
        }
    }

    private func hydrate() {
        switch mode {
        case .create(let defaultStart):
            title = ""
            notes = ""
            typeId = nil
            allDay = false
            start = defaultStart
            end = defaultStart.addingTimeInterval(3600)

        case .edit(let e):
            title = e.title
            notes = e.notes ?? ""
            typeId = e.typeId
            allDay = e.allDay
            start = DateUtils.parseISO(e.startAt) ?? Date()
            end = DateUtils.parseISO(e.endAt) ?? start.addingTimeInterval(3600)
        }
    }

    private func validate() -> Bool {
        err = nil
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            err = "Tytuł jest wymagany."
            return false
        }
        if !(start < end) {
            err = "Koniec musi być po początku."
            return false
        }
        return true
    }

    private func buildPayload() -> EventUpsert {
        var s = start
        var e = end

        if allDay {
            // normalizacja: start 00:00, end exclusive następny dzień 00:00
            let st = DateUtils.startOfDay(start)
            let en = DateUtils.startOfDay(end)
            s = st
            e = Calendar.current.date(byAdding: .day, value: 1, to: en) ?? en.addingTimeInterval(86400)
        }

        return EventUpsert(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes.isEmpty ? nil : notes,
            typeId: typeId,
            startAt: s.toISOString(),
            endAt: e.toISOString(),
            allDay: allDay
        )
    }

    private func save() async {
        guard validate() else { return }
        saving = true
        defer { saving = false }

        let payload = buildPayload()

        switch mode {
        case .create:
            await vm.createEvent(payload)

        case .edit(let ev):
            // update -> podmieniamy też notyfikację
            NotificationScheduler.shared.cancel(eventId: ev.id)
            await vm.updateEvent(id: ev.id, payload: payload)
        }

        // odśwież i ustaw notyfikacje dla listy
        await afterSaveReload()
        vm.syncNotificationsForLoadedEvents()

        // zaplanuj notyfikację dla konkretnego eventu w edycji (najpewniej po reloadu już jest)
        dismiss()
    }

    private func delete(_ ev: EventDTO) async {
        saving = true
        defer { saving = false }

        await vm.deleteEvent(id: ev.id)
        await afterSaveReload()
        dismiss()
    }
}

private extension Date {
    func toISOString() -> String {
        ISO8601DateFormatter().string(from: self)
    }
}
