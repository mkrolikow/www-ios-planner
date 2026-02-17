import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var error: String?

    let tokens: TokenStore

    init(tokens: TokenStore) {
        self.tokens = tokens
        self.isLoggedIn = !tokens.accessToken.isEmpty
    }

    func login(email: String, password: String) async {
        error = nil
        do {
            let res = try await APIClient.shared.login(email: email, password: password)
            tokens.set(access: res.accessToken, refresh: res.refreshToken)
            isLoggedIn = true
        } catch {
            self.error = error.localizedDescription
        }
    }

    func logout() {
        tokens.clear()
        isLoggedIn = false
    }

    func ensureAccessToken() async throws -> String {
        if !tokens.accessToken.isEmpty { return tokens.accessToken }
        if tokens.refreshToken.isEmpty { throw NSError(domain: "Auth", code: 401) }

        let refreshed = try await APIClient.shared.refresh(refreshToken: tokens.refreshToken)
        tokens.setAccess(refreshed.accessToken)
        return refreshed.accessToken
    }
}
