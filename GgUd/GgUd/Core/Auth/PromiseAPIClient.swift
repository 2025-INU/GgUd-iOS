import Foundation

struct PromiseListResponse: Codable {
    let content: [BackendPromise]
}

struct BackendPromise: Codable {
    let id: Int64?
    let title: String?
    let description: String?
    let promiseDateTime: String?
    let status: String?
    let inviteCode: String?
    let inviteExpiredAt: String?
    let maxParticipants: Int?
    let hostId: Int64?
    let hostNickname: String?
    let participantCount: Int64?
    let confirmedLatitude: Double?
    let confirmedLongitude: Double?
    let confirmedPlaceName: String?
    let createdAt: String?
}

struct CreatePromiseRequest: Codable {
    let title: String
    let description: String?
    let promiseDateTime: String
}

struct PromiseParticipantResponse: Codable {
    let id: Int64?
    let userId: Int64?
    let nickname: String?
    let profileImageUrl: String?
    let departureLatitude: Double?
    let departureLongitude: Double?
    let departureAddress: String?
    let locationSubmitted: Bool?
    let host: Bool?
    let joinedAt: String?
}

struct PromiseSummaryResponse: Codable {
    let id: Int64?
    let title: String?
    let promiseDateTime: String?
    let hostId: Int64?
    let hostNickname: String?
}

struct CoordinateResponse: Codable {
    let latitude: Double?
    let longitude: Double?
}

struct ParticipantTravelInfoResponse: Codable {
    let userId: Int64?
    let nickname: String?
    let departureAddress: String?
    let travelTimeMinutes: Int?
    let distanceMeters: Int?
}

struct StationRecommendationResponse: Codable {
    let stationId: Int64?
    let stationName: String?
    let lineName: String?
    let latitude: Double?
    let longitude: Double?
    let distanceFromMidpoint: Double?
    let averageDistanceFromParticipants: Double?
    let participantTravelInfos: [ParticipantTravelInfoResponse]?
    let averageTravelTimeMinutes: Int?
}

struct MidpointRecommendationResponse: Codable {
    let calculatedMidpoint: CoordinateResponse?
    let recommendedStations: [StationRecommendationResponse]?
    let participantCount: Int?
}

struct UpdateDepartureRequest: Codable {
    let latitude: Double
    let longitude: Double
    let address: String?
}

final class PromiseAPIClient {
    static let shared = PromiseAPIClient()

    private let baseURL = "http://3.37.196.242"
    private let session: URLSession

    private init(session: URLSession = .shared) {
        self.session = session
    }

    func getMyPromises(
        accessToken: String,
        tokenType: String = "Bearer",
        page: Int = 0,
        size: Int = 50,
        completion: @escaping (Result<[BackendPromise], Error>) -> Void
    ) {
        var components = URLComponents(string: "\(baseURL)/api/v1/promises")
        components?.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "size", value: "\(size)")
        ]

        guard let url = components?.url else {
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
                let decoded = try JSONDecoder().decode(PromiseListResponse.self, from: responseData)
                completion(.success(decoded.content))
            } catch {
                completion(.failure(error))
            }
        }
        .resume()
    }

    func createPromise(
        accessToken: String,
        tokenType: String = "Bearer",
        title: String,
        description: String? = nil,
        promiseDateTime: String,
        completion: @escaping (Result<BackendPromise, Error>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/api/v1/promises") else {
            completion(.failure(AuthAPIError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("\(tokenType) \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let payload = CreatePromiseRequest(
                title: title,
                description: description,
                promiseDateTime: promiseDateTime
            )
            request.httpBody = try JSONEncoder().encode(payload)
            print("[PromiseAPI] create payload title:", payload.title)
            print("[PromiseAPI] create payload promiseDateTime:", payload.promiseDateTime)
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
                print("[PromiseAPI] create failed status:", httpResponse.statusCode)
                print("[PromiseAPI] create failed body:", message)
                completion(.failure(AuthAPIError.server(statusCode: httpResponse.statusCode, message: message)))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(BackendPromise.self, from: responseData)
                completion(.success(decoded))
            } catch {
                completion(.failure(error))
            }
        }
        .resume()
    }

    func getParticipants(
        promiseId: Int64,
        accessToken: String,
        tokenType: String = "Bearer",
        completion: @escaping (Result<[PromiseParticipantResponse], Error>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/api/v1/promises/\(promiseId)/participants") else {
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
                let decoded = try JSONDecoder().decode([PromiseParticipantResponse].self, from: responseData)
                completion(.success(decoded))
            } catch {
                completion(.failure(error))
            }
        }
        .resume()
    }

    func getPromiseSummary(
        promiseId: Int64,
        accessToken: String,
        tokenType: String = "Bearer",
        completion: @escaping (Result<PromiseSummaryResponse, Error>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/api/v1/promises/\(promiseId)/summary") else {
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
                let decoded = try JSONDecoder().decode(PromiseSummaryResponse.self, from: responseData)
                completion(.success(decoded))
            } catch {
                completion(.failure(error))
            }
        }
        .resume()
    }


    func getInviteCode(
        promiseId: Int64,
        accessToken: String,
        tokenType: String = "Bearer",
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/api/v1/promises/\(promiseId)/invite/code") else {
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
                let decoded = try JSONDecoder().decode(BackendPromise.self, from: responseData)
                if let inviteCode = decoded.inviteCode, !inviteCode.isEmpty {
                    completion(.success(inviteCode))
                } else {
                    completion(.failure(AuthAPIError.server(statusCode: httpResponse.statusCode, message: "초대 코드를 찾지 못했습니다.")))
                }
            } catch {
                completion(.failure(error))
            }
        }
        .resume()
    }

    func joinPromise(
        inviteCode: String,
        accessToken: String,
        tokenType: String = "Bearer",
        completion: @escaping (Result<BackendPromise, Error>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/api/v1/promises/join/\(inviteCode)") else {
            completion(.failure(AuthAPIError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
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
                let decoded = try JSONDecoder().decode(BackendPromise.self, from: responseData)
                completion(.success(decoded))
            } catch {
                completion(.failure(error))
            }
        }
        .resume()
    }

    func getMidpointRecommendations(
        promiseId: Int64,
        accessToken: String,
        tokenType: String = "Bearer",
        completion: @escaping (Result<MidpointRecommendationResponse, Error>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/api/v1/promises/\(promiseId)/midpoint/recommendations") else {
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
                let decoded = try JSONDecoder().decode(MidpointRecommendationResponse.self, from: responseData)
                completion(.success(decoded))
            } catch {
                completion(.failure(error))
            }
        }
        .resume()
    }

    func startMidpointSelection(
        promiseId: Int64,
        accessToken: String,
        tokenType: String = "Bearer",
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/api/v1/promises/\(promiseId)/start-midpoint-selection") else {
            completion(.failure(AuthAPIError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
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

            guard (200...299).contains(httpResponse.statusCode) else {
                let responseData = data ?? Data()
                let message = String(data: responseData, encoding: .utf8) ?? "알 수 없는 오류"
                completion(.failure(AuthAPIError.server(statusCode: httpResponse.statusCode, message: message)))
                return
            }

            completion(.success(()))
        }
        .resume()
    }

    func updateDeparture(
        promiseId: Int64,
        accessToken: String,
        tokenType: String = "Bearer",
        latitude: Double,
        longitude: Double,
        address: String?,
        completion: @escaping (Result<PromiseParticipantResponse, Error>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/api/v1/promises/\(promiseId)/departure") else {
            completion(.failure(AuthAPIError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("\(tokenType) \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(
                UpdateDepartureRequest(latitude: latitude, longitude: longitude, address: address)
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
                let decoded = try JSONDecoder().decode(PromiseParticipantResponse.self, from: responseData)
                completion(.success(decoded))
            } catch {
                completion(.failure(error))
            }
        }
        .resume()
    }
}
