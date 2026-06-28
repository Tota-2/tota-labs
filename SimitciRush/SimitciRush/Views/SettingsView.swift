import SwiftUI

struct SettingsView: View {
    @ObservedObject var game: GameSession
    @ObservedObject private var gameCenter = GameCenterService.shared
    @ObservedObject private var notifications = NotificationService.shared
    @AppStorage("simitci-rush-sound-enabled") private var soundEnabled = true
    @AppStorage("simitci-rush-haptics-enabled") private var hapticsEnabled = true
    @AppStorage("simitci-rush-notes-enabled") private var notesEnabled = true
    @AppStorage("simitci-rush-notifications-enabled") private var notificationsEnabled = true

    var body: some View {
        VStack(spacing: 0) {
            MenuHeader(title: "Ayarlar", subtitle: "Oyun hissi ve bildirim tercihleri") {
                game.openMainMenu()
            }

            ScrollView {
                VStack(spacing: 16) {
                    StandPanel {
                        VStack(spacing: 12) {
                            SectionHeader(title: "Tercihler", systemImage: "slider.horizontal.3")
                            SettingsToggleRow(title: "Ses", detail: "Buton ve servis efektleri", systemImage: "speaker.wave.2.fill", isOn: $soundEnabled)
                            SettingsToggleRow(title: "Titreşim", detail: "Combo, hata ve servis geri bildirimi", systemImage: "iphone.radiowaves.left.and.right", isOn: $hapticsEnabled)
                            SettingsToggleRow(title: "Oyun İpuçları", detail: "İlk gün yönlendirmeleri ve kısa bilgi notları", systemImage: "questionmark.circle.fill", isOn: $notesEnabled)
                            SettingsToggleRow(title: "Bildirimler", detail: notificationDetail, systemImage: "bell.badge.fill", isOn: $notificationsEnabled)
                        }
                    }

                    GameCard {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Kayıt", systemImage: game.cloudSaveStatus.systemImage)
                            Text(game.cloudSaveStatus.title)
                                .font(.headline.weight(.black))
                                .foregroundStyle(Color.simitCream)
                            Text(game.cloudSaveStatus.detail)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white.opacity(0.58))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("Yeni oyun başlatmak için ana menüdeki Yeni Oyun seçeneğini kullan.")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white.opacity(0.42))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    GameCenterSettingsPanel(game: game, status: gameCenter.status)

                    GameplayTelemetryPanel(telemetry: game.telemetry)

                    #if DEBUG
                    DebugEconomyPanel()
                    #endif
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 24)
                .frame(maxWidth: 820)
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            notifications.refreshAuthorizationStatus()
            game.refreshNotificationReminders()
            if notificationsEnabled {
                handleNotificationPreference(true)
            }
        }
        .onChange(of: notificationsEnabled) { _, isEnabled in
            handleNotificationPreference(isEnabled)
        }
    }

    private var notificationDetail: String {
        guard notificationsEnabled else { return "Servis ve ödül hatırlatmaları kapalı" }

        switch notifications.authorizationStatus {
        case .authorized, .provisional:
            return "Servis, ek servis ve ödül hatırlatmaları"
        case .denied:
            return "iOS izni kapalı; Ayarlar'dan açman gerekir"
        case .notDetermined:
            return "Açınca iOS bildirim izni istenir"
        case .ephemeral:
            return "Geçici bildirim izniyle çalışıyor"
        @unknown default:
            return "Bildirim durumu kontrol ediliyor"
        }
    }

    private func handleNotificationPreference(_ isEnabled: Bool) {
        if isEnabled {
            Task {
                let granted = await notifications.requestAuthorizationIfNeeded()
                if !granted {
                    notificationsEnabled = false
                }
                game.refreshNotificationReminders()
            }
        } else {
            notifications.cancelAllGameReminders()
            game.refreshNotificationReminders()
        }
    }
}

private struct GameCenterSettingsPanel: View {
    @ObservedObject var game: GameSession
    let status: GameCenterStatus

    var body: some View {
        StandPanel {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Game Center", systemImage: status.systemImage)

                HStack(spacing: 12) {
                    Image(systemName: status.systemImage)
                        .font(.title3.weight(.black))
                        .foregroundStyle(tint)
                        .frame(width: 44, height: 44)
                        .background(tint.opacity(0.15), in: Circle())

                    VStack(alignment: .leading, spacing: 3) {
                        Text(status.title)
                            .font(.headline.weight(.black))
                            .foregroundStyle(Color.simitCream)
                            .lineLimit(1)
                            .minimumScaleFactor(0.76)
                        Text(status.detail)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white.opacity(0.56))
                            .lineLimit(2)
                    }

                    Spacer(minLength: 0)
                }

                HStack(spacing: 10) {
                    SettingsActionButton(title: "Bağlan", systemImage: "person.crop.circle.badge.checkmark") {
                        game.authenticateGameCenter()
                    }

                    SettingsActionButton(title: "Sıralama", systemImage: "trophy.fill", isPrimary: status.isAuthenticated) {
                        game.openGameCenterLeaderboards()
                    }
                }

                Text("Gün sonlarında itibar skoru, kasa, günlük skor ve işletme günü Game Center'a gönderilir.")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.46))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var tint: Color {
        switch status {
        case .authenticated: .simitSuccess
        case .authenticating: .simitAmber
        case .failed: .simitDanger
        case .unavailable: .simitCream
        }
    }
}

private struct SettingsActionButton: View {
    let title: String
    let systemImage: String
    var isPrimary = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.black))
                .lineLimit(1)
                .minimumScaleFactor(0.76)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    isPrimary ? Color.simitAmber : Color.white.opacity(0.09),
                    in: RoundedRectangle(cornerRadius: 13, style: .continuous)
                )
                .foregroundStyle(isPrimary ? .black.opacity(0.82) : Color.simitCream)
        }
        .buttonStyle(.plain)
    }
}

private struct GameplayTelemetryPanel: View {
    let telemetry: GameTelemetry

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        StandPanel {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Oyun Verileri", systemImage: "chart.bar.xaxis")

                Text(telemetry.totalRushes == 0 ? "İlk servis tamamlandığında gerçek oynanış verileri burada görünür." : insight)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.58))
                    .fixedSize(horizontal: false, vertical: true)

                LazyVGrid(columns: columns, spacing: 8) {
                    TelemetryMetric(title: "Servis", value: "\(telemetry.totalRushes)", detail: "\(telemetry.mainRushes) ana · \(telemetry.extraRushes) ek")
                    TelemetryMetric(title: "Başarı", value: "%\(telemetry.serviceSuccessRate)", detail: "\(telemetry.served) doğru servis")
                    TelemetryMetric(title: "Sipariş Süresi", value: averageOrderText, detail: "Doğru servis ortalaması")
                    TelemetryMetric(title: "Toplam Net", value: "\(telemetry.totalNetProfit) TL", detail: "\(telemetry.totalRevenue) TL ciro")
                    TelemetryMetric(title: "Ek Servis Neti", value: "\(telemetry.extraNetProfit) TL", detail: "\(telemetry.extraRevenue) TL ciro")
                    TelemetryMetric(title: "Hatalar", value: "\(telemetry.missed + telemetry.wrong)", detail: "\(telemetry.missed) kaçan · \(telemetry.wrong) yanlış")
                    TelemetryMetric(title: "Depo ve Kayıp", value: "\(telemetry.storageCosts + telemetry.spoilageCosts) TL", detail: "\(telemetry.spoilageCosts) TL bozulma")
                    TelemetryMetric(title: "Kararlar", value: "\(telemetry.priceAdjustments)", detail: "Fiyat net değişimi \(signedPriceDelta)")
                    TelemetryMetric(title: "Kredi", value: "\(telemetry.loansTaken)", detail: "Alınan kredi sayısı")
                }
            }
        }
    }

    private var averageOrderText: String {
        telemetry.served > 0 ? telemetry.averageOrderSeconds.formatted(.number.precision(.fractionLength(1))) + " sn" : "-"
    }

    private var signedPriceDelta: String {
        telemetry.totalPriceDelta > 0 ? "+\(telemetry.totalPriceDelta) TL" : "\(telemetry.totalPriceDelta) TL"
    }

    private var insight: String {
        if telemetry.extraRushes > 0, telemetry.extraNetProfit < 0 {
            return "Ek servis toplamda zarar yazıyor. Stok ve servis hızını kontrol et."
        }
        if telemetry.serviceSuccessRate < 65 {
            return "Başarı oranı düşük. Daha kısa siparişlerle combo kurmak daha güvenli olabilir."
        }
        if telemetry.spoilageCosts > telemetry.storageCosts {
            return "Bozulan stok maliyeti yüksek. Depoyu ihtiyacın kadar doldur."
        }
        return "İşletme dengeli ilerliyor. Fiyat ve ek servis kararlarının uzun dönem etkisini buradan takip edebilirsin."
    }
}

private struct TelemetryMetric: View {
    let title: String
    let value: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.black))
                .foregroundStyle(.white.opacity(0.42))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text(value)
                .font(.headline.weight(.black))
                .foregroundStyle(Color.simitCream)
                .lineLimit(1)
                .minimumScaleFactor(0.68)
            Text(detail)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.48))
                .lineLimit(2)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, minHeight: 70, alignment: .topLeading)
        .padding(10)
        .background(Color.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#if DEBUG
private struct DebugEconomyPanel: View {
    private let summary = EconomySimulation.run(days: 30)

    var body: some View {
        GameCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Ekonomi Raporu", systemImage: "chart.line.uptrend.xyaxis")

                Text("30 günlük otomatik denge kontrolü. Zorlanan, ortalama ve iyi oyuncuda kasa, borç, itibar ve iflas riski görünür.")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.52))
                    .fixedSize(horizontal: false, vertical: true)

                Text(summaryText)
                    .font(.caption.weight(.black))
                    .foregroundStyle(summary.runs.contains(where: { $0.bankruptcyDay != nil }) ? Color.simitAmber : Color.simitSuccess)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.black.opacity(0.18), in: Capsule())

                ForEach(summary.runs, id: \.profile) { run in
                    DebugEconomyRunRow(run: run)
                }
            }
        }
    }

    private var summaryText: String {
        let bankruptcies = summary.runs.filter { $0.bankruptcyDay != nil }.count
        if bankruptcies > 0 {
            return "\(bankruptcies) profil iflas riski gösteriyor"
        }
        let lowCash = summary.runs.filter { $0.cash < 750 }.count
        if lowCash > 0 {
            return "\(lowCash) profil düşük kasayla ayakta kalıyor"
        }
        return "30 gün sonunda kritik açık görünmüyor"
    }
}

private struct DebugEconomyRunRow: View {
    let run: EconomyRunResult

    private var tint: Color {
        if run.bankruptcyDay != nil { return .simitDanger }
        if run.cash < 500 { return .simitAmber }
        return .simitSuccess
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(run.profile.title)
                    .font(.headline.weight(.black))
                    .foregroundStyle(Color.simitCream)
                Spacer()
                Text(run.bankruptcyDay.map { "İflas G\($0)" } ?? "\(run.cash) TL")
                    .font(.headline.weight(.black))
                    .foregroundStyle(tint)
            }

            HStack(spacing: 8) {
                DebugEconomyMetric(title: "Gün", value: "\(run.finalDay)")
                DebugEconomyMetric(title: "Lv", value: "\(run.level)")
                DebugEconomyMetric(title: "XP", value: "\(run.xp)")
                DebugEconomyMetric(title: "İtibar", value: "\(run.reputation)")
            }

            HStack(spacing: 8) {
                DebugEconomyMetric(title: "Borç", value: "\(run.debt) TL")
                DebugEconomyMetric(title: "Son Net", value: "\(run.days.last?.netProfit ?? 0) TL")
            }

            Text(riskNote)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.50))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(Color.black.opacity(0.15), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var riskNote: String {
        if let day = run.bankruptcyDay {
            return "Risk: Gün \(day)'de kasa iflas limitine düşüyor."
        }
        if run.debt > 0 {
            return "Risk: Ay sonunda hâlâ borç taşıyor."
        }
        if run.reputation < 15 {
            return "Risk: İtibar düşük; müşteri sabrı zorlanır."
        }
        if run.cash < 750 {
            return "Not: Ayakta kalıyor ama kasa tamponu düşük."
        }
        return "Denge: Kritik açık yok, işletme sürdürülebilir."
    }
}

private struct DebugEconomyMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title.uppercased())
                .font(.caption2.weight(.black))
                .foregroundStyle(.white.opacity(0.42))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text(value)
                .font(.caption.weight(.black))
                .foregroundStyle(.white.opacity(0.82))
                .lineLimit(1)
                .minimumScaleFactor(0.68)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
#endif

struct MenuHeader: View {
    let title: String
    let subtitle: String
    let back: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            GameBackButton(action: back)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(Color.simitCream)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                Text(subtitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.68))
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 26)
        .padding(.bottom, 10)
    }
}

private struct SettingsToggleRow: View {
    let title: String
    let detail: String
    let systemImage: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.headline.weight(.black))
                .foregroundStyle(isOn ? Color.simitAmber : .white.opacity(0.34))
                .frame(width: 38, height: 38)
                .background((isOn ? Color.simitAmber : Color.white).opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(.white)
                Text(detail)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.52))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color.simitAmber)
        }
        .padding(10)
        .background(Color.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
