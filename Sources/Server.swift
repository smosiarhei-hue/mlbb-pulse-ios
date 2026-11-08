import Foundation

struct Server: Identifiable, Equatable {
    let id: String
    let country: String
    let city: String
    let label: String
    let isDemo: Bool

    static let demoCatalog: [Server] = [
        Server(id: "demo-asia-1", country: "Азия", city: "Демо-город", label: "Демо-сервер 01", isDemo: true),
        Server(id: "demo-eu-1", country: "Европа", city: "Демо-город", label: "Демо-сервер 02", isDemo: true)
    ]
}
