import XCTest
@testable import MLBBPulse

final class ServerTests: XCTestCase {
    func testDemoCatalogIsExplicitlyNonProduction() {
        XCTAssertFalse(Server.demoCatalog.isEmpty)
        XCTAssertTrue(Server.demoCatalog.allSatisfy(\.isDemo))
        XCTAssertEqual(Set(Server.demoCatalog.map(\.id)).count, Server.demoCatalog.count)
    }
}
