import SwiftUI

struct DayGridView: View {
    let date: Date
    let events: [EventDTO]
    let types: [EventTypeDTO]
    let onTapEvent: (EventDTO) -> Void
    let onTapEmpty: (Date) -> Void

    private let hourHeight: CGFloat = 64
    private let leftGutter: CGFloat = 52
    private let paddingRight: CGFloat = 10
    private let snapMinutes: Int = 15 // 1) “dokładność” tapu (15 min)

    var body: some View {
        GeometryReader { geo in
            ScrollView(.vertical) {
                ZStack(alignment: .topLeading) {
                    gridBackground(width: geo.size.width)

                    // 1) Precyzyjny tap: DragGesture(0) daje lokalizację
                    Color.clear
                        .contentShape(Rectangle())
                        .frame(height: hourHeight * 24)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onEnded { v in
                                    let y = v.location.y
                                    let start = dateFromTapY(y)
                                    onTapEmpty(start)
                                }
                        )

                    // 2) Overlapping layout
                    let dayEvents = eventsForThisDay()
                    let blocks = layoutBlocks(dayEvents)

                    ForEach(blocks, id: \.event.id) { b in
                        eventBlock(b, totalWidth: geo.size.width)
                    }
                }
                .frame(height: hourHeight * 24)
            }
        }
    }

    // MARK: - Day filtering
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

    // MARK: - Tap -> time
    private func dateFromTapY(_ y: CGFloat) -> Date {
        // y w obrębie 0..(24*hourHeight)
        let clamped = max(0, min(hourHeight * 24, y))
        let minsRaw = (clamped / (hourHeight * 24)) * 1440.0
        let mins = Int(minsRaw)

        // snap do 15 min
        let snapped = (mins / snapMinutes) * snapMinutes

        let startOfDay = DateUtils.startOfDay(date)
        return Calendar.current.date(byAdding: .minute, value: snapped, to: startOfDay) ?? startOfDay
    }

    private func minutesFromStartOfDay(_ d: Date) -> CGFloat {
        let start = DateUtils.startOfDay(date)
        let mins = d.timeIntervalSince(start) / 60.0
        return CGFloat(max(0, min(24*60, mins)))
    }

    // MARK: - Grid background (linie siatki)
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

    // MARK: - 2) Overlapping layout
    struct Block {
        let event: EventDTO
        let start: Date
        let end: Date
        let col: Int
        let colCount: Int
    }

    private func layoutBlocks(_ dayEvents: [EventDTO]) -> [Block] {
        // “greedy coloring” per grupy konfliktów
        // 1) zamień na przedziały
        var intervals: [(EventDTO, Date, Date)] = dayEvents.compactMap { e in
            guard let s = DateUtils.parseISO(e.startAt) else { return nil }
            let en = DateUtils.parseISO(e.endAt) ?? s.addingTimeInterval(3600)
            return (e, s, max(en, s.addingTimeInterval(60))) // min 1 min
        }

        intervals.sort { $0.1 < $1.1 }

        // 2) buduj grupy konfliktów (connected components)
        var groups: [[(EventDTO, Date, Date)]] = []
        var current: [(EventDTO, Date, Date)] = []
        var currentMaxEnd: Date = .distantPast

        for it in intervals {
            if current.isEmpty {
                current = [it]
                currentMaxEnd = it.2
            } else {
                if it.1 < currentMaxEnd { // konflikt z grupą
                    current.append(it)
                    if it.2 > currentMaxEnd { currentMaxEnd = it.2 }
                } else {
                    groups.append(current)
                    current = [it]
                    currentMaxEnd = it.2
                }
            }
        }
        if !current.isEmpty { groups.append(current) }

        // 3) dla każdej grupy: przypisz kolumny
        var out: [Block] = []
        for g in groups {
            // przypisz kolumnę: trzymaj end per kolumna
            var colEnds: [Date] = []
            var tmp: [(EventDTO, Date, Date, Int)] = []

            let sorted = g.sorted { $0.1 < $1.1 }
            for (e, s, en) in sorted {
                var placed = false
                for i in 0..<colEnds.count {
                    if s >= colEnds[i] {
                        colEnds[i] = en
                        tmp.append((e, s, en, i))
                        placed = true
                        break
                    }
                }
                if !placed {
                    colEnds.append(en)
                    tmp.append((e, s, en, colEnds.count - 1))
                }
            }

            let colCount = colEnds.count
            for (e, s, en, c) in tmp {
                out.append(Block(event: e, start: s, end: en, col: c, colCount: colCount))
            }
        }

        return out
    }

    // MARK: - Block rendering
    private func eventBlock(_ b: Block, totalWidth: CGFloat) -> some View {
        let contentWidth = totalWidth - leftGutter - paddingRight - 12
        let xBase = leftGutter + 8

        let top = minutesFromStartOfDay(b.start) / 60.0 * hourHeight
        let height = max(28, (minutesFromStartOfDay(b.end) - minutesFromStartOfDay(b.start)) / 60.0 * hourHeight)

        // 2) kolumny
        let colW = contentWidth / CGFloat(max(1, b.colCount))
        let x = xBase + CGFloat(b.col) * colW

        let colorHex = b.event.type?.colorHex ?? "#007AFF"
        let color = Color(hex: colorHex) ?? .blue

        return VStack(alignment: .leading, spacing: 4) {
            Text(b.event.title).font(.subheadline).bold().lineLimit(1)

            if let t = b.event.type?.name {
                Text(t).font(.caption2).opacity(0.9)
            }

            if !b.event.allDay {
                Text(timeRange(b.start, b.end)).font(.caption2).opacity(0.9)
            }
        }
        .padding(8)
        .frame(width: max(70, colW - 6), height: height, alignment: .topLeading)
        .background(color.opacity(0.22))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.55), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .position(x: x + (max(70, colW - 6))/2, y: top + height/2)
        .onTapGesture { onTapEvent(b.event) }
    }

    private func timeRange(_ s: Date, _ e: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return "\(f.string(from: s))–\(f.string(from: e))"
    }
}
