import SwiftUI

struct RootView: View {
    @EnvironmentObject var auth: AuthViewModel

    var body: some View {
        if auth.isLoggedIn {
            MainCalendarScreen()
        } else {
            LoginScreen()
        }
    }
}
