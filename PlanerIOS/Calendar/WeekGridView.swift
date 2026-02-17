import SwiftUI

struct WeekGridView: View {
    let weekStart: Date // poniedziałek
    let events: [EventDTO]
    let types: [EventTypeDTO]
    let onTapEvent: (EventDTO) -> Void
    let onTapEmpty: (Date) -> Void

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 12) {
                ForEach(0..<7, id: \.self) { i in
                    let day = Calendar.current.date(byAdding: .day, value: i, to: weekStart) ?? weekStart
                    VStack(alignment: .leading, spacing: 8) {
                        Text(day.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))
                            .font(.headline)

                        DayGridView(
                            date: day,
                            events: events,
                            types: types,
                            onTapEvent: onTapEvent,
                            onTapEmpty: onTapEmpty
                        )
                        .frame(width: 360, height: 520)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.secondary.opacity(0.18)))
                    }
                    .frame(width: 360)
                }
            }
            .padding(.horizontal, 12)
        }
    }
}
