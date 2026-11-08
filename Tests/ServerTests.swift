import XCTest
@testable import MLBBPulse

final class ServerTests: XCTestCase {
    func testProfileTrimsAndRoundTripsWithoutPassword() throws {
        let server = Server(name: " Minsk ", address: " vpn.example.com ", remoteID: "vpn.example.com", username: " user ")
        XCTAssertTrue(server.isValid)
        XCTAssertEqual(server.name, "Minsk")
        XCTAssertEqual(server.username, "user")
        let data = try JSONEncoder().encode(server)
        XCTAssertEqual(try JSONDecoder().decode(Server.self, from: data), server)
        XCTAssertFalse(String(decoding: data, as: UTF8.self).contains("password"))
    }

    func testProfileRejectsIncompleteAndURLAddresses() {
        XCTAssertFalse(Server(name: "", address: "host", remoteID: "host", username: "user").isValid)
        XCTAssertFalse(Server(name: "City", address: "https://host", remoteID: "host", username: "user").isValid)
        XCTAssertFalse(Server(name: "City", address: "host/path", remoteID: "host", username: "user").isValid)
        XCTAssertFalse(Server(name: "City", address: "host", remoteID: "", username: "user").isValid)
    }
}
