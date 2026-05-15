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


struct PromiseStatusResponse: Decodable {
    let promiseId: Int64?
    let status: String?

    init(promiseId: Int64?, status: String?) {
        self.promiseId = promiseId
        self.status = status
    }

    private enum CodingKeys: String, CodingKey {
        case promiseId
        case id
        case status
        case promiseStatus
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        promiseId = try container.decodeIfPresent(Int64.self, forKey: .promiseId)
            ?? container.decodeIfPresent(Int64.self, forKey: .id)
        status = try container.decodeIfPresent(String.self, forKey: .status)
            ?? container.decodeIfPresent(String.self, forKey: .promiseStatus)
    }
}


struct MapMarkerResponse: Codable {
    let latitude: Double?
    let longitude: Double?
    let name: String?
    let type: String?
}

struct ParticipantMarkerResponse: Codable {
    let userId: Int64?
    let nickname: String?
    let profileImageUrl: String?
    let latitude: Double?
    let longitude: Double?
    let host: Bool?
}

struct PromiseMapDataResponse: Codable {
    let promiseId: Int64?
    let destination: MapMarkerResponse?
    let participantDepartures: [ParticipantMarkerResponse]?
    let recommendedMidpoints: [MapMarkerResponse]?
    let currentLocations: [ParticipantMarkerResponse]?
}


struct RouteStepResponse: Codable {
    let type: String?
    let instruction: String?
    let duration: Int?
    let distance: Int?
    let lineName: String?
    let linestring: String?
}

struct RouteOptionResponse: Codable {
    let totalDuration: Int?
    let totalDistance: Int?
    let totalFare: Int?
    let transferCount: Int?
    let routes: [RouteStepResponse]?
}

struct DirectionsResponse: Codable {
    let routeOptions: [RouteOptionResponse]?
}

enum JSONValue: Decodable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON value")
        }
    }
}

struct ArrivalStatusResponse: Decodable {
    let raw: [String: JSONValue]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        raw = (try? container.decode([String: JSONValue].self)) ?? [:]
    }
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

struct ConfirmMidpointRequest: Codable {
    let stationId: Int64
}

struct ConfirmFinalPlaceRequest: Codable {
    let placeId: String?
    let placeName: String
    let latitude: Double
    let longitude: Double
}

struct PlaceRecommendationRequest: Codable {
    let query: String?
    let tab: String?
}

struct PlaceRecommendationItemResponse: Codable {
    let category: String?
    let address: String?
    let latitude: Double?
    let longitude: Double?
    let place_id: String?
    let place_name: String?
    let image_url: String?
    let ai_summary: String?
    let ai_score: Double?
    let distance_from_midpoint: Double?
}

struct PlaceRecommendationResponse: Codable {
    let recommendations: [PlaceRecommendationItemResponse]?
    let promise_id: Int64?
}

struct UpdateDepartureRequest: Codable {
    let latitude: Double
    let longitude: Double
    let address: String?
}


struct ExpenseRecordResponse: Codable {
    let userId: Int64?
    let nickname: String?
    let profileImageUrl: String?
    let paidAmount: Double?
    let balanceAmount: Double?
    let status: String?
}

struct SettlementTransferResponse: Codable {
    let fromUserId: Int64?
    let fromNickname: String?
    let toUserId: Int64?
    let toNickname: String?
    let amount: Double?
}

struct SettlementResponse: Codable {
    let promiseId: Int64?
    let promiseName: String?
    let totalAmount: Double?
    let perPersonAmount: Double?
    let participantCount: Int?
    let settlementCompletedAt: String?
    let expenses: [ExpenseRecordResponse]?
    let transfers: [SettlementTransferResponse]?
    let settlementCompleted: Bool?
}

struct UpdateMyExpenseRequest: Codable {
    let amount: Int
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
                print("[Settlement] updateMyExpense failed status:", httpResponse.statusCode)
                print("[Settlement] updateMyExpense failed body:", message)
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
                print("[Settlement] updateMyExpense failed status:", httpResponse.statusCode)
                print("[Settlement] updateMyExpense failed body:", message)
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
                print("[Settlement] updateMyExpense failed status:", httpResponse.statusCode)
                print("[Settlement] updateMyExpense failed body:", message)
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


    func getPromiseDetail(
        promiseId: Int64,
        accessToken: String,
        tokenType: String = "Bearer",
        completion: @escaping (Result<BackendPromise, Error>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/api/v1/promises/\(promiseId)") else {
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
                print("[Settlement] updateMyExpense failed status:", httpResponse.statusCode)
                print("[Settlement] updateMyExpense failed body:", message)
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

    func getPromiseStatus(
        promiseId: Int64,
        accessToken: String,
        tokenType: String = "Bearer",
        completion: @escaping (Result<PromiseStatusResponse, Error>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/api/v1/promises/\(promiseId)/status") else {
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
                print("[Settlement] updateMyExpense failed status:", httpResponse.statusCode)
                print("[Settlement] updateMyExpense failed body:", message)
                completion(.failure(AuthAPIError.server(statusCode: httpResponse.statusCode, message: message)))
                return
            }

            do {
                let rawStatus = try JSONDecoder().decode(String.self, from: responseData)
                completion(.success(PromiseStatusResponse(promiseId: promiseId, status: rawStatus)))
            } catch {
                do {
                    let decoded = try JSONDecoder().decode(PromiseStatusResponse.self, from: responseData)
                    completion(.success(decoded))
                } catch {
                    do {
                        let fallback = try JSONDecoder().decode(BackendPromise.self, from: responseData)
                        completion(.success(PromiseStatusResponse(promiseId: fallback.id ?? promiseId, status: fallback.status)))
                    } catch {
                        completion(.failure(error))
                    }
                }
            }
        }
        .resume()
    }


    func getInviteInfo(
        inviteCode: String,
        accessToken: String,
        tokenType: String = "Bearer",
        completion: @escaping (Result<BackendPromise, Error>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/api/v1/promises/invite/\(inviteCode)") else {
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
                print("[Settlement] updateMyExpense failed status:", httpResponse.statusCode)
                print("[Settlement] updateMyExpense failed body:", message)
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
                print("[Settlement] updateMyExpense failed status:", httpResponse.statusCode)
                print("[Settlement] updateMyExpense failed body:", message)
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
                print("[Settlement] updateMyExpense failed status:", httpResponse.statusCode)
                print("[Settlement] updateMyExpense failed body:", message)
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

    func getMapData(
        promiseId: Int64,
        accessToken: String,
        tokenType: String = "Bearer",
        completion: @escaping (Result<PromiseMapDataResponse, Error>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/api/v1/promises/\(promiseId)/map-data") else {
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
                print("[Settlement] updateMyExpense failed status:", httpResponse.statusCode)
                print("[Settlement] updateMyExpense failed body:", message)
                completion(.failure(AuthAPIError.server(statusCode: httpResponse.statusCode, message: message)))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(PromiseMapDataResponse.self, from: responseData)
                completion(.success(decoded))
            } catch {
                completion(.failure(error))
            }
        }
        .resume()
    }

    func getDirections(
        promiseId: Int64,
        accessToken: String,
        tokenType: String = "Bearer",
        originLat: Double,
        originLon: Double,
        destLat: Double,
        destLon: Double,
        completion: @escaping (Result<DirectionsResponse, Error>) -> Void
    ) {
        var components = URLComponents(string: "\(baseURL)/api/v1/promises/\(promiseId)/directions")
        components?.queryItems = [
            URLQueryItem(name: "originLat", value: String(originLat)),
            URLQueryItem(name: "originLon", value: String(originLon)),
            URLQueryItem(name: "destLat", value: String(destLat)),
            URLQueryItem(name: "destLon", value: String(destLon))
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
                print("[Settlement] updateMyExpense failed status:", httpResponse.statusCode)
                print("[Settlement] updateMyExpense failed body:", message)
                completion(.failure(AuthAPIError.server(statusCode: httpResponse.statusCode, message: message)))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(DirectionsResponse.self, from: responseData)
                completion(.success(decoded))
            } catch {
                completion(.failure(error))
            }
        }
        .resume()
    }

    func getArrivalStatus(
        promiseId: Int64,
        accessToken: String,
        tokenType: String = "Bearer",
        completion: @escaping (Result<ArrivalStatusResponse, Error>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/api/v1/promises/\(promiseId)/arrivals") else {
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
                print("[Settlement] updateMyExpense failed status:", httpResponse.statusCode)
                print("[Settlement] updateMyExpense failed body:", message)
                completion(.failure(AuthAPIError.server(statusCode: httpResponse.statusCode, message: message)))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(ArrivalStatusResponse.self, from: responseData)
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
                print("[Settlement] updateMyExpense failed status:", httpResponse.statusCode)
                print("[Settlement] updateMyExpense failed body:", message)
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

    func getPlaceRecommendations(
        promiseId: Int64,
        accessToken: String,
        tokenType: String = "Bearer",
        query: String? = nil,
        tab: String = "ALL",
        completion: @escaping (Result<PlaceRecommendationResponse, Error>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/api/v1/promises/\(promiseId)/place-recommendations") else {
            completion(.failure(AuthAPIError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("\(tokenType) \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(PlaceRecommendationRequest(query: query, tab: tab))
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
                print("[Settlement] updateMyExpense failed status:", httpResponse.statusCode)
                print("[Settlement] updateMyExpense failed body:", message)
                completion(.failure(AuthAPIError.server(statusCode: httpResponse.statusCode, message: message)))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(PlaceRecommendationResponse.self, from: responseData)
                completion(.success(decoded))
            } catch {
                completion(.failure(error))
            }
        }
        .resume()
    }

    func confirmMidpoint(
        promiseId: Int64,
        accessToken: String,
        tokenType: String = "Bearer",
        stationId: Int64,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/api/v1/promises/\(promiseId)/midpoint/confirm") else {
            completion(.failure(AuthAPIError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("\(tokenType) \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(ConfirmMidpointRequest(stationId: stationId))
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

    func confirmFinalPlace(
        promiseId: Int64,
        accessToken: String,
        tokenType: String = "Bearer",
        placeId: String? = nil,
        placeName: String,
        latitude: Double,
        longitude: Double,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/api/v1/promises/\(promiseId)/midpoint/place-confirm") else {
            completion(.failure(AuthAPIError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("\(tokenType) \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(
                ConfirmFinalPlaceRequest(
                    placeId: placeId,
                    placeName: placeName,
                    latitude: latitude,
                    longitude: longitude
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

    func resetMidpoint(
        promiseId: Int64,
        accessToken: String,
        tokenType: String = "Bearer",
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/api/v1/promises/\(promiseId)/midpoint/reset") else {
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

    func completePromise(
        promiseId: Int64,
        accessToken: String,
        tokenType: String = "Bearer",
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/api/v1/promises/\(promiseId)/complete") else {
            completion(.failure(AuthAPIError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
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

    func cancelPromise(
        promiseId: Int64,
        accessToken: String,
        tokenType: String = "Bearer",
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/api/v1/promises/\(promiseId)/cancel") else {
            completion(.failure(AuthAPIError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
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


    func getSettlement(
        promiseId: Int64,
        accessToken: String,
        tokenType: String = "Bearer",
        completion: @escaping (Result<SettlementResponse, Error>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/api/v1/promises/\(promiseId)/expenses") else {
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
                print("[Settlement] getSettlement failed status:", httpResponse.statusCode)
                print("[Settlement] getSettlement failed body:", message)
                completion(.failure(AuthAPIError.server(statusCode: httpResponse.statusCode, message: message)))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(SettlementResponse.self, from: responseData)
                completion(.success(decoded))
            } catch {
                completion(.failure(error))
            }
        }
        .resume()
    }

    func updateMyExpense(
        promiseId: Int64,
        accessToken: String,
        tokenType: String = "Bearer",
        amount: Int,
        completion: @escaping (Result<SettlementResponse, Error>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/api/v1/promises/\(promiseId)/expenses/my") else {
            completion(.failure(AuthAPIError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("\(tokenType) \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            print("[Settlement] updateMyExpense payload amount:", amount)
            request.httpBody = try JSONEncoder().encode(UpdateMyExpenseRequest(amount: amount))
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
                print("[Settlement] updateMyExpense failed status:", httpResponse.statusCode)
                print("[Settlement] updateMyExpense failed body:", message)
                completion(.failure(AuthAPIError.server(statusCode: httpResponse.statusCode, message: message)))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(SettlementResponse.self, from: responseData)
                completion(.success(decoded))
            } catch {
                completion(.failure(error))
            }
        }
        .resume()
    }

    func completeSettlement(
        promiseId: Int64,
        accessToken: String,
        tokenType: String = "Bearer",
        completion: @escaping (Result<SettlementResponse, Error>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/api/v1/promises/\(promiseId)/expenses/settle") else {
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
                print("[Settlement] completeSettlement failed status:", httpResponse.statusCode)
                print("[Settlement] completeSettlement failed body:", message)
                completion(.failure(AuthAPIError.server(statusCode: httpResponse.statusCode, message: message)))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(SettlementResponse.self, from: responseData)
                completion(.success(decoded))
            } catch {
                completion(.failure(error))
            }
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
                print("[Settlement] updateMyExpense failed status:", httpResponse.statusCode)
                print("[Settlement] updateMyExpense failed body:", message)
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



struct PromiseStatusSocketEvent: Decodable {
    struct Payload: Decodable {
        let previousStatus: String?
        let newStatus: String?
        let confirmedPlaceName: String?
    }

    let type: String
    let promiseId: Int64?
    let message: String?
    let payload: Payload?
    let timestamp: String?
}

struct PromiseLocationSocketEvent: Decodable {
    let promiseId: Int64?
    let userId: Int64?
    let nickname: String?
    let latitude: Double?
    let longitude: Double?
    let timestamp: String?
}

struct PromiseLocationPublishPayload: Encodable {
    let latitude: Double
    let longitude: Double
}

enum PromiseRealtimeSubscription: Hashable {
    case status
    case locations

    func destination(for promiseId: Int64) -> String {
        switch self {
        case .status:
            return "/topic/promises/\(promiseId)/status"
        case .locations:
            return "/topic/promises/\(promiseId)/locations"
        }
    }

    var subscribeID: String {
        switch self {
        case .status:
            return "promise-status"
        case .locations:
            return "promise-locations"
        }
    }
}

@MainActor
final class PromiseRealtimeManager: ObservableObject {
    enum ConnectionState: Equatable {
        case disconnected
        case connecting
        case connected
    }

    @Published var latestStatusEvent: PromiseStatusSocketEvent?
    @Published var latestLocationEvent: PromiseLocationSocketEvent?
    @Published var connectionState: ConnectionState = .disconnected

    private var task: URLSessionWebSocketTask?
    private let session = URLSession(configuration: .default)
    private var currentPromiseId: Int64?
    private var currentAuthorization: String?
    private var requestedSubscriptions: Set<PromiseRealtimeSubscription> = []
    private var subscribedTopics: Set<PromiseRealtimeSubscription> = []

    func connect(promiseId: Int64, accessToken: String, tokenType: String, subscriptions: Set<PromiseRealtimeSubscription>) {
        let authorization = "\(tokenType) \(accessToken)"
        if currentPromiseId == promiseId,
           currentAuthorization == authorization,
           requestedSubscriptions == subscriptions,
           task != nil {
            return
        }

        disconnect()
        currentPromiseId = promiseId
        currentAuthorization = authorization
        requestedSubscriptions = subscriptions

        guard let url = URL(string: "ws://3.37.196.242/ws/websocket") else {
            print("[PromiseRealtime] invalid websocket url")
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        request.setValue(authorization, forHTTPHeaderField: "Authorization")
        request.setValue("v12.stomp, v11.stomp, v10.stomp", forHTTPHeaderField: "Sec-WebSocket-Protocol")

        let webSocketTask = session.webSocketTask(with: request)
        task = webSocketTask
        connectionState = .connecting
        webSocketTask.resume()

        print("[PromiseRealtime] connecting to promiseId:", promiseId, "subscriptions:", subscriptions.map { $0.subscribeID }.joined(separator: ","))
        print("[PromiseRealtime] websocket url:", url.absoluteString)
        sendConnectFrame(authorization: authorization)
        receiveNextMessage()
    }

    func disconnect() {
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
        currentPromiseId = nil
        currentAuthorization = nil
        requestedSubscriptions = []
        subscribedTopics = []
        connectionState = .disconnected
    }

    func publishMyLocation(latitude: Double, longitude: Double) {
        guard let promiseId = currentPromiseId else { return }
        let payload = PromiseLocationPublishPayload(latitude: latitude, longitude: longitude)
        guard let data = try? JSONEncoder().encode(payload),
              let body = String(data: data, encoding: .utf8) else {
            print("[PromiseRealtime] failed to encode location payload")
            return
        }

        let frame = [
            "SEND",
            "destination:/app/promises/\(promiseId)/location",
            "content-type:application/json",
            "content-length:\(body.utf8.count)",
            "",
            body + "\0"
        ].joined(separator: "\n")

        task?.send(.string(frame)) { error in
            if let error {
                print("[PromiseRealtime] publish location error:", error.localizedDescription)
            } else {
                print("[PromiseRealtime] published my location for promiseId:", promiseId)
            }
        }
    }

    private func sendConnectFrame(authorization: String) {
        let frame = [
            "CONNECT",
            "accept-version:1.2",
            "heart-beat:10000,10000",
            "Authorization:\(authorization)",
            "",
            "\0"
        ].joined(separator: "\n")

        task?.send(.string(frame)) { error in
            if let error {
                print("[PromiseRealtime] connect frame error:", error.localizedDescription)
            } else {
                print("[PromiseRealtime] connect frame sent")
            }
        }
    }

    private func sendSubscribeFrames() {
        guard let promiseId = currentPromiseId else { return }

        for subscription in requestedSubscriptions where !subscribedTopics.contains(subscription) {
            let frame = [
                "SUBSCRIBE",
                "id:\(subscription.subscribeID)-\(promiseId)",
                "destination:\(subscription.destination(for: promiseId))",
                "",
                "\0"
            ].joined(separator: "\n")

            task?.send(.string(frame)) { [weak self] error in
                if let error {
                    print("[PromiseRealtime] subscribe frame error (\(subscription.subscribeID)):", error.localizedDescription)
                    return
                }
                Task { @MainActor in
                    self?.subscribedTopics.insert(subscription)
                }
                print("[PromiseRealtime] subscribed to \(subscription.destination(for: promiseId))")
            }
        }
    }

    private func receiveNextMessage() {
        task?.receive { [weak self] result in
            guard let self else { return }

            switch result {
            case let .success(message):
                Task { @MainActor in
                    self.handleMessage(message)
                    self.receiveNextMessage()
                }
            case let .failure(error):
                Task { @MainActor in
                    print("[PromiseRealtime] receive error:", error.localizedDescription)
                    self.connectionState = .disconnected
                    self.subscribedTopics = []
                }
            }
        }
    }

    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        let text: String
        switch message {
        case let .string(value):
            text = value
        case let .data(data):
            text = String(decoding: data, as: UTF8.self)
        @unknown default:
            return
        }

        for frame in text.split(separator: "\0") {
            processFrame(String(frame))
        }
    }

    private func processFrame(_ frame: String) {
        let normalized = frame.replacingOccurrences(of: "\r\n", with: "\n")

        if normalized.hasPrefix("CONNECTED") {
            connectionState = .connected
            print("[PromiseRealtime] connected")
            sendSubscribeFrames()
            return
        }

        guard let separatorRange = normalized.range(of: "\n\n") else { return }

        let headerPart = String(normalized[..<separatorRange.lowerBound])
        let bodyPart = String(normalized[separatorRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        let headerLines = headerPart.components(separatedBy: "\n")
        let command = headerLines.first ?? ""
        let headers = parseHeaders(Array(headerLines.dropFirst()))

        switch command {
        case "MESSAGE":
            handleMessageBody(bodyPart, headers: headers)
        case "ERROR":
            print("[PromiseRealtime] server error frame:", bodyPart)
        default:
            break
        }
    }

    private func handleMessageBody(_ body: String, headers: [String: String]) {
        guard !body.isEmpty, let data = body.data(using: .utf8) else { return }
        let destination = headers["destination"] ?? ""

        if destination.contains("/status") {
            do {
                latestStatusEvent = try JSONDecoder().decode(PromiseStatusSocketEvent.self, from: data)
            } catch {
                print("[PromiseRealtime] status decode error:", error.localizedDescription)
                print("[PromiseRealtime] status raw body:", body)
            }
            return
        }

        if destination.contains("/locations") {
            do {
                latestLocationEvent = try JSONDecoder().decode(PromiseLocationSocketEvent.self, from: data)
            } catch {
                print("[PromiseRealtime] locations decode error:", error.localizedDescription)
                print("[PromiseRealtime] locations raw body:", body)
            }
        }
    }

    private func parseHeaders(_ lines: [String]) -> [String: String] {
        var headers: [String: String] = [:]
        for line in lines {
            guard let separator = line.firstIndex(of: ":") else { continue }
            let key = String(line[..<separator])
            let value = String(line[line.index(after: separator)...])
            headers[key] = value
        }
        return headers
    }
}
