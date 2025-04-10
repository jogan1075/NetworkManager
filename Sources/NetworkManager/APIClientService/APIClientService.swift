//
//  APIClientService.swift
//  NetworkManager
//
//  Created by Jonathan Muñoz on 06-04-25.
//

import Foundation
import LoggerManager

public enum APIError: Error {
    case invalidEndpoint
    case badServerResponse
    case networkError(error: Error)
    case parsing(error: Error)
}

public typealias APIResponse = (data: Data, statusCode: Int)

public protocol IAPIClientService {
    func request(_ endpoint: EndPointType) async -> Result<APIResponse, APIError>
    func request<T: Decodable>(_ endpoint: EndPointType, for type: T.Type, decoder: JSONDecoder) async throws -> T
    func request<T, M: Mappable>(_ endpoint: EndPointType, mapper: M) async throws -> T where M.Output == T
}

public extension IAPIClientService {
    func request<T: Decodable>(_ endpoint: EndPointType, for type: T.Type) async throws -> T {
        try await request(endpoint, for: type, decoder: JSONDecoder())
    }
}

public final class APIClientService: IAPIClientService {
    public struct Configuration {
        let baseURL: URL?
        let baseHeaders: [String: String]

        public init(baseURL: URL?, baseHeaders: [String: String]) {
            self.baseURL = baseURL
            self.baseHeaders = baseHeaders
        }

        public static let `default` = Configuration(baseURL: nil, baseHeaders: [:])
    }

    private let logger: ILogger
    private let configuration: Configuration

    public init(logger: ILogger, configuration: Configuration = .default) {
        self.configuration = configuration
        self.logger = logger
    }

    private func request(_ endpoint: EndPointType, completion: @escaping (Result<APIResponse, APIError>) -> Void) {
        guard let request = buildURLRequest(from: endpoint) else {
            completion(.failure(.invalidEndpoint))
            return
        }

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            self?.logger.log(request: request, data: data, response: response as? HTTPURLResponse, error: error)

            if let error = error {
                completion(.failure(.networkError(error: error)))
                return
            }

            guard let data = data, let httpResponse = response as? HTTPURLResponse,
                  (200 ..< 400).contains(httpResponse.statusCode)
            else {
                completion(.failure(.badServerResponse))
                return
            }

            completion(.success((data, httpResponse.statusCode)))
        }

        task.resume()
    }

    public func request(_ endpoint: EndPointType) async -> Result<APIResponse, APIError> {
        await withCheckedContinuation { continuation in
            request(endpoint, completion: { result in
                continuation.resume(returning: result)
            })
        }
    }

    public func request<T>(
        _ endpoint: EndPointType,
        for _: T.Type,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> T where T: Decodable {
        let response = await request(endpoint)
        switch response {
        case let .success(result):
            do {
                let modelResponse = try decoder.decode(T.self, from: result.data)
                return modelResponse
            } catch {
                if let decodingError = error as? DecodingError {
                    logger.log(level: .error, message: "❌ Decoding error: \(decodingError.detailErrorDescription)")
                }

                throw APIError.parsing(error: error)
            }
        case let .failure(failure):
            throw failure
        }
    }

    public func request<T, M: Mappable>(_ endpoint: EndPointType, mapper: M) async throws -> T where T == M.Output {
        let responseModel: M.Input = try await request(endpoint, for: M.Input.self)
        return try mapper.map(responseModel)
    }

    private func buildURLRequest(from endpoint: EndPointType) -> URLRequest? {
        let host = endpoint.baseURL?.host ?? configuration.baseURL?.host
        guard let host = host else { return nil }

        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = endpoint.path

        if let urlQueries = endpoint.urlQueries {
            var queryItems: [URLQueryItem] = []
            for item in urlQueries {
                queryItems.append(URLQueryItem(name: item.key, value: item.value))
            }

            components.queryItems = queryItems
        }

        guard let url = components.url else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.httpMethod.rawValue

        let endpointHeaders = endpoint.headers ?? [:]
        let mergedHeaders = configuration.baseHeaders.merging(endpointHeaders) { (_, new) in new }
        request.allHTTPHeaderFields = mergedHeaders

        switch endpoint.bodyParameter {
        case let .data(data):
            request.httpBody = data
        case let .dictionary(dict, options):
            let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: options)
            request.httpBody = jsonData
        case let .encodable(object, encoder):
            let data = try? encoder.encode(object)
            request.httpBody = data
        default:
            break
        }

        return request
    }
}

