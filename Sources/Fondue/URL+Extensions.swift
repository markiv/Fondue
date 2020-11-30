//
//  URL+Extensions.swift
//  Fondue
//
//  Created by Vikram Kriplaney on 30.11.19.
//

import Foundation

/// Lets URLs be expressed conveniently with literal strings:
/// # Example:
///     let baseUrl: URL = "https://someserver/something"
extension URL: ExpressibleByStringLiteral {
    public init(stringLiteral string: StaticString) {
        guard let url = URL(string: "\(string)") else {
            preconditionFailure("Invalid literal URL string: \(string)")
        }
        self = url
    }
}

/// Adds dictionary semantics for URL parameters
/// Strictly speaking, URLs can have multiple parameters with the same name (e.g. "a=1&a=2"),
/// and some server-side frameworks gather these into arrays.
/// But in many real-life projects, we think of each parameter as uniquely-named.
/// If this is your case, it might be a lot more convenient to treat parameters as dictionaries.

/// # Example:
///
///     var url = baseUrl
///     url.parameters["query"] = "fondue"
public extension URL {
    /// A dictionary of values that can be encoded in a URL query string
    typealias Parameters = [String: String]
    typealias ConvertibleParameters = [String: CustomStringConvertible?]

    /// A computed dictionary that represents the query parameters in the URL
    var parameters: Parameters {
        get {
            Parameters(queryItems: URLComponents(url: self, resolvingAgainstBaseURL: true)?.queryItems ?? [])
        }
        set {
            var components = URLComponents(url: self, resolvingAgainstBaseURL: true)!
            components.queryItems = newValue.queryItems
            self = components.url ?? self
        }
    }

    /// Returns a new URL after merging new parameters into it. If there are parameters with duplicate
    /// names, only the last one is retained.
    func with(parameters: ConvertibleParameters) -> Self {
        let parameters = parameters.map { ($0.key, $0.value.map { String(describing: $0) }) }
        return modified(self) { this in
            parameters.forEach { key, value in
                this.parameters[key] = value
            }
        }
    }

    mutating func merge(parameters: ConvertibleParameters) {
        self = with(parameters: parameters)
    }

    func with(fragment: String?) -> Self {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: true)
        components?.fragment = fragment
        return components?.url ?? self
    }

    mutating func set(fragment: String?) {
        self = with(fragment: fragment)
    }
}

public extension URL.Parameters {
    /// Initializes from an array of `URLQueryItem`s, as used in `URLComponents`.
    /// Note that nil values will be discarded, and if there are duplicate keys, only the last value will be retained.
    init(queryItems: [URLQueryItem]) {
        let sequence = queryItems.filter { $0.value != nil }.map { ($0.name, $0.value!) }
        self = Dictionary(sequence) { $1 } // in case of duplicate keys, only the last occurrence is stored
    }

    /// Returns an array of URLQueryItems, as used in URLComponents
    /// We also sort parameters in alphabetical order so that URLs are easier to compare.
    var queryItems: [URLQueryItem] {
        map { URLQueryItem(name: $0.key, value: $0.value) }.sorted { $1.name > $0.name }
    }

    /// Returns a query string representing these parameters, such as `a=1&b=2&c=Vikram%20Kriplaney`
    var query: String? {
        var components = URLComponents(string: "://")
        components?.queryItems = queryItems
        return components?.url?.query
    }
}

extension URL.ConvertibleParameters {
    /// Removes nil elements and converts non-nil elements to their string representation
    var converted: [String: String] {
        var result = URL.Parameters()
        forEach { key, value in
            result[key] = value.map { String(describing: $0) }
        }
        return result
    }
}
