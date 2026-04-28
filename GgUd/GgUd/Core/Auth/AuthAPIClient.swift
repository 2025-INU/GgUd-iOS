import Foundation

struct KakaoSdkLoginRequest: Codable {
    let kakaoAccessToken: String
}

struct TokenRefreshRequest: Codable {
    let refreshToken: String
}

struct BackendLoginResponse: Codable {
    let accessToken: String?
    let refreshToken: String?
    let tokenType: String?
    let expiresIn: Int64?
    let userId: Int64?
    let nickname: String?
}

struct TokenRefreshResponse: Codable {
    let accessToken: String?
    let tokenType: String?
    let expiresIn: Int64?
}

struct BackendUserResponse: Codable {
    let id: Int64?
    let nickname: String?
    let profileImageUrl: String?
    let email: String?
}

struct UpdateProfileRequest: Codable {
    let nickname: String
    let profileImageUrl: String?
}

enum AuthAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case server(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "서버 주소가 올바르지 않습니다."
        case .invalidResponse:
            return "서버 응답을 해석하지 못했습니다."
        case let .server(statusCode, message):
            return "서버 오류(\(statusCode)): \(message)"
        }
    }
}

final class AuthAPIClient {
    static let shared = AuthAPIClient()

    private let baseURL = "http://3.37.196.242"
    private let session: URLSession

    private init(session: URLSession = .shared) {
        self.session = session
    }

    func loginWithKakao(accessToken: String, completion: @escaping (Result<BackendLoginResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/v1/auth/kakao/login") else {
            completion(.failure(AuthAPIError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(KakaoSdkLoginRequest(kakaoAccessToken: accessToken))
        } catch {
            completion(.failure(error))
            return
        }

        session.dataTask(with: request) { data, response, error in
            if let error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(AuthAPIError.invalidResponse))
                return
            }

            let responseData = data ?? Data()

            guard (200...299).contains(httpResponse.statusCode) else {
                let message = String(data: responseData, encoding: .utf8) ?? "알 수 없는 오류"
                completion(.failure(AuthAPIError.server(statusCode: httpResponse.statusCode, message: message)))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(BackendLoginResponse.self, from: responseData)
                completion(.success(decoded))
            } catch {
                completion(.failure(error))
            }
        }
        .resume()
    }

    func logout(accessToken: String, tokenType: String = "Bearer", completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/v1/auth/logout") else {
            completion(.failure(AuthAPIError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("\(tokenType) \(accessToken)", forHTTPHeaderField: "Authorization")

        session.dataTask(with: request) { _, response, error in
            if let error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(AuthAPIError.invalidResponse))
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(AuthAPIError.server(statusCode: httpResponse.statusCode, message: "로그아웃 요청 실패")))
                return
            }

            completion(.success(()))
        }
        .resume()
    }

    func refreshToken(refreshToken: String, completion: @escaping (Result<TokenRefreshResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/v1/auth/refresh") else {
            completion(.failure(AuthAPIError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(TokenRefreshRequest(refreshToken: refreshToken))
        } catch {
            completion(.failure(error))
            return
        }

        session.dataTask(with: request) { data, response, error in
            if let error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(AuthAPIError.invalidResponse))
                return
            }

            let responseData = data ?? Data()

            guard (200...299).contains(httpResponse.statusCode) else {
                let message = String(data: responseData, encoding: .utf8) ?? "알 수 없는 오류"
                completion(.failure(AuthAPIError.server(statusCode: httpResponse.statusCode, message: message)))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(TokenRefreshResponse.self, from: responseData)
                completion(.success(decoded))
            } catch {
                completion(.failure(error))
            }
        }
        .resume()
    }

    func getMyInfo(accessToken: String, tokenType: String = "Bearer", completion: @escaping (Result<BackendUserResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/v1/users/me") else {
            completion(.failure(AuthAPIError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("\(tokenType) \(accessToken)", forHTTPHeaderField: "Authorization")

        session.dataTask(with: request) { data, response, error in
            if let error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(AuthAPIError.invalidResponse))
                return
            }

            let responseData = data ?? Data()

            guard (200...299).contains(httpResponse.statusCode) else {
                let message = String(data: responseData, encoding: .utf8) ?? "알 수 없는 오류"
                completion(.failure(AuthAPIError.server(statusCode: httpResponse.statusCode, message: message)))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(BackendUserResponse.self, from: responseData)
                completion(.success(decoded))
            } catch {
                completion(.failure(error))
            }
        }
        .resume()
    }

    func updateMyProfile(
        accessToken: String,
        tokenType: String = "Bearer",
        nickname: String,
        profileImageUrl: String? = nil,
        completion: @escaping (Result<BackendUserResponse, Error>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/api/v1/users/me") else {
            completion(.failure(AuthAPIError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("\(tokenType) \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(
                UpdateProfileRequest(
                    nickname: nickname,
                    profileImageUrl: profileImageUrl
                )
            )
        } catch {
            completion(.failure(error))
            return
        }

        session.dataTask(with: request) { data, response, error in
            if let error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(AuthAPIError.invalidResponse))
                return
            }

            let responseData = data ?? Data()

            guard (200...299).contains(httpResponse.statusCode) else {
                let message = String(data: responseData, encoding: .utf8) ?? "알 수 없는 오류"
                completion(.failure(AuthAPIError.server(statusCode: httpResponse.statusCode, message: message)))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(BackendUserResponse.self, from: responseData)
                completion(.success(decoded))
            } catch {
                completion(.failure(error))
            }
        }
        .resume()
    }

    func uploadProfileImage(
        accessToken: String,
        tokenType: String = "Bearer",
        imageData: Data,
        mimeType: String,
        fileName: String = "profile.jpg",
        completion: @escaping (Result<BackendUserResponse, Error>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/api/v1/users/me/profile-image") else {
            completion(.failure(AuthAPIError.invalidURL))
            return
        }

        let boundary = "Boundary-\(UUID().uuidString)"

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("\(tokenType) \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = makeMultipartBody(
            boundary: boundary,
            fieldName: "image",
            fileName: fileName,
            mimeType: mimeType,
            fileData: imageData
        )

        session.dataTask(with: request) { data, response, error in
            if let error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(AuthAPIError.invalidResponse))
                return
            }

            let responseData = data ?? Data()

            guard (200...299).contains(httpResponse.statusCode) else {
                let message = String(data: responseData, encoding: .utf8) ?? "알 수 없는 오류"
                completion(.failure(AuthAPIError.server(statusCode: httpResponse.statusCode, message: message)))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(BackendUserResponse.self, from: responseData)
                completion(.success(decoded))
            } catch {
                completion(.failure(error))
            }
        }
        .resume()
    }

    private func makeMultipartBody(
        boundary: String,
        fieldName: String,
        fileName: String,
        mimeType: String,
        fileData: Data
    ) -> Data {
        var body = Data()
        let lineBreak = "\r\n"

        body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\(lineBreak)".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\(lineBreak)\(lineBreak)".data(using: .utf8)!)
        body.append(fileData)
        body.append(lineBreak.data(using: .utf8)!)
        body.append("--\(boundary)--\(lineBreak)".data(using: .utf8)!)

        return body
    }
}
