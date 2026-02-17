import SwiftUI

struct RootView: View {
    @EnvironmentObject var auth: AuthViewModel

    var body: some View {
        if auth.isLoggedIn {
            MainCalendarHost(auth: auth)
        } else {
            LoginScreen()
        }
    }
}
