import XCTest
@testable import Fondue

final class FondueTests: XCTestCase {
    static var allTests = [
        ("testUrlParameters", testUrlParameters)
    ]
}

extension FondueTests {
    func testUrlParameters() {
        var url: URL = "https://server.domain/path?query=vikram"
        // Read a parameter
        XCTAssertEqual(url.parameters["query"], "vikram")
        // Add a parameter
        url.parameters["page"] = "1"
        // Parameters are sorted alphabetically: page, query
        XCTAssertEqual(url.absoluteString, "https://server.domain/path?page=1&query=vikram")
        // Replace a parameter
        url.parameters["page"] = "2"
        XCTAssertEqual(url.absoluteString, "https://server.domain/path?page=2&query=vikram")
        // Remove a parameter
        url.parameters["page"] = nil
        XCTAssertEqual(url.absoluteString, "https://server.domain/path?query=vikram")
        // Change several parameters with mutating function
        url.merge(parameters: ["query": "kriplaney", "page": 3])
        XCTAssertEqual(url.absoluteString, "https://server.domain/path?page=3&query=kriplaney")

        // Read fragment
        XCTAssertNil(url.fragment)
        // Set fragment with nonmutating function
        url = url.with(fragment: "section1")
        XCTAssertEqual(url.absoluteString, "https://server.domain/path?page=3&query=kriplaney#section1")
        // Read fragment
        XCTAssertEqual(url.fragment, "section1")
        // Change fragment with mutating function
        url.set(fragment: "section2")
        XCTAssertEqual(url.fragment, "section2")
        // Remove fragment
        url = url.with(fragment: nil)
        XCTAssertNil(url.fragment)

        XCTAssertEqual(url.query, "page=3&query=kriplaney")
        XCTAssertEqual(url.parameters.query, "page=3&query=kriplaney")

        url = url.with(parameters: ["a": 12, "query": nil])
        XCTAssertEqual(url.query, "a=12&page=3")

        // Remove all parameters
        url.parameters = [:]
        XCTAssertEqual(url.query, "")
    }
}

extension FondueTests {
    func testConvertibleParameters() {
        let parameters: URL.ConvertibleParameters = ["a": 1, "b": "pepe", "c": nil, "d": false]
        XCTAssertEqual(parameters.converted, ["a": "1", "b": "pepe", "d": "false"])
    }
}
