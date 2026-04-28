import Foundation

final class UserSessionStore: ObservableObject {
    private enum Keys {
        static let isLoggedIn = "user_session_is_logged_in"
        static let kakaoUserId = "user_session_kakao_user_id"
        static let nickname = "user_session_nickname"
        static let profileImageURL = "user_session_profile_image_url"
        static let backendAccessToken = "user_session_backend_access_token"
        static let backendRefreshToken = "user_session_backend_refresh_token"
        static let backendTokenType = "user_session_backend_token_type"
        static let backendExpiresIn = "user_session_backend_expires_in"
    }

    @Published var isLoggedIn = false
    @Published var kakaoUserId: Int64?
    @Published var nickname: String = ""
    @Published var profileImageURL: String?
    @Published var backendAccessToken: String?
    @Published var backendRefreshToken: String?
    @Published var backendTokenType: String?
    @Published var backendExpiresIn: Int64?

    init() {
        let defaults = UserDefaults.standard
        isLoggedIn = defaults.bool(forKey: Keys.isLoggedIn)

        let storedUserId = defaults.object(forKey: Keys.kakaoUserId) as? NSNumber
        kakaoUserId = storedUserId?.int64Value
        nickname = defaults.string(forKey: Keys.nickname) ?? ""
        profileImageURL = defaults.string(forKey: Keys.profileImageURL)
        backendAccessToken = defaults.string(forKey: Keys.backendAccessToken)
        backendRefreshToken = defaults.string(forKey: Keys.backendRefreshToken)
        backendTokenType = defaults.string(forKey: Keys.backendTokenType)
        let storedExpiresIn = defaults.object(forKey: Keys.backendExpiresIn) as? NSNumber
        backendExpiresIn = storedExpiresIn?.int64Value
    }

    func update(
        kakaoUserId: Int64?,
        nickname: String,
        profileImageURL: String?,
        backendAccessToken: String? = nil,
        backendRefreshToken: String? = nil,
        backendTokenType: String? = nil,
        backendExpiresIn: Int64? = nil
    ) {
        self.isLoggedIn = true
        self.kakaoUserId = kakaoUserId
        self.nickname = nickname
        self.profileImageURL = profileImageURL
        self.backendAccessToken = backendAccessToken
        self.backendRefreshToken = backendRefreshToken
        self.backendTokenType = backendTokenType
        self.backendExpiresIn = backendExpiresIn

        let defaults = UserDefaults.standard
        defaults.set(true, forKey: Keys.isLoggedIn)

        if let kakaoUserId {
            defaults.set(NSNumber(value: kakaoUserId), forKey: Keys.kakaoUserId)
        } else {
            defaults.removeObject(forKey: Keys.kakaoUserId)
        }

        defaults.set(nickname, forKey: Keys.nickname)

        if let profileImageURL {
            defaults.set(profileImageURL, forKey: Keys.profileImageURL)
        } else {
            defaults.removeObject(forKey: Keys.profileImageURL)
        }

        if let backendAccessToken {
            defaults.set(backendAccessToken, forKey: Keys.backendAccessToken)
        } else {
            defaults.removeObject(forKey: Keys.backendAccessToken)
        }

        if let backendRefreshToken {
            defaults.set(backendRefreshToken, forKey: Keys.backendRefreshToken)
        } else {
            defaults.removeObject(forKey: Keys.backendRefreshToken)
        }

        if let backendTokenType {
            defaults.set(backendTokenType, forKey: Keys.backendTokenType)
        } else {
            defaults.removeObject(forKey: Keys.backendTokenType)
        }

        if let backendExpiresIn {
            defaults.set(NSNumber(value: backendExpiresIn), forKey: Keys.backendExpiresIn)
        } else {
            defaults.removeObject(forKey: Keys.backendExpiresIn)
        }
    }

    func updateProfile(userId: Int64?, nickname: String?, profileImageURL: String?) {
        if let userId {
            kakaoUserId = userId
            UserDefaults.standard.set(NSNumber(value: userId), forKey: Keys.kakaoUserId)
        }

        if let nickname {
            self.nickname = nickname
            UserDefaults.standard.set(nickname, forKey: Keys.nickname)
        }

        self.profileImageURL = profileImageURL
        if let profileImageURL {
            UserDefaults.standard.set(profileImageURL, forKey: Keys.profileImageURL)
        } else {
            UserDefaults.standard.removeObject(forKey: Keys.profileImageURL)
        }
    }

    func updateBackendTokens(accessToken: String?, tokenType: String?, expiresIn: Int64?) {
        backendAccessToken = accessToken
        backendTokenType = tokenType
        backendExpiresIn = expiresIn

        let defaults = UserDefaults.standard

        if let accessToken {
            defaults.set(accessToken, forKey: Keys.backendAccessToken)
        } else {
            defaults.removeObject(forKey: Keys.backendAccessToken)
        }

        if let tokenType {
            defaults.set(tokenType, forKey: Keys.backendTokenType)
        } else {
            defaults.removeObject(forKey: Keys.backendTokenType)
        }

        if let expiresIn {
            defaults.set(NSNumber(value: expiresIn), forKey: Keys.backendExpiresIn)
        } else {
            defaults.removeObject(forKey: Keys.backendExpiresIn)
        }
    }

    func logout() {
        isLoggedIn = false
        kakaoUserId = nil
        nickname = ""
        profileImageURL = nil
        backendAccessToken = nil
        backendRefreshToken = nil
        backendTokenType = nil
        backendExpiresIn = nil

        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: Keys.isLoggedIn)
        defaults.removeObject(forKey: Keys.kakaoUserId)
        defaults.removeObject(forKey: Keys.nickname)
        defaults.removeObject(forKey: Keys.profileImageURL)
        defaults.removeObject(forKey: Keys.backendAccessToken)
        defaults.removeObject(forKey: Keys.backendRefreshToken)
        defaults.removeObject(forKey: Keys.backendTokenType)
        defaults.removeObject(forKey: Keys.backendExpiresIn)
    }
}
