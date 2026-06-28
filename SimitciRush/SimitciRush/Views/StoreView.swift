import SwiftUI

struct StoreView: View {
    @ObservedObject var game: GameSession

    var body: some View {
        VStack(spacing: 0) {
            MenuHeader(title: "Özel Dükkân", subtitle: "Tema, manzara ve küçük esnaf destekleri") {
                game.openMainMenu()
            }

            ScrollView {
                VStack(spacing: 16) {
                    StoreSection(title: "Manzara Koleksiyonu", systemImage: "photo.fill") {
                        Text("Sadece görünüm değiştirir; servis hızı, kazanç ve ekonomi dengesine avantaj vermez.")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white.opacity(0.58))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(spacing: 10) {
                            ForEach(GameTheme.allCases) { theme in
                                StoreThemeCard(theme: theme, game: game)
                            }
                        }
                    }

                    StoreSection(title: "Esnaf Destekleri", systemImage: "gift.fill") {
                        Text("Destekler oyun parasıyla alınır ve günde 1 kez kullanılır. Kupon nakit vermez; market alışverişinde otomatik indirim olur.")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white.opacity(0.58))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        StoreGrid {
                            StoreActionButton(title: "Kira Desteği", state: supportState(.rentSupport), note: "Bugünkü gideri sınırlı azaltır", systemImage: "mappin.and.ellipse") {
                                game.buyStoreItem(.rentSupport)
                            }
                            StoreActionButton(title: "Stok Paketi", state: supportState(.starterStock), note: "Boş yer varsa tezgâha ekler", systemImage: "shippingbox.fill") {
                                game.buyStoreItem(.starterStock)
                            }
                            StoreActionButton(title: "Tedarik Kuponu", state: supportState(.supplyCoupon), note: "Market alışında otomatik düşer", systemImage: "ticket.fill") {
                                game.buyStoreItem(.supplyCoupon)
                            }
                            StoreActionButton(title: "Günlük Bonus", state: supportState(.dailyBonus), note: "Küçük nakit ve +1 itibar", systemImage: "sparkles") {
                                game.buyStoreItem(.dailyBonus)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 24)
                .frame(maxWidth: 820)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func supportState(_ item: StoreItemID) -> StoreSupportState {
        if item == .supplyCoupon, game.supplyCouponCredit > 0 {
            return .active("Aktif", "\(game.supplyCouponCredit) TL kupon kaldı")
        }

        if game.usedStoreConsumablesToday.contains(item) {
            return .completed("Tamam", "Yarın tekrar açılır")
        }

        if item == .starterStock, !game.canReceiveStarterStock {
            return .blocked("Yer yok", "Tezgâh kapasitesi dolu")
        }

        let cost = game.storeItemCost(item)
        if game.cash < cost {
            return .blocked("Kasa yetmez", "\(cost) TL gerekiyor")
        }

        return .available("\(cost) TL", "Bugün 1 kez")
    }
}

private enum StoreSupportState {
    case available(String, String)
    case active(String, String)
    case completed(String, String)
    case blocked(String, String)

    var title: String {
        switch self {
        case .available(let title, _), .active(let title, _), .completed(let title, _), .blocked(let title, _):
            title
        }
    }

    var detail: String {
        switch self {
        case .available(_, let detail), .active(_, let detail), .completed(_, let detail), .blocked(_, let detail):
            detail
        }
    }

    var isEnabled: Bool {
        if case .available = self { return true }
        return false
    }

    var isCompleted: Bool {
        if case .completed = self { return true }
        return false
    }

    var tint: Color {
        switch self {
        case .available: .simitAmber
        case .active: .simitTeal
        case .completed: .simitSuccess
        case .blocked: .simitDanger
        }
    }

    var foreground: Color {
        switch self {
        case .available: .black.opacity(0.82)
        case .active, .completed, .blocked: .simitCream
        }
    }
}

private struct StoreThemeCard: View {
    let theme: GameTheme
    @ObservedObject var game: GameSession

    private var isActive: Bool {
        game.activeTheme == theme
    }

    private var isUnlocked: Bool {
        game.isThemeUnlocked(theme)
    }

    var body: some View {
        Button(action: handleTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(iconTint.opacity(isUnlocked ? 0.22 : 0.10))
                    Circle()
                        .stroke(iconTint.opacity(isUnlocked ? 0.42 : 0.18), lineWidth: 1)
                    Image(systemName: theme.systemImage)
                        .font(.title3.weight(.black))
                        .foregroundStyle(isUnlocked ? iconTint : Color.simitCream.opacity(0.40))
                }
                .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 7) {
                        Text(theme.title)
                            .font(.headline.weight(.black))
                            .foregroundStyle(Color.simitCream)
                            .lineLimit(1)
                            .minimumScaleFactor(0.76)

                        if !isUnlocked {
                            Image(systemName: "lock.fill")
                                .font(.caption.weight(.black))
                                .foregroundStyle(Color.simitAmber.opacity(0.86))
                        }
                    }

                    Text(theme.storeSubtitle)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.56))
                        .lineLimit(1)
                        .minimumScaleFactor(0.74)
                }

                Spacer(minLength: 8)

                Text(statusText)
                    .font(.caption.weight(.black))
                    .foregroundStyle(statusForeground)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 8)
                    .background(statusBackground, in: Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.10), lineWidth: 1))
            }
            .padding(12)
            .background(
                LinearGradient(
                    colors: isActive
                        ? [Color.simitAmber.opacity(0.30), Color.simitStand.opacity(0.52)]
                        : [Color.black.opacity(0.20), Color.simitStand.opacity(0.26)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isActive ? Color.simitAmber.opacity(0.48) : Color.simitCream.opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var iconTint: Color {
        switch theme {
        case .morning: .simitAmber
        case .evening: .orange
        case .rainy: .simitTeal
        }
    }

    private var statusText: String {
        if isActive { return "Aktif" }
        if isUnlocked { return "Seç" }
        return "\(theme.unlockPrice.formatted(.number.grouping(.automatic))) TL"
    }

    private var statusForeground: Color {
        isActive || isUnlocked ? .black.opacity(0.82) : .simitCream
    }

    private var statusBackground: Color {
        isActive || isUnlocked ? .simitAmber : .black.opacity(0.22)
    }

    private func handleTap() {
        if isUnlocked {
            game.selectTheme(theme)
        } else {
            game.unlockTheme(theme)
        }
    }
}

private struct StoreSection<Content: View>: View {
    let title: String
    let systemImage: String
    let content: Content

    init(title: String, systemImage: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }

    var body: some View {
        StandPanel {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: title, systemImage: systemImage)
                content
            }
        }
    }
}

private struct StoreGrid<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            content
        }
    }
}

private struct StoreActionButton: View {
    let title: String
    let state: StoreSupportState
    var note: String = ""
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 9) {
                HStack(spacing: 9) {
                    Image(systemName: systemImage)
                        .font(.headline.weight(.black))
                        .foregroundStyle(state.foreground)
                        .frame(width: 36, height: 36)
                        .background(state.tint.opacity(state.isEnabled ? 1 : 0.22), in: Circle())
                        .overlay(
                            Circle()
                                .stroke(state.tint.opacity(0.62), lineWidth: 1)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.caption.weight(.black))
                            .foregroundStyle(Color.simitCream)
                            .lineLimit(1)
                            .minimumScaleFactor(0.70)

                        if !note.isEmpty {
                            Text(note)
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(Color.simitCream.opacity(0.48))
                                .lineLimit(1)
                                .minimumScaleFactor(0.70)
                        }
                    }
                }

                HStack(spacing: 7) {
                    if state.isCompleted {
                        Text(state.title)
                            .font(.caption2.weight(.black))
                            .foregroundStyle(Color.simitSuccess)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 6)
                            .background(Color.simitSuccess.opacity(0.16), in: Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color.simitSuccess.opacity(0.36), lineWidth: 1)
                            )
                    } else {
                        Text(state.title)
                            .font(.caption2.weight(.black))
                            .foregroundStyle(state.foreground)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 6)
                            .background(state.tint.opacity(state.isEnabled ? 1 : 0.20), in: Capsule())
                    }
                    Text(state.detail)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.simitCream.opacity(0.62))
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 114)
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(
                LinearGradient(
                    colors: [
                        state.tint.opacity(state.isCompleted ? 0.18 : (state.isEnabled ? 0.20 : 0.12)),
                        Color.simitSuccess.opacity(state.isCompleted ? 0.10 : 0),
                        Color.black.opacity(state.isCompleted ? 0.16 : (state.isEnabled ? 0.20 : 0.30)),
                        Color.simitStand.opacity(state.isCompleted ? 0.16 : 0.28)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(state.tint.opacity(state.isCompleted ? 0.58 : (state.isEnabled ? 0.52 : 0.34)), lineWidth: state.isEnabled || state.isCompleted ? 1.3 : 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!state.isEnabled)
        .opacity(state.isEnabled || state.isCompleted ? 1 : 0.78)
    }
}
