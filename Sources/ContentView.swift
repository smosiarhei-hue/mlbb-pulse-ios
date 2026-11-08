import SwiftUI

struct ContentView: View {
    @State private var selectedServer = Server.demoCatalog[0]
    @State private var showingNotice = false

    private let background = Color(red: 0.035, green: 0.055, blue: 0.11)
    private let accent = Color(red: 0.30, green: 0.91, blue: 0.77)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    statusCard
                    serverSection
                    diagnosticsSection
                    disclaimer
                }
                .padding(20)
            }
            .background(background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .alert("Пока только прототип", isPresented: $showingNotice) {
                Button("Понятно", role: .cancel) { }
            } message: {
                Text("Нужны официальный API каталога и проверенная схема маршрутизации. Сейчас выбран только демо-элемент — VPN не подключён.")
            }
        }
        .tint(accent)
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                Image(systemName: "waveform.path")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(accent)
                Text("MLBB")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.72))
            }
            Text("Pulse")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("Выбор региона и честная диагностика")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.62))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 18)
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Состояние подключения", systemImage: "dot.radiowaves.left.and.right")
                .font(.headline)
                .foregroundStyle(.white)
            statusRow("Выбранный пункт", value: selectedServer.label, symbol: "checkmark.circle.fill", color: accent)
            statusRow("VPN-туннель", value: "Не подключён", symbol: "lock.slash", color: .orange)
            statusRow("Регион выхода", value: "Не проверен", symbol: "location.slash", color: .orange)
        }
        .padding(18)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.08)))
    }

    private var serverSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Серверы").font(.title3.bold()).foregroundStyle(.white)
                Spacer()
                Text("ДЕМО")
                    .font(.caption2.bold()).tracking(1).foregroundStyle(.black)
                    .padding(.horizontal, 9).padding(.vertical, 5)
                    .background(accent, in: Capsule())
            }
            Text("Это макет списка, а не реальные узлы Smetargus.")
                .font(.caption).foregroundStyle(.white.opacity(0.55))
            ForEach(Server.demoCatalog) { server in
                Button {
                    withAnimation(.snappy(duration: 0.22)) { selectedServer = server }
                } label: {
                    HStack(spacing: 13) {
                        Image(systemName: "globe.europe.africa.fill")
                            .foregroundStyle(accent).frame(width: 38, height: 38)
                            .background(accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(server.country + " · " + server.city)
                                .font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                            Text(server.label + " · не подключается")
                                .font(.caption).foregroundStyle(.white.opacity(0.55))
                        }
                        Spacer()
                        if selectedServer == server {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(accent)
                        }
                    }
                    .padding(13)
                    .background(.white.opacity(selectedServer == server ? 0.10 : 0.055), in: RoundedRectangle(cornerRadius: 17))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var diagnosticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Диагностика").font(.title3.bold()).foregroundStyle(.white)
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "info.circle.fill").foregroundStyle(accent)
                Text("Покажем отдельно выбранный сервер, состояние туннеля и подтверждённый регион выхода. Для реальной проверки нужен API/endpoint провайдера; сайт-статус не равен игровому ping.")
                    .font(.subheadline).foregroundStyle(.white.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 17))
            Button { showingNotice = true } label: {
                Label("Открыть Mobile Legends", systemImage: "arrow.up.right.square")
                    .font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(accent.opacity(0.17), in: RoundedRectangle(cornerRadius: 15))
                    .foregroundStyle(accent)
            }
        }
    }

    private var disclaimer: some View {
        Text("Независимый прототип. Не связан с Moonton или Smetargus. Запуск игры и VPN будут включены только после проверки официальных интерфейсов и правил платформы.")
            .font(.caption2).foregroundStyle(.white.opacity(0.42)).padding(.top, 4)
    }

    private func statusRow(_ title: String, value: String, symbol: String, color: Color) -> some View {
        HStack(spacing: 9) {
            Image(systemName: symbol).foregroundStyle(color)
            Text(title).foregroundStyle(.white.opacity(0.65))
            Spacer(minLength: 6)
            Text(value).foregroundStyle(.white).multilineTextAlignment(.trailing)
        }
        .font(.caption.weight(.medium))
    }
}
