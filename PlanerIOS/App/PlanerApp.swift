import SwiftUI

@main
struct PlanerApp: App {
    @StateObject private var tokens = TokenStore()
    @StateObject private var auth: AuthViewModel

    init() {
        let t = TokenStore()
        _tokens = StateObject(wrappedValue: t)
        _auth = StateObject(wrappedValue: AuthViewModel(tokens: t))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(tokens)
                .environmentObject(auth)
        }
    }
}
