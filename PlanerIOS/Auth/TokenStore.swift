import Foundation

final class TokenStore: ObservableObject {
    @Published var accessToken: String = ""
    @Published var refreshToken: String = ""

    private let kAccess = "planer_access"
    private let kRefresh = "planer_refresh"

    init() {
        accessToken = UserDefaults.standard.string(forKey: kAccess) ?? ""
        refreshToken = UserDefaults.standard.string(forKey: kRefresh) ?? ""
    }

    func set(access: String, refresh: String) {
        accessToken = access
        refreshToken = refresh
        UserDefaults.standard.set(access, forKey: kAccess)
        UserDefaults.standard.set(refresh, forKey: kRefresh)
    }

    func setAccess(_ access: String) {
        accessToken = access
        UserDefaults.standard.set(access, forKey: kAccess)
    }

    func clear() {
        accessToken = ""
        refreshToken = ""
        UserDefaults.standard.removeObject(forKey: kAccess)
        UserDefaults.standard.removeObject(forKey: kRefresh)
    }
}
