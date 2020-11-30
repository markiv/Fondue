//
//  URLRequest+Extensions.swift
//  Fondue
//
//  Created by Vikram Kriplaney on 01.12.19.
//

import Foundation

/// URLRequest modifiers
public extension URLRequest {
    enum HttpMethod: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
        case head = "HEAD"
        case patch = "PATCH"
        case connect = "CONNECT"
        case options = "OPTIONS"
        case trace = "TRACE"
    }

    /// Returns a request with modified URL parameters
    func adding(parameters: URL.ConvertibleParameters) -> Self {
        modified(self) { $0.url = $0.url?.with(parameters: parameters) }
    }

    /// Returns a new request with modified headers. Any existing headers with the same name are overwritten.
    func adding(headers: [String: String]) -> Self {
        modified(self) {
            $0.allHTTPHeaderFields = ($0.allHTTPHeaderFields ?? [:]).merging(headers) { $1 }
        }
    }

    /// Returns a new request with a modified header. Any existing header with the same name is overwritten.
    func adding(header: String, value: String) -> Self {
        adding(headers: [header: value])
    }

    /// Returns a request with a modified HTTP method.
    func with(method: HttpMethod) -> Self {
        modified(self) { $0.httpMethod = method.rawValue }
    }

    func with(body: Data?, contentType: String? = nil) -> Self {
        modified(self) {
            $0.httpBody = body
            if let contentType = contentType {
                $0.addValue(contentType, forHTTPHeaderField: "Content-Type")
            }
        }
    }

    /// Returns a new request with a modified HTTP body.
    /// - Parameter body: A plain text body
    func with(body: String) -> Self {
        with(body: body.data(using: .utf8), contentType: "text/plain; charset=utf-8")
    }

    /// Returns a new request with a modified HTTP body and `Content-Type` header.
    /// - Parameter body: Any `Encodable` type, will be encoded as JSON
    /// - Parameter encoder: An optional `JSONEncoder`
    func with<T: Encodable>(body: T, encoder: JSONEncoder = .shared) -> Self {
        with(body: try? encoder.encode(body), contentType: "application/json; charset=utf-8")
    }

    /// Returns a new request with a modified HTTP body and `Content-Type` header.
    /// - Parameter body: A dictionary or parameters, will be encoded as a URL form body
    func with(body: URL.Parameters) -> Self {
        with(body: body.query?.data(using: .utf8), contentType: "application/x-www-form-urlencoded; charset=utf-8")
    }

    /*
     /// Returns a new request with a modified HTTP body.
     /// - Parameter body: Any `Encodable` type
     /// - Parameter encoder: A custom encoder
     func with<T: Encodable, E: TopLevelEncoder>(body: T, encoder: E) -> Self where E.Output == Data {
         modified(self) {
             $0.httpBody = try? encoder.encode(body)
         }
     }
     */

    /// Returns a new request with a modified `User-Agent` header.
    /// - Parameter userAgent: The new user-agent string
    func with(userAgent: String) -> Self {
        adding(header: "User-Agent", value: userAgent)
    }
}

public extension JSONDecoder {
    /// A convenient, shared `JSONDecoder`
    static var shared = modified(JSONDecoder()) {
        $0.keyDecodingStrategy = .convertFromSnakeCase
    }
}

public extension JSONEncoder {
    /// A convenient, shared `JSONEncoder`
    static var shared = JSONEncoder()
}

public extension URL {
    /// Creates  a request from this `URL`.
    /// - Parameter path: An optional path to append to the URL
    /// - Parameter method: An optional HTTP method, `.get` by default
    /// - Returns: a `URLRequest`
    func request(_ method: URLRequest.HttpMethod = .get, path: String? = nil) -> URLRequest {
        if let path = path, !path.isEmpty {
            return URLRequest(url: appendingPathComponent(path)).with(method: method)
        }
        return URLRequest(url: self).with(method: method)
    }
}

#if canImport(Combine)
    import Combine

    @available(iOS 13.0, tvOS 13.0, OSX 10.15, macCatalyst 13.0, watchOS 6.0, *)
    public extension URLRequest {
        /// Creates a publisher for this request and decodable type.
        ///
        /// Example:
        ///
        ///     func employee(name: String) -> AnyPublisher<Employee, Error> {
        ///         URL(string: "https://api.foo.com/employees")!
        ///             .request(path: name).publisher()
        ///     }
        /// - Parameter session: Optional session. `URLSession.shared` is used by default.
        /// - Parameter decoder: Optional decoder. `JSONDecoder.shared` is used by default.
        /// - Returns: A publisher that wraps a data task and decoding for the URL request
        ///
        func publisher<T: Decodable>(
            session: URLSession = .shared, decoder: JSONDecoder = .shared
        ) -> AnyPublisher<T, Error> {
            session.dataTaskPublisher(for: self)
                .map(\.data)
                .map { $0.dumpJson() }
                .decode(type: T.self, decoder: decoder)
                .handleEvents(receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        debugPrint(error)
                    }
                })
                .eraseToAnyPublisher()
        }

        /// Publishes just the HTTP status of this request
        func statusPublisher(
            session: URLSession = .shared, decoder: JSONDecoder = .shared
        ) -> AnyPublisher<Int?, Error> {
            session.dataTaskPublisher(for: self)
                .map { ($0.response as? HTTPURLResponse)?.statusCode }
                .mapError { $0 as Error }
                .eraseToAnyPublisher()
        }
    }

    extension Data {
        @discardableResult func dumpJson(title: String? = nil) -> Self {
            #if DEBUG
                print("----- \(title ?? "JSON Dump") -----")
                guard let object = try? JSONSerialization.jsonObject(with: self),
                      let data = try? JSONSerialization.data(withJSONObject: object, options: .prettyPrinted),
                      let json = String(data: data, encoding: .utf8)
                else {
                    print(String(data: self, encoding: .utf8) ?? "Unknown data encoding")
                    return self
                }
                print(json)
            #endif
            return self
        }
    }
#endif
