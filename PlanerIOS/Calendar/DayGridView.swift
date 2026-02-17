import SwiftUI

struct DayGridView: View {
    let date: Date
    let events: [EventDTO]
    let types: [EventTypeDTO]
    let onTapEvent: (EventDTO) -> Void
    let onTapEmpty: (Date) -> Void

    private let hourHeight: CGFloat = 64
    private let leftGutter: CGFloat = 52

    var body: some View {
        GeometryReader { geo in
            ScrollView(.vertical) {
                ZStack(alignment: .topLeading) {
                    gridBackground(width: geo.size.width)

                    // warstwa kliknięć w puste miejsce
                    Color.clear
                        .contentShape(Rectangle())
                        .frame(height: hourHeight * 24)
                        .onTapGesture { location in
                            // SwiftUI nie daje location w onTapGesture bez Gesture,
                            // więc robimy "tap -> zaokrąglamy do najbliższej godziny" w oparciu o scroll.
                            // MVP: tworzymy event na 1h od 09:00 jeśli user tapnie w widok.
                            let cal = Calendar.current
                            let start = cal.date(bySettingHour: 9, minute: 0, second: 0, of: date) ?? date
                            onTapEmpty(start)
                        }

                    // wydarzenia
                    ForEach(eventsForThisDay(), id: \.id) { e in
                        eventBlock(e, totalWidth: geo.size.width)
                    }
                }
                .frame(height: hourHeight * 24)
                .padding(.leading, 0)
            }
        }
    }

    private func eventsForThisDay() -> [EventDTO] {
        let start = DateUtils.startOfDay(date)
        let end = DateUtils.endOfDayExclusive(date)
        return events.filter { e in
            guard let s = DateUtils.parseISO(e.startAt) else { return false }
            return s >= start && s < end
        }
        .sorted { (a, b) in
            (DateUtils.parseISO(a.startAt) ?? .distantPast) < (DateUtils.parseISO(b.startAt) ?? .distantPast)
        }
    }

    private func minutesFromStartOfDay(_ d: Date) -> CGFloat {
        let start = DateUtils.startOfDay(date)
        let mins = d.timeIntervalSince(start) / 60.0
        return CGFloat(max(0, min(24*60, mins)))
    }

    private func gridBackground(width: CGFloat) -> some View {
        VStack(spacing: 0) {
            ForEach(0..<24, id: \.self) { hour in
                HStack(spacing: 0) {
                    Text(String(format: "%02d:00", hour))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: leftGutter, alignment: .trailing)
                        .padding(.trailing, 6)

                    Rectangle()
                        .fill(Color.secondary.opacity(0.15))
                        .frame(height: 1)
                        .overlay(alignment: .bottom) {
                            // linia półgodziny
                            Rectangle()
                                .fill(Color.secondary.opacity(0.10))
                                .frame(height: 1)
                                .offset(y: hourHeight/2)
                        }
                }
                .frame(height: hourHeight)
            }
        }
        .frame(width: width, alignment: .leading)
    }

    private func eventBlock(_ e: EventDTO, totalWidth: CGFloat) -> some View {
        let contentWidth = totalWidth - leftGutter - 12
        let x = leftGutter + 8

        let start = DateUtils.parseISO(e.startAt) ?? date
        let end = DateUtils.parseISO(e.endAt) ?? start.addingTimeInterval(3600)

        let top = minutesFromStartOfDay(start) / 60.0 * hourHeight
        let height = max(28, (minutesFromStartOfDay(end) - minutesFromStartOfDay(start)) / 60.0 * hourHeight)

        let colorHex = e.type?.colorHex ?? "#007AFF"
        let color = Color(hex: colorHex) ?? .blue

        return VStack(alignment: .leading, spacing: 4) {
            Text(e.title).font(.subheadline).bold().lineLimit(1)
            if let t = e.type?.name {
                Text(t).font(.caption2).opacity(0.9)
            }
            if !e.allDay {
                Text(timeRange(e)).font(.caption2).opacity(0.9)
            }
        }
        .padding(8)
        .frame(width: contentWidth, height: height, alignment: .topLeading)
        .background(color.opacity(0.22))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.55), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .position(x: x + contentWidth/2, y: top + height/2)
        .onTapGesture { onTapEvent(e) }
    }

    private func timeRange(_ e: EventDTO) -> String {
        guard let s = DateUtils.parseISO(e.startAt), let en = DateUtils.parseISO(e.endAt) else { return "" }
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return "\(f.string(from: s))–\(f.string(from: en))"
    }
}
