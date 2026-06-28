import SwiftUI

struct ContentView: View {
    @StateObject private var game = GameSession()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            GameBackground(theme: game.activeTheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                currentScreen

                if showsBottomNavigation {
                    AppBottomNavigation(game: game)
                        .frame(maxWidth: 700)
                        .padding(.horizontal, 18)
                        .padding(.top, 6)
                        .padding(.bottom, UIDevice.current.userInterfaceIdiom == .pad ? 14 : 8)
                        .background(.black.opacity(0.20))
                }
            }

            if let presentation = game.levelUpPresentation {
                LevelUpOverlay(presentation: presentation) {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        game.levelUpPresentation = nil
                    }
                }
                .transition(.scale(scale: 0.88).combined(with: .opacity))
                .zIndex(10)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            game.authenticateGameCenter()
            updateAudio(for: game.screen)
        }
        .onChange(of: game.screen) { _, screen in
            updateAudio(for: screen)
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            game.refreshForForeground()
            updateAudio(for: game.screen)
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.78), value: game.levelUpPresentation)
    }

    @ViewBuilder
    private var currentScreen: some View {
        switch game.screen {
        case .mainMenu:
            MainMenuView(game: game)
        case .introStory:
            IntroStoryView(game: game)
        case .home:
            HomeView(game: game)
        case .prep:
            PrepView(game: game)
        case .rush:
            RushView(game: game)
        case .report:
            ReportView(game: game)
        case .dayClose:
            DayCloseView(game: game)
        case .absenceReport:
            AbsenceReportView(game: game)
        case .store:
            StoreView(game: game)
        case .settings:
            SettingsView(game: game)
        case .market:
            MarketView(game: game)
        case .upgrades:
            UpgradesView(game: game)
        case .profile:
            ProfileView(game: game)
        case .bankruptcy:
            BankruptcyView(game: game)
        }
    }

    private var showsBottomNavigation: Bool {
        switch game.screen {
        case .home, .market, .upgrades, .profile:
            true
        case .mainMenu, .introStory, .prep, .rush, .report, .dayClose, .absenceReport, .store, .settings, .bankruptcy:
            false
        }
    }

    private func updateAudio(for screen: GameScreen) {
        switch screen {
        case .home, .market, .upgrades, .profile:
            GameAudio.shared.startAmbience(.shop, volume: 0.12)
        case .rush:
            GameAudio.shared.startAmbience(.shop, volume: 0.045)
        case .dayClose:
            GameAudio.shared.stopAmbience()
            GameAudio.shared.play(.report, volume: 0.32)
        default:
            GameAudio.shared.stopAmbience()
        }
    }
}

private struct LevelUpOverlay: View {
    let presentation: LevelUpPresentation
    let dismiss: () -> Void

    @State private var isVisible = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.62)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.simitAmber.opacity(0.20))
                        .frame(width: 126, height: 126)
                        .scaleEffect(isVisible ? 1 : 0.58)

                    Circle()
                        .stroke(Color.simitAmber.opacity(0.62), lineWidth: 2)
                        .frame(width: 104, height: 104)

                    Text("\(presentation.level)")
                        .font(.system(size: 58, weight: .black, design: .rounded))
                        .foregroundStyle(Color.simitCream)
                        .contentTransition(.numericText())
                }

                VStack(spacing: 4) {
                    Text("SEVİYE \(presentation.level)")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(Color.simitCream)
                    Text("Tezgâh büyüyor")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white.opacity(0.66))
                }

                VStack(alignment: .leading, spacing: 9) {
                    ForEach(presentation.unlocks, id: \.self) { unlock in
                        Label(unlock, systemImage: "lock.open.fill")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white.opacity(0.86))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                Button(action: dismiss) {
                    Text("Devam Et")
                        .font(.headline.weight(.black))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .foregroundStyle(.black.opacity(0.82))
                        .background(Color.simitAmber, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(22)
            .frame(maxWidth: 420)
            .background(
                LinearGradient(
                    colors: [Color.black.opacity(0.88), Color.simitStand.opacity(0.92)],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                in: RoundedRectangle(cornerRadius: 24, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.simitAmber.opacity(0.52), lineWidth: 1.5)
            )
            .shadow(color: Color.simitAmber.opacity(0.24), radius: 30, y: 14)
            .padding(24)
            .scaleEffect(isVisible ? 1 : 0.84)
            .opacity(isVisible ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.48, dampingFraction: 0.68)) {
                isVisible = true
            }
        }
    }
}

private struct AppBottomNavigation: View {
    @ObservedObject var game: GameSession

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        HStack(spacing: isPad ? 9 : 6) {
            BottomNavButton(
                title: "Market",
                systemImage: "cart.fill",
                isSelected: game.screen == .market
            ) {
                game.openMarket()
            }

            BottomNavButton(
                title: "Dükkan",
                systemImage: "house.fill",
                isSelected: game.screen == .home,
                isPrimary: true
            ) {
                game.backHome()
            }

            BottomNavButton(
                title: "Esnaf",
                systemImage: "person.fill",
                isSelected: game.screen == .profile
            ) {
                game.openProfile()
            }
        }
        .padding(isPad ? 8 : 6)
        .background(.black.opacity(0.46), in: RoundedRectangle(cornerRadius: isPad ? 26 : 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: isPad ? 26 : 20, style: .continuous)
                .stroke(Color.simitCream.opacity(0.14), lineWidth: 1)
        )
    }
}

private struct BottomNavButton: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    var isPrimary: Bool = false
    let action: () -> Void

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: isPad ? 5 : 4) {
                Image(systemName: systemImage)
                    .font((isPrimary ? (isPad ? Font.title2 : Font.title3) : (isPad ? Font.title3 : Font.headline)).weight(.black))
                Text(title.uppercased())
                    .font(.system(size: isPad ? 11 : 10, weight: .black))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, isPad ? (isPrimary ? 15 : 14) : (isPrimary ? 11 : 10))
            .foregroundStyle(isSelected ? .black.opacity(0.82) : Color.simitCream.opacity(0.72))
            .background(isSelected ? Color.simitAmber : Color.clear, in: RoundedRectangle(cornerRadius: isPad ? 19 : 15, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private enum ProfileSection: String, CaseIterable, Identifiable {
    case general
    case finance
    case social
    case achievements

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: "Genel"
        case .finance: "Finans"
        case .social: "Sosyal"
        case .achievements: "Başarımlar"
        }
    }

    var systemImage: String {
        switch self {
        case .general: "person.fill"
        case .finance: "building.columns.fill"
        case .social: "trophy.fill"
        case .achievements: "rosette"
        }
    }
}

private struct ProfileView: View {
    @ObservedObject var game: GameSession
    @State private var selectedSection: ProfileSection = .general

    var body: some View {
        GeometryReader { proxy in
            let isPad = proxy.size.width > 700

            ScrollView {
                VStack(spacing: isPad ? 18 : 16) {
                    ScreenTitle(
                        title: "Esnaf",
                        subtitle: "Profil, finans, sosyal sıralama ve başarımlar."
                    )
                    .padding(.top, isPad ? 28 : 18)

                    ProfileStatusPanel(game: game)
                    ProfileSectionPicker(selectedSection: $selectedSection)

                    ProfileSectionContent(game: game, section: selectedSection, isPad: isPad)

                    Spacer(minLength: 18)
                }
                .frame(maxWidth: isPad ? 1060 : .infinity)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, isPad ? 44 : 20)
                .padding(.top, isPad ? 18 : 20)
                .padding(.bottom, isPad ? 110 : 20)
            }
        }
    }
}

private struct ProfileSectionPicker: View {
    @Binding var selectedSection: ProfileSection

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        HStack(spacing: isPad ? 10 : 7) {
            ForEach(ProfileSection.allCases) { section in
                Button {
                    withAnimation(.spring(response: 0.26, dampingFraction: 0.84)) {
                        selectedSection = section
                    }
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: section.systemImage)
                            .font(.headline.weight(.black))
                        Text(section.title.uppercased())
                            .font(.system(size: isPad ? 11 : 10, weight: .black))
                            .lineLimit(1)
                            .minimumScaleFactor(0.62)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, isPad ? 14 : 12)
                    .foregroundStyle(selectedSection == section ? .black.opacity(0.82) : Color.simitCream.opacity(0.72))
                    .background(selectedSection == section ? Color.simitAmber : Color.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .stroke(selectedSection == section ? Color.simitCream.opacity(0.35) : Color.white.opacity(0.08), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(.black.opacity(0.20), in: RoundedRectangle(cornerRadius: 19, style: .continuous))
    }
}

private struct ProfileSectionContent: View {
    @ObservedObject var game: GameSession
    let section: ProfileSection
    let isPad: Bool

    var body: some View {
        Group {
            switch section {
            case .general:
                if isPad {
                    HStack(alignment: .top, spacing: 16) {
                        VStack(spacing: 16) {
                            ProfilePersonalPanel(game: game)
                        }
                        VStack(spacing: 16) {
                            DailyTasksPanel(game: game)
                        }
                    }
                } else {
                    ProfilePersonalPanel(game: game)
                    DailyTasksPanel(game: game)
                }
            case .finance:
                if isPad {
                    HStack(alignment: .top, spacing: 16) {
                        ProfileFinanceSummaryPanel(game: game)
                        ProfileBankPanel(game: game)
                    }
                } else {
                    ProfileFinanceSummaryPanel(game: game)
                    ProfileBankPanel(game: game)
                }
            case .social:
                ProfileSocialPanel(game: game)
            case .achievements:
                ProfileAchievementsPanel(game: game)
            }
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
}

private struct ProfilePersonalPanel: View {
    @ObservedObject var game: GameSession
    @State private var draftName = ""
    @State private var isExpanded = false

    private var hasNameChange: Bool {
        draftName.trimmingCharacters(in: .whitespacesAndNewlines) != game.playerName
    }

    var body: some View {
        DisclosureActionPanel(
            title: "Profil",
            subtitle: "\(game.playerName) • \(game.cartLevelName)",
            systemImage: game.playerAvatar.systemImage,
            tint: .simitAmber,
            isExpanded: $isExpanded
        ) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.black.opacity(0.18))
                        Circle()
                            .stroke(Color.simitCream.opacity(0.18), lineWidth: 1)
                        Image(systemName: game.playerAvatar.systemImage)
                            .font(.system(size: 30, weight: .black))
                            .foregroundStyle(Color.simitAmber)
                    }
                    .frame(width: 66, height: 66)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            TextField("Simitçi adı", text: $draftName)
                                .font(.headline.weight(.black))
                                .foregroundStyle(Color.simitCream)
                                .textInputAutocapitalization(.words)
                                .submitLabel(.done)
                                .onSubmit {
                                    game.updatePlayerName(draftName)
                                }

                            Button {
                                game.updatePlayerName(draftName)
                            } label: {
                                Image(systemName: hasNameChange ? "checkmark" : "checkmark.seal.fill")
                                    .font(.caption.weight(.black))
                                    .frame(width: 30, height: 30)
                                    .background(hasNameChange ? Color.simitAmber : Color.simitSuccess.opacity(0.20), in: Circle())
                                    .foregroundStyle(hasNameChange ? .black.opacity(0.82) : Color.simitSuccess)
                            }
                            .buttonStyle(.plain)
                            .disabled(!hasNameChange)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(Color.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                        Text("\(game.cartLevelName) · Gün \(game.currentDay)")
                            .font(.caption.weight(.black))
                            .foregroundStyle(.white.opacity(0.58))
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                    }
                }

                HStack(spacing: 8) {
                    ForEach(PlayerAvatar.allCases) { avatar in
                        Button {
                            game.selectAvatar(avatar)
                        } label: {
                            Image(systemName: avatar.systemImage)
                                .font(.headline.weight(.black))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .foregroundStyle(game.playerAvatar == avatar ? .black.opacity(0.82) : Color.simitCream.opacity(0.72))
                                .background(game.playerAvatar == avatar ? Color.simitAmber : Color.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(avatar.title)
                    }
                }
            }
        }
        .onAppear {
            draftName = game.playerName
        }
        .onChange(of: game.playerName) { _, name in
            draftName = name
        }
    }
}

private struct ProfileStatusPanel: View {
    @ObservedObject var game: GameSession

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    private var statColumns: [GridItem] {
        let count = UIDevice.current.userInterfaceIdiom == .pad ? 3 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 10), count: count)
    }

    var body: some View {
        StandPanel {
            VStack(alignment: .leading, spacing: isPad ? 20 : 14) {
                HStack(spacing: isPad ? 20 : 14) {
                    ZStack {
                        Circle()
                            .fill(Color.simitAmber.opacity(0.18))
                        Circle()
                            .stroke(Color.simitAmber.opacity(0.38), lineWidth: 1.5)
                        Text("\(game.level)")
                            .font(.system(size: isPad ? 46 : 34, weight: .black, design: .rounded))
                            .foregroundStyle(Color.simitCream)
                    }
                    .frame(width: isPad ? 96 : 76, height: isPad ? 96 : 76)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(game.playerName)
                            .font((isPad ? Font.title : Font.title2).weight(.black))
                            .foregroundStyle(Color.simitCream)
                            .lineLimit(1)
                            .minimumScaleFactor(0.74)
                        Label(game.esnafTitle.title, systemImage: game.esnafTitle.systemImage)
                            .font((isPad ? Font.subheadline : Font.caption).weight(.black))
                            .foregroundStyle(Color.simitAmber)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                        Text(game.esnafTitle.detail)
                            .font((isPad ? Font.caption : Font.caption2).weight(.bold))
                            .foregroundStyle(.white.opacity(0.54))
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                        ProfileXPBar(game: game)
                    }
                }

                LazyVGrid(columns: statColumns, spacing: 10) {
                    ProfileStatPill(title: "Esnaf Skoru", value: "\(game.esnafScore.formatted(.number.grouping(.automatic)))", systemImage: "trophy.fill", tint: .simitAmber)
                    ProfileStatPill(title: "Unvan", value: game.esnafTitle.title, systemImage: game.esnafTitle.systemImage, tint: .simitCream)
                    ProfileStatPill(title: "Kasa", value: "\(game.cash) TL", systemImage: "banknote.fill", tint: .simitAmber)
                    ProfileStatPill(title: "İtibar", value: "\(game.reputation)", systemImage: "heart.fill", tint: .simitDanger)
                    ProfileStatPill(title: "Borç", value: "\(game.debt) TL", systemImage: "creditcard.fill", tint: .simitTeal)
                    ProfileStatPill(title: "Limit", value: "\(game.bankruptcyLimit) TL", systemImage: "exclamationmark.triangle.fill", tint: .simitCream)
                }
            }
        }
    }
}

private struct ProfileStatPill: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        HStack(spacing: isPad ? 11 : 8) {
            Image(systemName: systemImage)
                .font((isPad ? Font.subheadline : Font.caption).weight(.black))
                .foregroundStyle(tint)
                .frame(width: isPad ? 38 : 28, height: isPad ? 38 : 28)
                .background(tint.opacity(0.13), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(.system(size: isPad ? 11 : 9, weight: .black))
                    .foregroundStyle(.white.opacity(0.42))
                    .lineLimit(1)
                Text(value)
                    .font((isPad ? Font.subheadline : Font.caption).weight(.black))
                    .foregroundStyle(Color.simitCream)
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }
            Spacer(minLength: 0)
        }
        .padding(isPad ? 14 : 10)
        .background(Color.black.opacity(0.16), in: RoundedRectangle(cornerRadius: isPad ? 17 : 13, style: .continuous))
    }
}

private struct DailyTasksPanel: View {
    @ObservedObject var game: GameSession
    @State private var isExpanded = false

    private var completedCount: Int {
        game.dailyTasks.filter { game.progress(for: $0) >= $0.target }.count
    }

    private var claimableCount: Int {
        game.dailyTasks.filter { game.canClaimDailyTask($0) }.count
    }

    var body: some View {
        DisclosureActionPanel(
            title: "Günlük Hedefler",
            subtitle: claimableCount > 0 ? "\(claimableCount) ödül hazır • AL" : "\(completedCount)/\(game.dailyTasks.count) tamam • oyun günü sonunda yenilenir",
            systemImage: "checklist.checked",
            tint: claimableCount > 0 ? .simitSuccess : (completedCount == game.dailyTasks.count ? .simitSuccess : .simitTeal),
            subtitleColor: claimableCount > 0 ? .simitSuccess : .white.opacity(0.54),
            isExpanded: $isExpanded
        ) {
            VStack(alignment: .leading, spacing: 12) {
                VStack(spacing: 9) {
                    ForEach(game.dailyTasks) { task in
                        DailyTaskRow(task: task, game: game)
                    }
                }

                Text("Yeni oyun gününe geçince hedefler yenilenir. Ödüller küçük destek verir, ekonomiyi kırmaz.")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.46))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct DailyTaskRow: View {
    let task: DailyTaskDefinition
    @ObservedObject var game: GameSession

    private var progress: Int {
        game.progress(for: task)
    }

    private var fraction: Double {
        task.target > 0 ? min(1, Double(progress) / Double(task.target)) : 0
    }

    private var isClaimed: Bool {
        game.claimedDailyTasks.contains(task.id)
    }

    private var canClaim: Bool {
        game.canClaimDailyTask(task)
    }

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.10), lineWidth: 5)
                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke(taskTint, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: isClaimed ? "checkmark" : task.systemImage)
                    .font(.caption.weight(.black))
                    .foregroundStyle(taskTint)
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(task.title)
                        .font(.caption.weight(.black))
                        .foregroundStyle(Color.simitCream)
                    Spacer()
                    Text(statusText)
                        .font(.caption2.weight(.black))
                        .foregroundStyle(taskTint)
                }

                ProgressView(value: fraction)
                    .tint(taskTint)

                Text("\(task.detail) · +\(task.rewardCash) TL / +\(task.rewardXP) XP")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.46))
                    .lineLimit(2)
                    .minimumScaleFactor(0.74)
            }

            Button {
                game.claimDailyTask(task)
            } label: {
                Text(isClaimed ? "Alındı" : (canClaim ? "Ödülü Al" : "Al"))
                    .font(.caption2.weight(.black))
                    .padding(.horizontal, canClaim ? 12 : 10)
                    .padding(.vertical, 8)
                    .background(canClaim ? Color.simitAmber : Color.black.opacity(0.16), in: Capsule())
                    .foregroundStyle(canClaim ? .black.opacity(0.82) : .white.opacity(0.36))
                    .overlay(
                        Capsule()
                            .stroke(canClaim ? Color.simitCream.opacity(0.55) : .clear, lineWidth: 1)
                    )
                    .shadow(color: canClaim ? Color.simitAmber.opacity(0.32) : .clear, radius: 8, y: 3)
            }
            .buttonStyle(.plain)
            .disabled(!canClaim)
        }
        .padding(10)
        .background(Color.black.opacity(canClaim ? 0.24 : 0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(taskTint.opacity(canClaim ? 0.32 : 0.10), lineWidth: 1)
        )
    }

    private var taskTint: Color {
        isClaimed ? .simitSuccess : (fraction >= 1 ? .simitAmber : .simitTeal)
    }

    private var statusText: String {
        if isClaimed { return "Tamam" }
        return "\(progress)/\(task.target)"
    }
}

private struct LastRushPanel: View {
    @ObservedObject var game: GameSession

    var body: some View {
        GameCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Son Servis", systemImage: "chart.bar.fill")

                if let report = game.lastReport {
                    HStack(spacing: 10) {
                        MetricTile(title: "Net", value: "\(report.netProfit) TL", systemImage: "banknote.fill")
                        MetricTile(title: "XP", value: "+\(report.xpEarned)", systemImage: "star.fill", tint: .simitAmber)
                    }
                    HStack(spacing: 10) {
                        MetricTile(title: "Servis", value: "\(report.served)", systemImage: "checkmark.seal.fill", tint: .simitSuccess)
                        MetricTile(title: "Hata", value: "\(report.missed + report.wrong)", systemImage: "xmark.octagon.fill", tint: .simitDanger)
                    }
                } else {
                    Text("Henüz rapor yok.")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white.opacity(0.58))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

private struct ProfileStorePanel: View {
    @ObservedObject var game: GameSession
    @State private var isExpanded = false

    var body: some View {
        DisclosureActionPanel(
            title: "Koleksiyon",
            subtitle: "Manzara temaları ve küçük destek paketleri",
            systemImage: "storefront.fill",
            tint: .simitAmber,
            isExpanded: $isExpanded
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Manzaralar sadece görünüm değiştirir; ekonomi avantajı vermez.")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.56))

                HStack(spacing: 10) {
                    StoreButton(title: GameTheme.morning.title, detail: themeDetail(.morning), systemImage: GameTheme.morning.systemImage) {
                        game.selectTheme(.morning)
                    }
                    StoreButton(title: GameTheme.evening.title, detail: themeDetail(.evening), systemImage: GameTheme.evening.systemImage) {
                        handleThemeTap(.evening)
                    }
                }

                HStack(spacing: 10) {
                    StoreButton(title: GameTheme.rainy.title, detail: themeDetail(.rainy), systemImage: GameTheme.rainy.systemImage) {
                        handleThemeTap(.rainy)
                    }
                    StoreButton(title: "Destekler", detail: "Aç", systemImage: "gift.fill") {
                        game.openStore()
                    }
                }

                Text("Destekler günlük sınırlıdır; küçük nefes aldırır, işletme ekonomisini tek başına taşımaz.")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.46))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func themeDetail(_ theme: GameTheme) -> String {
        if game.activeTheme == theme { return "Aktif" }
        if game.isThemeUnlocked(theme) { return "Seç" }
        return "\(theme.unlockPrice.formatted(.number.grouping(.automatic))) TL"
    }

    private func handleThemeTap(_ theme: GameTheme) {
        if game.isThemeUnlocked(theme) {
            game.selectTheme(theme)
        } else {
            game.unlockTheme(theme)
        }
    }
}

private struct ProfileFinanceSummaryPanel: View {
    @ObservedObject var game: GameSession

    var body: some View {
        GameCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Finans Özeti", systemImage: "chart.line.uptrend.xyaxis")

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    MetricTile(title: "Kasa", value: "\(game.cash) TL", systemImage: "banknote.fill", tint: .simitAmber)
                    MetricTile(title: "Borç", value: "\(game.debt) TL", systemImage: "creditcard.fill", tint: game.debt > 0 ? .simitDanger : .simitTeal)
                    MetricTile(title: "Kira", value: "\(game.dailyFixedCost) TL", systemImage: "building.2.fill", tint: .simitCream)
                    MetricTile(title: "Limit", value: "\(game.bankruptcyLimit) TL", systemImage: "exclamationmark.triangle.fill", tint: .simitDanger)
                }

                Text(financeHint)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.54))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var financeHint: String {
        if game.debt > 0 {
            return "Ana servis kapanışında kredi taksidi otomatik düşer. Borç bitince banka rahatlar."
        }
        return "Kredi sadece sen onaylarsan alınır. Kira ve stok maliyeti günü kapatırken kasadan düşer."
    }
}

private struct ProfileSocialPanel: View {
    @ObservedObject var game: GameSession
    @ObservedObject private var gameCenter = GameCenterService.shared

    var body: some View {
        GameCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Sosyal", systemImage: "trophy.fill")

                HStack(spacing: 12) {
                    Image(systemName: gameCenter.status.systemImage)
                        .font(.title3.weight(.black))
                        .foregroundStyle(statusTint)
                        .frame(width: 46, height: 46)
                        .background(statusTint.opacity(0.15), in: Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text(gameCenter.status.title)
                            .font(.headline.weight(.black))
                            .foregroundStyle(Color.simitCream)
                        Text(gameCenter.status.detail)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white.opacity(0.54))
                    }

                    Spacer()
                }
                .padding(12)
                .background(Color.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 15, style: .continuous))

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    MetricTile(title: "Esnaf Skoru", value: "\(game.esnafScore.formatted(.number.grouping(.automatic)))", systemImage: "trophy.fill", tint: .simitAmber)
                    MetricTile(title: "İşletme", value: "Gün \(game.currentDay)", systemImage: "calendar", tint: .simitTeal)
                    MetricTile(title: "Servis", value: "\(game.telemetry.served)", systemImage: "checkmark.seal.fill", tint: .simitSuccess)
                    MetricTile(title: "Başarı", value: "%\(game.telemetry.serviceSuccessRate)", systemImage: "chart.bar.fill", tint: .simitCream)
                }

                HStack(spacing: 10) {
                    Button {
                        game.openGameCenterLeaderboards()
                    } label: {
                        Label("Sıralamayı Aç", systemImage: "trophy.fill")
                            .font(.caption.weight(.black))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.simitAmber, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                            .foregroundStyle(.black.opacity(0.82))
                    }
                    .buttonStyle(.plain)

                    Button {
                        game.authenticateGameCenter()
                    } label: {
                        Label("Bağlan", systemImage: "gamecontroller.fill")
                            .font(.caption.weight(.black))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                            .foregroundStyle(Color.simitCream)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var statusTint: Color {
        switch gameCenter.status {
        case .authenticated: .simitSuccess
        case .authenticating: .simitAmber
        case .failed: .simitDanger
        case .unavailable: .simitCream
        }
    }
}

private struct ProfileAchievementsPanel: View {
    @ObservedObject var game: GameSession

    private var completedCount: Int {
        game.achievementProgress.filter(\.isComplete).count
    }

    private var columns: [GridItem] {
        UIDevice.current.userInterfaceIdiom == .pad
            ? [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
            : [GridItem(.flexible(), spacing: 10)]
    }

    var body: some View {
        GameCard {
            VStack(alignment: .leading, spacing: 13) {
                HStack {
                    SectionHeader(title: "Başarımlar", systemImage: "rosette")
                    Spacer()
                    Text("\(completedCount)/\(game.achievementProgress.count)")
                        .font(.caption.weight(.black))
                        .foregroundStyle(Color.simitAmber)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.simitAmber.opacity(0.14), in: Capsule())
                }

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(game.achievementProgress) { achievement in
                        AchievementProgressRow(achievement: achievement)
                    }
                }
            }
        }
    }
}

private struct AchievementProgressRow: View {
    let achievement: AchievementProgressItem

    var body: some View {
        HStack(spacing: 11) {
            ZStack {
                Circle()
                    .fill(tint.opacity(achievement.isComplete ? 0.24 : 0.13))
                Circle()
                    .stroke(tint.opacity(achievement.isComplete ? 0.62 : 0.22), lineWidth: 1.5)
                Image(systemName: achievement.isComplete ? "checkmark.seal.fill" : achievement.systemImage)
                    .font(.headline.weight(.black))
                    .foregroundStyle(tint)
            }
            .frame(width: 48, height: 48)
            .shadow(color: achievement.isComplete ? tint.opacity(0.28) : .clear, radius: 10, y: 4)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(achievement.title)
                        .font(.caption.weight(.black))
                        .foregroundStyle(Color.simitCream)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Spacer()
                    Text(achievement.isComplete ? "Tamam" : "\(achievement.current)/\(achievement.target)")
                        .font(.caption2.weight(.black))
                        .foregroundStyle(tint)
                }

                ProgressView(value: achievement.fraction)
                    .tint(tint)

                Text(achievement.detail)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.48))
                    .lineLimit(2)
            }
        }
        .padding(11)
        .background(Color.black.opacity(achievement.isComplete ? 0.24 : 0.15), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(tint.opacity(achievement.isComplete ? 0.34 : 0.10), lineWidth: 1)
        )
    }

    private var tint: Color {
        achievement.isComplete ? .simitSuccess : .simitAmber
    }
}

private struct ProfileBankPanel: View {
    @ObservedObject var game: GameSession
    @State private var isExpanded = false
    @State private var selectedPlan: LoanPlan?

    private var subtitle: String {
        if game.debt > 0 {
            return "Aktif borç \(game.debt) TL • \(game.dailyLoanPayment) TL/gün ödeme"
        }

        return "Kredi limiti \(game.loanLimit) TL • İşler sıkışırsa destek al"
    }

    var body: some View {
        DisclosureActionPanel(
            title: "Esnaf Bankası",
            subtitle: subtitle,
            systemImage: "building.columns.fill",
            tint: .simitTeal,
            isExpanded: $isExpanded
        ) {
            VStack(alignment: .leading, spacing: 12) {
                if let selectedPlan {
                    LoanConfirmationCard(plan: selectedPlan, game: game) {
                        game.takeLoan(selectedPlan)
                        self.selectedPlan = nil
                    } cancel: {
                        self.selectedPlan = nil
                    }
                } else {
                    VStack(spacing: 8) {
                        if game.debt > 0 {
                            LoanStatusCard(game: game)
                        }
                        ForEach(LoanPlan.allCases) { plan in
                            LoanPlanButton(plan: plan, game: game) {
                                selectedPlan = plan
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct LoanStatusCard: View {
    @ObservedObject var game: GameSession

    private var remainingPayments: Int {
        guard game.dailyLoanPayment > 0 else { return 0 }
        return Int(ceil(Double(game.debt) / Double(game.dailyLoanPayment)))
    }

    private var planTitle: String {
        game.activeLoanPlan?.title ?? "Aktif kredi"
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.shield.fill")
                .font(.headline.weight(.black))
                .foregroundStyle(Color.simitAmber)
                .frame(width: 36, height: 36)
                .background(Color.simitAmber.opacity(0.13), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(planTitle)
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white)
                Text("\(remainingPayments) taksit kaldı. Her ana servis sonunda ödeme kesilir.")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.54))
                    .lineLimit(2)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("\(game.debt) TL")
                    .font(.caption.weight(.black))
                    .foregroundStyle(Color.simitCream)
                Text("\(game.dailyLoanPayment) TL/gün")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(Color.simitAmber)
            }
        }
        .padding(10)
        .background(Color.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
    }
}

private struct DisclosureActionPanel<Content: View>: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    let subtitleColor: Color
    @Binding var isExpanded: Bool
    let content: Content

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    init(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color,
        subtitleColor: Color = .white.opacity(0.54),
        isExpanded: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.tint = tint
        self.subtitleColor = subtitleColor
        self._isExpanded = isExpanded
        self.content = content()
    }

    var body: some View {
        GameCard {
            VStack(alignment: .leading, spacing: isExpanded ? (isPad ? 18 : 12) : 0) {
                Button {
                    withAnimation(.spring(response: 0.24, dampingFraction: 0.86)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: isPad ? 16 : 12) {
                        Image(systemName: systemImage)
                            .font((isPad ? Font.title2 : Font.title3).weight(.black))
                            .foregroundStyle(tint)
                            .frame(width: isPad ? 58 : 42, height: isPad ? 58 : 42)
                            .background(tint.opacity(0.15), in: Circle())

                        VStack(alignment: .leading, spacing: 3) {
                            Text(title)
                                .font((isPad ? Font.title3 : Font.headline).weight(.black))
                                .foregroundStyle(.white)
                            Text(subtitle)
                                .font((isPad ? Font.subheadline : Font.caption).weight(.bold))
                                .foregroundStyle(subtitleColor)
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                        }

                        Spacer()

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font((isPad ? Font.subheadline : Font.caption).weight(.black))
                            .foregroundStyle(tint)
                            .frame(width: isPad ? 40 : 30, height: isPad ? 40 : 30)
                            .background(tint.opacity(0.14), in: Circle())
                    }
                }
                .buttonStyle(.plain)

                if isExpanded {
                    content
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(tint.opacity(isExpanded ? 0.26 : 0.16), lineWidth: 1)
        )
    }
}

private struct LoanPlanButton: View {
    let plan: LoanPlan
    @ObservedObject var game: GameSession
    let action: () -> Void

    private var isUnlocked: Bool {
        game.level >= plan.requiredLevel
    }

    private var canTake: Bool {
        game.canTakeLoan(plan)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "creditcard.fill")
                    .font(.headline.weight(.black))
                    .foregroundStyle(canTake ? Color.simitTeal : .white.opacity(0.28))
                    .frame(width: 34, height: 34)
                    .background((canTake ? Color.simitTeal : Color.white).opacity(0.13), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(plan.title)
                        .font(.caption.weight(.black))
                        .foregroundStyle(.white)
                    Text(isUnlocked ? "+\(plan.cashAmount) TL / \(plan.debtAmount) TL borç" : "Lv \(plan.requiredLevel)'te açılır")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white.opacity(0.52))
                }

                Spacer()

                Text(isUnlocked ? "\(plan.dailyPayment)/gün" : "Kilitli")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(canTake ? Color.simitTeal : Color.simitAmber.opacity(0.65))
            }
            .padding(10)
            .background(Color.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!canTake)
        .opacity(canTake || !isUnlocked ? 1 : 0.45)
    }
}

private struct LoanConfirmationCard: View {
    let plan: LoanPlan
    @ObservedObject var game: GameSession
    let confirm: () -> Void
    let cancel: () -> Void

    private var term: Int {
        Int(ceil(Double(plan.debtAmount) / Double(plan.dailyPayment)))
    }

    private var fee: Int {
        plan.debtAmount - plan.cashAmount
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(plan.title)
                        .font(.headline.weight(.black))
                        .foregroundStyle(.white)
                    Text("Lv \(plan.requiredLevel) • Esnaf kredisi")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white.opacity(0.50))
                }
                Spacer()
                Text("+\(plan.cashAmount) TL")
                    .font(.headline.weight(.black))
                    .foregroundStyle(Color.simitTeal)
            }

            HStack(spacing: 8) {
                LoanDetailPill(title: "Vade", value: "\(term) gün")
                LoanDetailPill(title: "Geri Ödeme", value: "\(plan.debtAmount) TL")
                LoanDetailPill(title: "Masraf", value: "\(fee) TL")
            }

            Text("Onaylarsan kasaya \(plan.cashAmount) TL girer, aktif borcun \(plan.debtAmount) TL olur. Her ana servis sonunda \(plan.dailyPayment) TL ödeme kesilir.")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.58))

            HStack(spacing: 10) {
                Button(action: cancel) {
                    Text("Geri Dön")
                        .font(.caption.weight(.black))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .foregroundStyle(Color.simitCream)
                }
                .buttonStyle(.plain)

                Button(action: confirm) {
                    Text("Krediyi Al")
                        .font(.caption.weight(.black))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(game.canTakeLoan(plan) ? Color.simitTeal : Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .foregroundStyle(game.canTakeLoan(plan) ? .black.opacity(0.82) : .white.opacity(0.30))
                }
                .buttonStyle(.plain)
                .disabled(!game.canTakeLoan(plan))
            }
        }
        .padding(12)
        .background(Color.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
    }
}

private struct LoanDetailPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 3) {
            Text(title.uppercased())
                .font(.system(size: 8, weight: .black))
                .foregroundStyle(.white.opacity(0.40))
            Text(value)
                .font(.caption2.weight(.black))
                .foregroundStyle(Color.simitCream)
                .lineLimit(1)
                .minimumScaleFactor(0.70)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
    }
}

private struct StoreButton: View {
    let title: String
    let detail: String
    let systemImage: String
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.headline.weight(.black))
                    .frame(width: 34, height: 34)
                    .background(Color.black.opacity(0.18), in: Circle())
                Text(title)
                    .font(.caption.weight(.black))
                    .lineLimit(1)
                    .minimumScaleFactor(0.70)
                Text(detail)
                    .font(.caption2.weight(.bold))
                    .opacity(0.62)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [Color.black.opacity(0.18), Color.simitStand.opacity(0.30)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 13, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(Color.simitCream.opacity(0.14), lineWidth: 1)
            )
            .foregroundStyle(enabled ? Color.simitCream : Color.simitCream.opacity(0.42))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.58)
    }
}

private struct BankruptcyView: View {
    @ObservedObject var game: GameSession
    @State private var isVisible = false

    var body: some View {
        ZStack {
            Color.black.opacity(isVisible ? 0.50 : 0)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Spacer()

                VStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.simitDanger.opacity(0.16))
                            .frame(width: 92, height: 92)
                        Image(systemName: "storefront.fill")
                            .font(.system(size: 42, weight: .black))
                            .foregroundStyle(Color.simitDanger)
                    }

                    Text("Tezgâh Kapandı")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(Color.simitCream)

                    if let summary = game.lastBankruptcy {
                        Text("Gün \(summary.day), Lv \(summary.level). Kasa \(summary.debt) TL'ye düştü.")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white.opacity(0.64))
                            .multilineTextAlignment(.center)
                    }

                    PrimaryGameButton(title: "Yeni Başlangıç", systemImage: "arrow.clockwise") {
                        game.backHome()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(22)
                .background(Color.black.opacity(0.76), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.simitDanger.opacity(0.48), lineWidth: 1.5)
                )
                .shadow(color: Color.black.opacity(0.48), radius: 30, y: 18)
                .offset(y: isVisible ? 0 : -90)
                .opacity(isVisible ? 1 : 0)

                Spacer()
            }
            .padding(20)
        }
        .onAppear {
            withAnimation(.spring(response: 0.64, dampingFraction: 0.78)) {
                isVisible = true
            }
        }
    }
}

private struct ProfileXPBar: View {
    @ObservedObject var game: GameSession

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
        VStack(alignment: .leading, spacing: 4) {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.black.opacity(0.28))
                    Capsule()
                        .fill(LinearGradient(colors: [.simitTeal, .simitAmber], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(12, proxy.size.width * progress))
                }
            }
            .frame(height: 9)

            Text(game.xpForNextLevel.map { _ in "\(currentLevelXP)/\(total) XP" } ?? "\(game.xp) XP")
                .font(.caption2.weight(.black))
                .foregroundStyle(.white.opacity(0.52))
        }
    }
}
