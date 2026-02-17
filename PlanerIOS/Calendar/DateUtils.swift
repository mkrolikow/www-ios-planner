import Foundation
import SwiftUI

enum DateUtils {
    static func ymdUTC(_ date: Date) -> String {
        let f = DateFormatter()
        f.calendar = .current
        f.locale = .current
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    static func startOfDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    static func endOfDayExclusive(_ date: Date) -> Date {
        let start = Calendar.current.startOfDay(for: date)
        return Calendar.current.date(byAdding: .day, value: 1, to: start)!
    }

    static func startOfWeek(_ date: Date) -> Date {
        var cal = Calendar.current
        cal.firstWeekday = 2 // poniedziałek
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return cal.date(from: comps) ?? cal.startOfDay(for: date)
    }

    static func endOfWeekExclusive(_ date: Date) -> Date {
        let start = startOfWeek(date)
        return Calendar.current.date(byAdding: .day, value: 7, to: start)!
    }

    static func parseISO(_ iso: String) -> Date? {
        ISO8601DateFormatter().date(from: iso)
    }
}

extension Color {
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = Int(s, radix: 16) else { return nil }

        let r = Double((v >> 16) & 0xFF) / 255.0
        let g = Double((v >> 8) & 0xFF) / 255.0
        let b = Double(v & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
