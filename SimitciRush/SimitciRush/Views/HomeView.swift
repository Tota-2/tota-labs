import SwiftUI

struct HomeView: View {
    @ObservedObject var game: GameSession
    @AppStorage("simitci-first-day-home-tip-dismissed") private var isFirstDayHomeTipDismissed = false
    @AppStorage("simitci-rush-notes-enabled") private var notesEnabled = true

    var body: some View {
        GeometryReader { proxy in
            let isPad = proxy.size.width > 700

            ZStack {
                ScrollView {
                    VStack(spacing: isPad ? 26 : 16) {
                        HomeHeaderView(game: game)
                            .padding(.top, isPad ? 58 : 18)

                        HStack(spacing: isPad ? 14 : 10) {
                            MetricTile(title: "Kasa", value: "\(game.cash) TL", systemImage: "banknote.fill")
                            MetricTile(title: "Gün", value: "\(game.currentDay)", systemImage: "sun.max.fill", tint: .simitCream)
                            MetricTile(title: "İtibar", value: "\(game.reputation)", systemImage: "heart.fill", tint: .simitDanger)
                        }
                        .frame(maxWidth: isPad ? 920 : .infinity)
                        .padding(.top, isPad ? 18 : 20)

                        ShopStatusCard(game: game)
                            .frame(maxWidth: isPad ? 980 : .infinity)
                            .padding(.top, isPad ? max(360, proxy.size.height * 0.35) : 176)

                        HStack(spacing: isPad ? 14 : 10) {
                            HomePrepButton(
                                title: actionTitle,
                                systemImage: actionIcon,
                                style: game.hasPlayedRushToday ? .settlement : .primary
                            ) {
                                if game.canStartRush(.extra) {
                                    game.screen = .report
                                } else if game.hasPlayedRushToday {
                                    game.openDayClose()
                                } else {
                                    game.openPrep()
                                }
                            }

                            MiniRushCard(game: game)
                        }
                        .frame(maxWidth: isPad ? 980 : .infinity)
                        .padding(.top, isPad ? 16 : 12)

                        Spacer(minLength: 18)
                    }
                    .frame(maxWidth: isPad ? 1120 : .infinity)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, isPad ? 64 : 20)
                    .padding(.top, isPad ? 10 : 20)
                    .padding(.bottom, isPad ? 110 : 20)
                }

                if showsFirstDayTip {
                    FirstDayHomeCoach(isPad: isPad) {
                        isFirstDayHomeTipDismissed = true
                        game.openMarket()
                    } dismiss: {
                        isFirstDayHomeTipDismissed = true
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                }
            }
        }
    }

	private var actionTitle: String {
	    if game.canStartRush(.extra) { return "Kapanış Kararı" }
	    if game.hasPlayedRushToday, game.canPrepareNextDay { return "Yeni Gün Hazır" }
	    return game.hasPlayedRushToday ? "Kapanışı Gör" : "Tezgâh Aç"
	}

	private var actionIcon: String {
	    if game.canStartRush(.extra) { return "timer" }
	    return game.hasPlayedRushToday ? "receipt.fill" : "cart.fill.badge.plus"
	}

    private var showsFirstDayTip: Bool {
        notesEnabled && game.currentDay == 1 && !game.hasPlayedRushToday && !isFirstDayHomeTipDismissed
    }
}

private struct FirstDayHomeCoach: View {
    let isPad: Bool
    let openMarket: () -> Void
    let dismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.48)
                .ignoresSafeArea()

            VStack {
                Spacer()

                CoachPanel {
                    VStack(alignment: .leading, spacing: isPad ? 16 : 12) {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "cart.fill.badge.plus")
                                .font((isPad ? Font.title2 : Font.title3).weight(.black))
                                .foregroundStyle(.black.opacity(0.82))
                                .frame(width: isPad ? 52 : 46, height: isPad ? 52 : 46)
                                .background(Color.simitAmber, in: Circle())
                                .layoutPriority(1)

                            VStack(alignment: .leading, spacing: 5) {
                                Text("İlk iş: tedarik")
                                    .font((isPad ? Font.title2 : Font.headline).weight(.black))
                                    .foregroundStyle(Color.simitAmber)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.78)
                                Text("Tezgâh boş. Önce marketten simit, çay ve poşet al; sonra hazırlığa geç.")
                                    .font((isPad ? Font.subheadline : Font.caption).weight(.bold))
                                    .foregroundStyle(Color.simitCream.opacity(0.86))
                                    .lineLimit(3)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .layoutPriority(2)
                        }

                        HStack(spacing: 10) {
                            Button("Sonra") {
                                dismiss()
                            }
                            .font(.subheadline.weight(.black))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(Color.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .foregroundStyle(Color.simitCream.opacity(0.72))

                            Button {
                                openMarket()
                            } label: {
                                Label("Markete Git", systemImage: "arrow.right")
                                    .font(.subheadline.weight(.black))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 13)
                                    .background(Color.simitAmber, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .foregroundStyle(.black.opacity(0.82))
                            }
                        }
                    }
                }
                .frame(maxWidth: isPad ? 560 : .infinity)
                .padding(.horizontal, isPad ? 40 : 32)
                .padding(.bottom, isPad ? 188 : 154)
            }
        }
    }
}

private struct HomeHeaderView: View {
    @ObservedObject var game: GameSession

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        HStack(alignment: .top, spacing: isPad ? 16 : 10) {
            VStack(alignment: .leading, spacing: isPad ? 7 : 6) {
                Text("Simitçi")
                    .font(.system(size: isPad ? 50 : 38, weight: .black, design: .rounded))
                    .foregroundStyle(Color.simitCream)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text(dailyTagline)
                    .font((isPad ? Font.headline : Font.subheadline).weight(.bold))
                    .foregroundStyle(.white.opacity(0.76))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)

            HomeXPBadge(game: game)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var dailyTagline: String {
        let taglines = [
            "Sıcak simit hazır, vapur kuyruğu beklemez.",
            "Tezgâh açıldı mı sahil uyanır.",
            "Bugünün hesabı sıcak simitten çıkar.",
            "Kuyruk bekler, iyi esnaf bekletmez.",
            "Çay taze, simit çıtır, defter açık.",
            "Az stokla değil, doğru hesapla kazan.",
            "Sahil hareketli, kasa disiplin ister."
        ]
        return taglines[(max(1, game.currentDay) - 1) % taglines.count]
    }
}

private struct HomeMenuFloatingButton: View {
    let action: () -> Void

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: isPad ? 5 : 3) {
                Image(systemName: "house.fill")
                    .font((isPad ? Font.title3 : Font.subheadline).weight(.black))
                    .frame(width: isPad ? 58 : 40, height: isPad ? 58 : 40)
                    .foregroundStyle(.black.opacity(0.84))
                    .background(
                        LinearGradient(
                            colors: [Color.simitAmber, Color(red: 0.98, green: 0.55, blue: 0.20)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: Circle()
                    )
                    .overlay(Circle().stroke(Color.simitCream.opacity(0.62), lineWidth: 2))
                    .shadow(color: Color.simitAmber.opacity(0.44), radius: 16, y: 8)

                Text("MENÜ")
                    .font(.system(size: isPad ? 10 : 8, weight: .black))
                    .foregroundStyle(Color.simitCream.opacity(0.86))
                    .padding(.horizontal, isPad ? 8 : 6)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.28), in: Capsule())
                    .overlay(Capsule().stroke(Color.simitAmber.opacity(0.28), lineWidth: 1))
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Ana menü")
    }
}

private struct HomeXPBadge: View {
    @ObservedObject var game: GameSession

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    private var total: Int {
        guard let next = game.xpForNextLevel else { return max(game.xp, 1) }
        let current = GameProgression.requiredXP(for: game.level)
        return max(1, next - current)
    }

    private var currentLevelXP: Int {
        guard game.xpForNextLevel != nil else { return game.xp }
        return max(0, game.xp - GameProgression.requiredXP(for: game.level))
    }

    private var progress: Double {
        guard total > 0 else { return 1 }
        return min(1, Double(currentLevelXP) / Double(total))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isPad ? 11 : 8) {
            HStack(spacing: isPad ? 11 : 8) {
                ZStack {
                    Circle()
                        .fill(Color.simitAmber.opacity(0.18))
                    Circle()
                        .stroke(Color.simitAmber.opacity(0.45), lineWidth: 1)
                    Text("\(game.level)")
                        .font(.system(size: isPad ? 21 : 15, weight: .black, design: .rounded))
                        .foregroundStyle(Color.simitCream)
                }
                .frame(width: isPad ? 44 : 32, height: isPad ? 44 : 32)

                VStack(alignment: .leading, spacing: 1) {
                    Text("SEVİYE")
                        .font(.system(size: isPad ? 11 : 9, weight: .black))
                        .foregroundStyle(.white.opacity(0.44))
                    Text(game.xpForNextLevel.map { _ in "\(currentLevelXP)/\(total) XP" } ?? "\(game.xp) XP")
                        .font(.system(size: isPad ? 13 : 11, weight: .black, design: .rounded))
                        .foregroundStyle(.white.opacity(0.82))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.black.opacity(0.32))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.simitTeal, Color.simitAmber],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(10, proxy.size.width * progress))
                    Capsule()
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                }
            }
            .frame(height: isPad ? 11 : 8)
        }
        .frame(width: isPad ? 190 : 120)
        .padding(isPad ? 16 : 10)
        .background(.black.opacity(0.34), in: RoundedRectangle(cornerRadius: isPad ? 20 : 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: isPad ? 20 : 16, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.simitCream.opacity(0.30), Color.simitAmber.opacity(0.18)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

private struct MiniRushCard: View {
    @ObservedObject var game: GameSession

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    private var hasExtraService: Bool {
        game.hasExtraServiceOpportunity
    }

    private var hasPendingExtraService: Bool {
        game.hasPendingExtraServiceOpportunity
    }

    private var isCompleted: Bool {
        game.hasPlayedRushToday && !game.canPrepareNextDay && !hasExtraService && !hasPendingExtraService
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isPad ? 10 : 7) {
            HStack(spacing: isPad ? 10 : 8) {
                if isCompleted {
                    Text("Tamamlandı")
                        .font(.system(size: isPad ? 10 : 8, weight: .black))
                        .foregroundStyle(Color.simitSuccess)
                        .padding(.horizontal, isPad ? 9 : 6)
                        .padding(.vertical, isPad ? 5 : 4)
                        .background(Color.simitSuccess.opacity(0.14), in: Capsule())
                        .overlay(Capsule().stroke(Color.simitSuccess.opacity(0.34), lineWidth: 1))
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)
                } else {
                    ZStack {
                        Circle()
                            .fill(statusTint.opacity(0.26))
                        Circle()
                            .stroke(statusTint.opacity(0.62), lineWidth: 1)
                        Image(systemName: statusIcon)
                            .font((isPad ? Font.title3 : Font.headline).weight(.black))
                            .foregroundStyle(statusTint)
                    }
                    .frame(width: isPad ? 46 : 36, height: isPad ? 46 : 36)
                }

                Text(statusTitle)
                    .font(.system(size: isPad ? 18 : 14, weight: .black, design: .rounded))
                    .foregroundStyle(Color.simitCream)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            Text(statusSubtitle)
                .font((isPad ? Font.caption : Font.caption2).weight(.bold))
                .foregroundStyle(.white.opacity(0.62))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            Text(statusFooter)
                .font(.system(size: isPad ? 12 : 10, weight: .black))
                .foregroundStyle(statusTint)
        }
        .frame(maxWidth: .infinity, minHeight: isPad ? 170 : 78, alignment: .leading)
        .padding(isPad ? 26 : 12)
        .foregroundStyle(Color.simitCream)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.34), Color.simitStand.opacity(0.42)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.simitCream.opacity(isPad ? 0.22 : 0.16), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.18), radius: 10, x: 0, y: 8)
    }

    private var statusTint: Color {
        hasExtraService || hasPendingExtraService ? .simitAmber : (game.hasPlayedRushToday ? (game.canPrepareNextDay ? .simitAmber : .simitSuccess) : .simitTeal)
    }

    private var statusIcon: String {
        hasExtraService ? "timer" : (hasPendingExtraService ? "hourglass" : (game.hasPlayedRushToday ? (game.canPrepareNextDay ? "sunrise.fill" : "seal.fill") : "timer"))
    }

    private var statusTitle: String {
        hasExtraService ? "Ek Servis Hazır" : (hasPendingExtraService ? "Ek Servis Bekleniyor" : (game.hasPlayedRushToday ? (game.canPrepareNextDay ? "Yeni Gün" : "Servis Bitti") : "Servis Durumu"))
    }

    private var statusSubtitle: String {
        hasExtraService || hasPendingExtraService ? game.extraServiceOpportunityText : (game.hasPlayedRushToday ? game.nextServiceLockText : "Bugün 1 ana servis hakkın var.")
    }

    private var statusFooter: String {
        hasExtraService ? "20 saniyelik servis" : (hasPendingExtraService ? "Bildirim gelir" : (game.hasPlayedRushToday ? (game.canPrepareNextDay ? "Hazırlığa geçilebilir" : "Servis deftere işlendi") : "Ana servis hazır"))
    }
}

private enum HomePrepButtonStyle {
    case primary
    case settlement
}

private struct HomePrepButton: View {
    let title: String
    var systemImage: String = "cart.fill.badge.plus"
    var style: HomePrepButtonStyle = .primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            let isPad = UIDevice.current.userInterfaceIdiom == .pad

            VStack(alignment: .leading, spacing: isPad ? 12 : 8) {
                HStack(spacing: isPad ? 11 : 8) {
                    Image(systemName: systemImage)
                        .font((isPad ? Font.title2 : Font.headline).weight(.black))
                        .frame(width: isPad ? 58 : 36, height: isPad ? 58 : 36)
                        .foregroundStyle(Color.simitCream)
                        .background(.black.opacity(0.24), in: Circle())

                    Text(title)
                        .font(.system(size: isPad ? 22 : 18, weight: .black, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.70)
                }

                Spacer(minLength: 0)

                HStack(spacing: 5) {
                    Text(footerTitle)
                        .font(.system(size: isPad ? 12 : 10, weight: .black))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font((isPad ? Font.subheadline : Font.caption).weight(.black))
                }
                .opacity(0.72)
            }
            .padding(isPad ? 28 : 16)
            .frame(maxWidth: .infinity, minHeight: isPad ? 170 : 96, alignment: .leading)
            .foregroundStyle(.black.opacity(0.82))
            .background(
                LinearGradient(
                    colors: [
                            Color.simitAmber,
                            style == .settlement ? Color.simitCounter.opacity(0.96) : Color(red: 0.95, green: 0.48, blue: 0.18),
                            Color.simitStand
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: isPad ? 28 : 24, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: isPad ? 28 : 24, style: .continuous)
                    .stroke(Color.simitCream.opacity(style == .settlement ? 0.30 : 0.48), lineWidth: 1)
            )
            .shadow(color: Color.simitAmber.opacity(style == .settlement ? 0.16 : 0.34), radius: style == .settlement ? 10 : 18, x: 0, y: 10)
            .scaleEffect(style == .settlement ? 1 : (isPad ? 1.01 : 1.015))
        }
        .buttonStyle(.plain)
    }

    private var footerTitle: String {
        switch title {
        case "Tezgâh Aç":
            return "Hazırlık"
        case "Kapanış Kararı":
            return "Rapor"
        case "Yeni Gün Hazır":
            return "Devam"
        default:
            return "Muhasebe"
        }
    }
}

private struct ShopStatusCard: View {
    @ObservedObject var game: GameSession

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        GeometryReader { proxy in
            let isWide = proxy.size.width > 560

            VStack(spacing: isPad ? 16 : 12) {
                HStack(spacing: isPad ? 24 : (isWide ? 16 : 8)) {
                    HomeMenuFloatingButton {
                        game.openMainMenu()
                    }
                    .frame(width: isPad ? 76 : 46)

                    VStack(alignment: .leading, spacing: isPad ? 10 : 6) {
                        Text("Sahil Tezgâhı")
                            .font(.system(size: isPad ? 38 : (isWide ? 28 : 24), weight: .black, design: .rounded))
                            .foregroundStyle(Color.simitCream)
                            .lineLimit(1)
                            .minimumScaleFactor(0.58)
                        Text(game.cartLevelName)
                            .font((isPad ? Font.headline : Font.caption).weight(.bold))
                            .foregroundStyle(.white.opacity(0.68))
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)

                        LastServiceInlineStats(report: game.lastReport, isPad: isPad)
                    }
                    .layoutPriority(3)

                    Spacer()

                    NeonOpenSign(isOpen: !game.hasPlayedRushToday, isPad: isPad)
                        .frame(width: isPad ? nil : 58, alignment: .trailing)
                        .layoutPriority(0)
                }
            }
            .padding(isPad ? 32 : 14)
            .background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: isPad ? 28 : 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: isPad ? 28 : 22, style: .continuous)
                    .stroke(Color.simitCream.opacity(0.20), lineWidth: 1)
            )
            .shadow(color: Color.simitStand.opacity(isWide ? 0.24 : 0.12), radius: isWide ? 22 : 10, x: 0, y: 12)
        }
        .frame(height: isPad ? 190 : 118)
    }
}

private struct LastServiceInlineStats: View {
    let report: DayReport?
    let isPad: Bool

    var body: some View {
        if let report {
            HStack(spacing: isPad ? 8 : 4) {
                InlineServiceMetric(
                    value: "\(report.netProfit >= 0 ? "+" : "")\(report.netProfit) TL",
                    systemImage: "banknote.fill",
                    tint: report.netProfit >= 0 ? .simitSuccess : .simitDanger,
                    isPad: isPad,
                    minWidth: isPad ? 122 : 70
                )
                InlineServiceMetric(value: "\(report.served)", systemImage: "checkmark.circle.fill", tint: .simitSuccess, isPad: isPad, minWidth: isPad ? 48 : 30)
                InlineServiceMetric(value: "\(report.missed)", systemImage: "figure.walk", tint: .simitDanger, isPad: isPad, minWidth: isPad ? 48 : 30)
                InlineServiceMetric(value: "\(report.wrong)", systemImage: "xmark.circle.fill", tint: .simitDanger, isPad: isPad, minWidth: isPad ? 48 : 30)
            }
            .padding(.top, 1)
        }
    }
}

private struct InlineServiceMetric: View {
    let value: String
    let systemImage: String
    let tint: Color
    let isPad: Bool
    let minWidth: CGFloat

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.system(size: isPad ? 11 : 9, weight: .black))
                .foregroundStyle(tint)
            Text(value)
                .font(.system(size: isPad ? 12 : 10, weight: .black, design: .rounded))
                .foregroundStyle(Color.simitCream.opacity(0.82))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(minWidth: minWidth)
        .padding(.horizontal, isPad ? 8 : 5)
        .padding(.vertical, isPad ? 5 : 4)
        .background(Color.black.opacity(0.22), in: Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.10), lineWidth: 1))
    }
}

private struct NeonOpenSign: View {
    let isOpen: Bool
    let isPad: Bool
    @State private var glow = false

    private var tint: Color {
        isOpen ? .simitAmber : .simitDanger
    }

    var body: some View {
        Text(isOpen ? "AÇIK" : "KAPALI")
            .font(.system(size: isPad ? 13 : 11, weight: .black))
            .foregroundStyle(isOpen ? Color.simitCream : tint)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .padding(.horizontal, isPad ? 15 : 10)
            .padding(.vertical, isPad ? 8 : 6)
            .background(
                LinearGradient(
                    colors: [Color.black.opacity(0.46), tint.opacity(isOpen ? 0.22 : 0.16)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: Capsule()
            )
            .overlay(Capsule().stroke(tint.opacity(glow ? 0.90 : 0.42), lineWidth: 1.4))
            .shadow(color: tint.opacity(glow ? 0.50 : 0.12), radius: glow ? 9 : 2)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.35).repeatForever(autoreverses: true)) {
                    glow = true
                }
            }
    }
}

private struct CartBadge: View {
    var size: CGFloat = 54

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.simitCream.opacity(0.22),
                            Color.simitAmber.opacity(0.12)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .stroke(Color.simitCream.opacity(0.28), lineWidth: 1.5)

            Image(systemName: "cart.fill")
                .font(.title2.weight(.black))
                .foregroundStyle(Color.simitCream)
        }
        .frame(width: size, height: size)
    }
}

private struct CompactStatus: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.caption.weight(.black))
                .foregroundStyle(tint)
            Text(value)
                .font(.caption.weight(.black))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text(title.uppercased())
                .font(.system(size: 8, weight: .black))
                .foregroundStyle(.white.opacity(0.38))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
    }
}
