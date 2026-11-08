import Foundation
import NetworkExtension

@MainActor
final class VPNController: ObservableObject {
    @Published private(set) var status: NEVPNStatus = .invalid
    @Published private(set) var configuredAddress: String?
    @Published private(set) var busy = false
    @Published var errorMessage: String?
    private let manager = NEVPNManager.shared()
    private var observer: NSObjectProtocol?

    init() {
        observer = NotificationCenter.default.addObserver(forName: .NEVPNStatusDidChange, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        load()
    }

    deinit { if let observer { NotificationCenter.default.removeObserver(observer) } }

    func load() {
        manager.loadFromPreferences { [weak self] error in
            Task { @MainActor in
                guard let self else { return }
                if let error { self.errorMessage = error.localizedDescription }
                self.refresh()
            }
        }
    }

    private func refresh() {
        status = manager.connection.status
        configuredAddress = manager.protocolConfiguration?.serverAddress
    }

    var canConfigure: Bool { status == .invalid || status == .disconnected }

    func connect(_ server: Server) {
        guard !busy && canConfigure else { return }
        busy = true
        manager.loadFromPreferences { [weak self] error in
            Task { @MainActor in
                guard let self else { return }
                if let error { self.fail(error); return }
                // Never replace a configuration during an active transition.
                self.refresh()
                guard self.canConfigure else { self.busy = false; return }
                do {
                    let passwordRef = try KeychainStore.passwordReference(for: server.id)
                    let configuration = NEVPNProtocolIKEv2()
                    configuration.serverAddress = server.address
                    configuration.remoteIdentifier = server.remoteID
                    configuration.authenticationMethod = .none
                    configuration.useExtendedAuthentication = true
                    configuration.username = server.username
                    configuration.passwordReference = passwordRef
                    configuration.disconnectOnSleep = false
                    // This is device VPN, not per-app VPN. iOS still has system exceptions.
                    configuration.includeAllNetworks = true
                    configuration.excludeLocalNetworks = true
                    self.manager.protocolConfiguration = configuration
                    self.manager.localizedDescription = "MLBB Pulse"
                    self.manager.isEnabled = true
                    self.manager.isOnDemandEnabled = false
                    self.manager.saveToPreferences { [weak self] error in
                        Task { @MainActor in
                            guard let self else { return }
                            if let error { self.fail(error); return }
                            self.manager.loadFromPreferences { [weak self] error in
                                Task { @MainActor in
                                    guard let self else { return }
                                    if let error { self.fail(error); return }
                                    do { try self.manager.connection.startVPNTunnel() }
                                    catch { self.fail(error); return }
                                    self.busy = false
                                    self.refresh()
                                }
                            }
                        }
                    }
                } catch { self.fail(error) }
            }
        }
    }

    func disconnect() {
        manager.connection.stopVPNTunnel()
        refresh()
    }

    private func fail(_ error: Error) {
        busy = false
        errorMessage = error.localizedDescription
        refresh()
    }

    var statusText: String {
        switch status {
        case .invalid: return "Не настроен"
        case .disconnected: return "Отключён"
        case .connecting: return "Подключение…"
        case .connected: return "Подключён"
        case .reasserting: return "Переподключение…"
        case .disconnecting: return "Отключение…"
        @unknown default: return "Неизвестно"
        }
    }
}
