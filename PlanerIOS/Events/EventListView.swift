import SwiftUI

struct EventListView: View {
    let date: Date
    let events: [EventDTO]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Wydarzenia: \(date.formatted(date: .abbreviated, time: .omitted))")
                .font(.headline)

            if events.isEmpty {
                Text("Brak wydarzeń").foregroundStyle(.secondary)
            } else {
                List(events) { e in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(e.title).font(.headline)
                        if let t = e.type {
                            Text("\(t.name) • \(t.colorHex)").font(.caption).foregroundStyle(.secondary)
                        }
                        Text("\(e.startAt) → \(e.endAt)").font(.caption).foregroundStyle(.secondary)
                    }
                }
                .listStyle(.plain)
                .frame(minHeight: 220)
            }
        }
    }
}
