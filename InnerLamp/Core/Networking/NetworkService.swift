//
//  NetworkService.swift
//  base_project
//
//  Created by ChjpCoj on 2/5/26.
//

import Foundation

protocol NetworkService {
    func request<T: Decodable>(endpoint: Endpoint, responseType: T.Type) async throws -> T
    
    func request(endpoint: Endpoint) async throws
}

actor NetworkServiceImpl: NetworkService {
    private let session: URLSession
    private let decoder: JSONDecoder
    /// `nonisolated(unsafe)` — both are immutable references whose concrete types
    /// (`KeychainAuthTokenProviding`, `NetworkLogger`) are `nonisolated` and hold no mutable
    /// state. The protocols themselves are not `Sendable`, so plain `nonisolated` leaves the
    /// properties actor-isolated; the initializer would then be mutating them from the main actor
    /// (the project's default actor isolation), which is an error in Swift 6.
    private nonisolated(unsafe) let authTokenProvider: AuthTokenProviding
    private nonisolated(unsafe) let logger: NetworkLogging

    init(
        session: URLSession = NetworkConfiguration.makeSession(),
        decoder: JSONDecoder = JSONDecoder(),
        authTokenProvider: AuthTokenProviding = KeychainAuthTokenProviding(keychainService: KeychainServiceImpl()),
        logger: NetworkLogging = NetworkLogger(loggingService: SentryLoggingService.shared)
    ) {
        self.session = session
        self.decoder = decoder
        self.authTokenProvider = authTokenProvider
        self.logger = logger
        
        // Configure decoder
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder.dateDecodingStrategy = .iso8601
    }
    
    func request<T: Decodable>(endpoint: Endpoint, responseType: T.Type) async throws -> T {
        var urlRequest = try endpoint.buildURLRequest()
        injectAuthHeader(into: &urlRequest, endpoint: endpoint)

        let method = urlRequest.httpMethod ?? endpoint.method.rawValue
        let path = endpoint.path
        let startedAt = Date()
        var observedStatusCode: Int?

        do {
            let (data, response) = try await session.data(for: urlRequest)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.unknown(NSError(domain: "Invalid response type", code: -1))
            }
            observedStatusCode = httpResponse.statusCode

            let value: T = try decodeSuccessOrThrow(
                statusCode: httpResponse.statusCode,
                data: data,
                envelope: endpoint.responseEnvelope
            )

            logger.log(
                method: method,
                path: path,
                statusCode: httpResponse.statusCode,
                duration: Date().timeIntervalSince(startedAt),
                failureClassification: nil
            )
            return value
        } catch let error as NetworkError {
            logFailure(method: method, path: path, statusCode: observedStatusCode, startedAt: startedAt, error: error)
            throw error
        } catch let urlError as URLError {
            let mapped = mapURLError(urlError)
            logFailure(method: method, path: path, statusCode: observedStatusCode, startedAt: startedAt, error: mapped)
            throw mapped
        } catch {
            let mapped = NetworkError.unknown(error)
            logFailure(method: method, path: path, statusCode: observedStatusCode, startedAt: startedAt, error: mapped)
            throw mapped
        }
    }
    
    func request(endpoint: any Endpoint) async throws {
        var urlRequest = try endpoint.buildURLRequest()
        injectAuthHeader(into: &urlRequest, endpoint: endpoint)

        let method = urlRequest.httpMethod ?? endpoint.method.rawValue
        let path = endpoint.path
        let startedAt = Date()
        var observedStatusCode: Int?

        do {
            let (data, response) = try await session.data(for: urlRequest)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.unknown(NSError(domain: "Invalid response type", code: -1))
            }
            observedStatusCode = httpResponse.statusCode

            try validateVoidResponse(statusCode: httpResponse.statusCode, data: data, envelope: endpoint.responseEnvelope)

            logger.log(
                method: method,
                path: path,
                statusCode: httpResponse.statusCode,
                duration: Date().timeIntervalSince(startedAt),
                failureClassification: nil
            )
        } catch let error as NetworkError {
            logFailure(method: method, path: path, statusCode: observedStatusCode, startedAt: startedAt, error: error)
            throw error
        } catch let urlError as URLError {
            let mapped = mapURLError(urlError)
            logFailure(method: method, path: path, statusCode: observedStatusCode, startedAt: startedAt, error: mapped)
            throw mapped
        } catch {
            let mapped = NetworkError.unknown(error)
            logFailure(method: method, path: path, statusCode: observedStatusCode, startedAt: startedAt, error: mapped)
            throw mapped
        }
    }
    
    // MARK: Private helpers — auth

    /// See Docs/Specs/Networking/design.md § "Request lifecycle" Step 2.
    private func injectAuthHeader(into request: inout URLRequest, endpoint: Endpoint) {
        // `requiresAuth == false` always wins — never even read the Keychain for this purpose.
        guard endpoint.requiresAuth else { return }

        // An endpoint's own declared `Authorization` header wins over the stored token.
        guard request.value(forHTTPHeaderField: "Authorization") == nil else { return }

        // No token stored → send with no `Authorization` header. Do not throw, do not block,
        // do not fabricate an empty token.
        guard let token = authTokenProvider.currentToken(), !token.isEmpty else { return }

        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }

    // MARK: Private helpers — decoding (Steps 4-5)

    private func decodeSuccessOrThrow<T: Decodable>(
        statusCode: Int,
        data: Data,
        envelope: ResponseEnvelope
    ) throws -> T {
        switch statusCode {
        case 200...299:
            switch envelope {
            case .bare:
                do {
                    return try decoder.decode(T.self, from: data)
                } catch {
                    throw NetworkError.decodingError(error)
                }
            case .standard:
                return try decodeEnvelopeSuccess(data: data, statusCode: statusCode)
            }
        case 401:
            throw NetworkError.unauthorized
        default:
            throw decodeFailureEnvelope(data: data, statusCode: statusCode)
        }
    }

    /// Same status/envelope handling as `decodeSuccessOrThrow`, but for the no-body overload:
    /// still enforces `success == false` → `.apiError` on the envelope, without needing a
    /// concrete `T` to return.
    private func validateVoidResponse(statusCode: Int, data: Data, envelope: ResponseEnvelope) throws {
        switch statusCode {
        case 200...299:
            guard envelope == .standard, !data.isEmpty else { return }
            let envelopeValue: APIEnvelope<AnyCodable>
            do {
                envelopeValue = try decoder.decode(APIEnvelope<AnyCodable>.self, from: data)
            } catch {
                // No body to speak of, or a body that isn't the envelope — nothing to validate.
                return
            }
            if !envelopeValue.success {
                throw apiError(from: envelopeValue.error, details: envelopeValue.details)
            }
        case 401:
            throw NetworkError.unauthorized
        default:
            throw decodeFailureEnvelope(data: data, statusCode: statusCode)
        }
    }

    private func decodeEnvelopeSuccess<T: Decodable>(data: Data, statusCode: Int) throws -> T {
        let envelope: APIEnvelope<T>
        do {
            envelope = try decoder.decode(APIEnvelope<T>.self, from: data)
        } catch {
            // Envelope decode failed — no second decode strategy is attempted.
            throw NetworkError.serverError(statusCode: statusCode, message: nil)
        }

        if envelope.success {
            guard let value = envelope.data else {
                throw NetworkError.noData
            }
            return value
        } else {
            throw apiError(from: envelope.error, details: envelope.details)
        }
    }

    /// Step 5 — attempt to decode a 4xx/5xx body as the envelope; fall back to `.serverError`
    /// with no message when it doesn't parse as one. 401 is handled before this is ever called.
    private func decodeFailureEnvelope(data: Data, statusCode: Int) -> NetworkError {
        guard let envelope = try? decoder.decode(APIEnvelope<AnyCodable>.self, from: data),
              let detail = envelope.error else {
            return .serverError(statusCode: statusCode, message: nil)
        }
        return apiError(from: detail, details: envelope.details)
    }

    private func apiError(from detail: APIErrorDetail?, details: [String: AnyCodable]?) -> NetworkError {
        guard let detail else {
            return .serverError(statusCode: 200, message: nil)
        }
        return .apiError(code: detail.code, message: detail.message, type: detail.type, details: details)
    }

    // MARK: Private helpers — logging

    private func logFailure(method: String, path: String, statusCode: Int?, startedAt: Date, error: NetworkError) {
        logger.log(
            method: method,
            path: path,
            statusCode: statusCode,
            duration: Date().timeIntervalSince(startedAt),
            failureClassification: classification(for: error)
        )
    }

    private func classification(for error: NetworkError) -> String {
        switch error {
        case .invalidURL: return "invalidURL"
        case .noData: return "noData"
        case .decodingError: return "decodingError"
        case .encodingError: return "encodingError"
        case .serverError(let statusCode, _): return "serverError(\(statusCode))"
        case .unauthorized: return "unauthorized"
        case .noInternetConnection: return "noInternetConnection"
        case .timeout: return "timeout"
        case .unknown: return "unknown"
        case .apiError(let code, _, _, _): return "apiError(\(code))"
        }
    }

    private func mapURLError(_ error: URLError) -> NetworkError {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .noInternetConnection
        case .timedOut:
            return .timeout
        default:
            return .unknown(error)
        }
    }
}
