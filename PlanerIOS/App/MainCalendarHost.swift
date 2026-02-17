import SwiftUI

struct MainCalendarHost: View {
    @EnvironmentObject var auth: AuthViewModel
    @StateObject private var vm: CalendarViewModel

    init() {
        // tymczasowo, potem nadpiszemy w init(auth:) przez drugi init
        _vm = StateObject(wrappedValue: CalendarViewModel(auth: AuthViewModel(tokens: TokenStore())))
    }

    init(auth: AuthViewModel) {
        _vm = StateObject(wrappedValue: CalendarViewModel(auth: auth))
    }

    var body: some View {
        MainCalendarScreenInner(vm: vm)
    }
}
