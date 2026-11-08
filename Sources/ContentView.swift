import SwiftUI
import NetworkExtension

struct ContentView: View {
    @StateObject private var vpn = VPNController()
    @State private var servers: [Server] = []
    @State private var selectedID: UUID?
    @State private var showingAdd = false
    @State private var probeURL = ""
    @State private var probeResult = "Проверка не выполнялась"
    @State private var probing = false
    @State private var showError = false
    @State private var localError = ""

    private var selected: Server? { servers.first { $0.id == selectedID } }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Label("VPN", systemImage: "network")
                        Spacer()
                        Text(vpn.statusText).foregroundStyle(vpn.status == .connected ? .green : .secondary)
                    }
                    if let address = vpn.configuredAddress, !vpn.canConfigure {
                        LabeledContent("Адрес конфигурации", value: address)
                    }
                    if vpn.canConfigure {
                        Button("Подключить выбранный сервер") {
                            if let selected { vpn.connect(selected) }
                        }.disabled(selected == nil || vpn.busy)
                    } else {
                        Button("Отключить VPN", role: .destructive) { vpn.disconnect() }
                            .disabled(vpn.status == .disconnecting)
                    }
                } footer: {
                    Text("Это VPN устройства, а не только игры. При подключении другой активный VPN может отключиться. Регион выхода и игровой сервер автоматически не подтверждаются.")
                }
                Section {
                    if servers.isEmpty { Text("Добавьте свой IKEv2-сервер.").foregroundStyle(.secondary) }
                    ForEach(servers) { server in
                        Button {
                            selectedID = server.id
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(server.name).foregroundStyle(.primary)
                                    Text(server.address).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if selectedID == server.id { Image(systemName: "checkmark.circle.fill") }
                            }
                        }.disabled(!vpn.canConfigure || vpn.busy)
                    }
                    .onDelete(perform: deleteServers)
                    Button("Добавить сервер", systemImage: "plus") { showingAdd = true }
                        .disabled(!vpn.canConfigure || vpn.busy)
                } header: { Text("Ваши серверы") } footer: {
                    Text("Выбор записи ещё не означает подключение. Нужен сервер IKEv2 с EAP-логином и доверенным сертификатом.")
                }
                Section("Диагностика HTTPS") {
                    TextField("https://ваш-тестовый-адрес", text: $probeURL)
                        .keyboardType(.URL).textInputAutocapitalization(.never).autocorrectionDisabled()
                    Button(probing ? "Проверка…" : "Проверить доступность") { Task { await probe() } }
                        .disabled(probing)
                    Text(probeResult).font(.footnote).foregroundStyle(.secondary)
                    Text("Время HTTPS-запроса — не игровой ping и не доказательство игрового сервера. Адрес получит запрос с вашего текущего IP.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section("Mobile Legends") {
                    Text("После подключения откройте игру вручную. Достоверный адрес запуска игры не подтверждён.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("MLBB Pulse")
            .sheet(isPresented: $showingAdd) {
                AddServerView { server, password in
                    do {
                        try KeychainStore.savePassword(password, for: server.id)
                        servers.append(server)
                        selectedID = server.id
                        persist()
                        return true
                    } catch {
                        localError = error.localizedDescription
                        showError = true
                        return false
                    }
                }
            }
            .alert("Ошибка", isPresented: $showError) { Button("OK", role: .cancel) {} } message: { Text(localError) }
            .alert("Ошибка VPN", isPresented: Binding(get: { vpn.errorMessage != nil }, set: { if !$0 { vpn.errorMessage = nil } })) {
                Button("OK", role: .cancel) { vpn.errorMessage = nil }
            } message: { Text(vpn.errorMessage ?? "") }
            .onAppear {
                servers = (try? JSONDecoder().decode([Server].self, from: UserDefaults.standard.data(forKey: "servers.v1") ?? Data())) ?? []
                if selectedID == nil { selectedID = servers.first?.id }
                vpn.load()
            }
        }
    }

    private func persist() { if let data = try? JSONEncoder().encode(servers) { UserDefaults.standard.set(data, forKey: "servers.v1") } }

    private func deleteServers(at offsets: IndexSet) {
        guard vpn.canConfigure && !vpn.busy else { return }
        for index in offsets.sorted(by: >) {
            let server = servers[index]
            do {
                try KeychainStore.deletePassword(for: server.id)
                servers.remove(at: index)
            } catch { localError = error.localizedDescription; showError = true }
        }
        if !servers.contains(where: { $0.id == selectedID }) { selectedID = servers.first?.id }
        persist()
    }

    @MainActor private func probe() async {
        guard let url = URL(string: probeURL.trimmingCharacters(in: .whitespacesAndNewlines)),
              url.scheme?.lowercased() == "https", url.host != nil,
              url.user == nil, url.password == nil else {
            probeResult = "Введите корректный HTTPS-адрес без логина и пароля."
            return
        }
        probing = true
        defer { probing = false }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        request.httpMethod = "HEAD"
        let start = Date()
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { probeResult = "Получен не HTTP-ответ."; return }
            let ms = Int(Date().timeIntervalSince(start) * 1000)
            probeResult = "HTTPS: HTTP \(http.statusCode), \(ms) мс. Это время запроса, не ping игры."
        } catch { probeResult = "Проверка не удалась: \(error.localizedDescription)" }
    }
}

private struct AddServerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var address = ""
    @State private var remoteID = ""
    @State private var username = ""
    @State private var password = ""
    let save: (Server, String) -> Bool

    private var server: Server { Server(name: name, address: address, remoteID: remoteID, username: username) }
    var body: some View {
        NavigationStack {
            Form {
                Section("IKEv2 · EAP") {
                    TextField("Название, например город", text: $name)
                    TextField("Адрес сервера", text: $address).textInputAutocapitalization(.never).autocorrectionDisabled()
                    TextField("Remote ID (имя сертификата)", text: $remoteID).textInputAutocapitalization(.never).autocorrectionDisabled()
                    TextField("Логин", text: $username).textInputAutocapitalization(.never).autocorrectionDisabled()
                    SecureField("Пароль", text: $password)
                } footer: {
                    Text("Пароль хранится в Keychain на этом устройстве. Сервер и сертификат должны поддерживать IKEv2 с EAP. VPN запросит системное разрешение.")
                }
            }
            .navigationTitle("Новый сервер")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Добавить") { if save(server, password) { password = ""; dismiss() } }
                        .disabled(!server.isValid || password.isEmpty)
                }
            }
        }
    }
}
