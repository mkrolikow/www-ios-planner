import SwiftUI
import UIKit

struct MonthCalendarView: UIViewRepresentable {
    var onDateSelected: (Date) -> Void

    func makeUIView(context: Context) -> UICalendarView {
        let v = UICalendarView()
        v.calendar = Calendar.current
        v.locale = Locale(identifier: "pl_PL")
        v.availableDateRange = DateInterval(start: .distantPast, end: .distantFuture)
        v.selectionBehavior = UICalendarSelectionSingleDate(delegate: context.coordinator)
        return v
    }

    func updateUIView(_ uiView: UICalendarView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onDateSelected: onDateSelected) }

    final class Coordinator: NSObject, UICalendarSelectionSingleDateDelegate {
        let onDateSelected: (Date) -> Void
        init(onDateSelected: @escaping (Date) -> Void) { self.onDateSelected = onDateSelected }

        func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
            guard let dc = dateComponents, let date = Calendar.current.date(from: dc) else { return }
            onDateSelected(date)
        }
    }
}
