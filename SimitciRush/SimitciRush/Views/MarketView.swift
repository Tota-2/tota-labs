import SwiftUI

struct MarketView: View {
    @ObservedObject var game: GameSession
    @State private var category: MarketCategory = .supplies
    @State private var supplyCategory: SupplyCategory = .core
    @State private var storageCategory: StorageCategory = .core
    @State private var upgradeCategory: UpgradeCategory = .storage
    @AppStorage("simitci-first-day-market-tip-dismissed") private var isFirstDayMarketTipDismissed = false
    @AppStorage("simitci-rush-notes-enabled") private var notesEnabled = true

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 16) {
                    ScreenTitle(
                        title: "Market",
                        subtitle: "Tedarik, depo, geliştirme ve masrafları tek yerden yönet."
                    )
                    .padding(.top, 18)

                    MarketCategoryTabs(selection: $category)

                    GameCard {
                        HStack(spacing: 10) {
                            MetricTile(title: "Kasa", value: "\(game.cash) TL", systemImage: "banknote.fill")
                            MetricTile(title: "Masraf", value: "\(game.dailyFixedCost + game.dailyStorageCost) TL", systemImage: "receipt.fill", tint: .simitTeal)
                        }
                    }

                    switch category {
                    case .supplies:
                        if showsFirstDayTip {
                            FirstSupplyCoachCard(game: game) {
                                isFirstDayMarketTipDismissed = true
                            }
                        }

                        StandPanel {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(title: "Tedarik", systemImage: "cart.fill")
                                Text(game.isStorageUnlocked ? "Aldığın ürünler önce depoya gider. Serviste kullanmak için Hazırlık ekranında tezgâha çıkar." : "Depo Lv \(GameProgression.storageUnlockLevel)'te açılana kadar aldığın ürünler direkt tezgâha eklenir.")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white.opacity(0.56))
                                SupplyCategoryTabs(selection: $supplyCategory)

                                AdaptiveMarketGrid {
                                    ForEach(Products.all.filter { supplyCategory.contains($0.id) }) { product in
                                        MarketProductRow(product: product, game: game)
                                    }
                                }
                            }
                        }

                    case .storage:
                        if game.isStorageUnlocked {
                            StoragePanel(game: game, category: $storageCategory)
                        } else {
                            LockedStoragePanel()
                        }

                    case .upgrades:
                        StandPanel {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(title: "Geliştirmeler", systemImage: "wrench.and.screwdriver.fill")
                                UpgradeCategoryTabs(selection: $upgradeCategory)

                                if upgradeCategory == .business {
                                    VStack(spacing: 10) {
                                        ForEach(BusinessStage.allCases) { stage in
                                            BusinessStageRow(stage: stage, game: game)
                                        }
                                    }
                                } else {
                                    AdaptiveMarketGrid {
                                        ForEach(game.upgrades.filter { upgradeCategory.contains($0.id) }.sorted { $0.requiredLevel < $1.requiredLevel }) { upgrade in
                                            MarketUpgradeRow(upgrade: upgrade, game: game)
                                        }
                                    }
                                }
                            }
                        }

                    case .expenses:
                        ExpensesPanel(game: game)
                    }

                    if category == .supplies {
                        MinimalStandButton(title: "Tezgâh Aç", systemImage: "cart.fill.badge.plus") {
                            game.openPrep()
                        }
                        .frame(maxWidth: 520)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 2)
                    }

                    Spacer(minLength: 18)
                }
                .frame(maxWidth: proxy.size.width > 700 ? 1080 : .infinity)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, proxy.size.width > 700 ? 54 : 20)
                .padding(.top, proxy.size.width > 700 ? 38 : 20)
            }
        }
    }

    private var showsFirstDayTip: Bool {
        notesEnabled && category == .supplies && game.currentDay == 1 && !game.hasPlayedRushToday && !isFirstDayMarketTipDismissed
    }
}

private struct FirstSupplyCoachCard: View {
    @ObservedObject var game: GameSession
    let dismiss: () -> Void

    private var hasStarterStock: Bool {
        game.stock.quantity(for: .simit) >= 10
            && game.stock.quantity(for: .tea) >= 8
            && game.stock.quantity(for: .bag) >= 10
    }

    private var canBuyStarterPack: Bool {
        game.cash >= starterPackCost
    }

    private var starterPackCost: Int {
        (10 * game.buyCost(for: .simit)) + (8 * game.buyCost(for: .tea)) + (10 * game.buyCost(for: .bag))
    }

    var body: some View {
        CoachPanel {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    HStack(spacing: -8) {
                        ProductMark(product: Products.definition(for: .simit), size: 42)
                        ProductMark(product: Products.definition(for: .tea), size: 42)
                        ProductMark(product: Products.definition(for: .bag), size: 42)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(hasStarterStock ? "2. Tezgâhı aç" : "1. Başlangıç paketi")
                            .font(.headline.weight(.black))
                            .foregroundStyle(Color.simitCream)
                        Text(hasStarterStock ? "Simit, çay ve poşet tamam. Şimdi hazırlık ekranında fiyatı kontrol et." : "İlk servis için simit, çay ve poşet al. Böylece ilk kuyruk daha rahat döner.")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white.opacity(0.58))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                HStack(spacing: 10) {
                    if hasStarterStock {
                        Button {
                            dismiss()
                            game.openPrep()
                        } label: {
                            Label("Hazırlığa Geç", systemImage: "arrow.right.circle.fill")
                                .font(.subheadline.weight(.black))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(Color.simitAmber, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .foregroundStyle(.black.opacity(0.82))
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button {
                            game.buyStock(.simit, amount: 10)
                            game.buyStock(.tea, amount: 8)
                            game.buyStock(.bag, amount: 10)
                        } label: {
                            Label("Paketi Al · \(starterPackCost) TL", systemImage: "cart.fill.badge.plus")
                                .font(.subheadline.weight(.black))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(canBuyStarterPack ? Color.simitAmber : Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .foregroundStyle(canBuyStarterPack ? .black.opacity(0.82) : .white.opacity(0.36))
                        }
                        .buttonStyle(.plain)
                        .disabled(!canBuyStarterPack)
                    }

                    Button("Anladım") {
                        dismiss()
                    }
                    .font(.subheadline.weight(.black))
                    .frame(width: 104)
                    .padding(.vertical, 13)
                    .background(Color.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .foregroundStyle(Color.simitCream.opacity(0.72))
                }
            }
        }
    }
}

private struct AdaptiveMarketGrid<Content: View>: View {
    let content: Content

    private let columns = [
        GridItem(.adaptive(minimum: 300, maximum: 430), spacing: 10, alignment: .top)
    ]

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            content
        }
    }
}

private struct MinimalStandButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.black))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .foregroundStyle(.black.opacity(0.82))
                .background(Color.simitAmber, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.simitCream.opacity(0.30), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

private enum SupplyCategory: String, CaseIterable, Identifiable {
    case core = "Ana"
    case drinks = "İçecek"
    case addOns = "Ek"
    case packing = "Paket"

    var id: String { rawValue }

    func contains(_ product: ProductID) -> Bool {
        switch self {
        case .core: [.simit, .acma, .oliveAcma, .cheesePogaca].contains(product)
        case .drinks: [.tea, .water, .ayran, .juiceBox].contains(product)
        case .addOns: product.isAddOn
        case .packing: product == .bag
        }
    }
}

private enum UpgradeCategory: String, CaseIterable, Identifiable {
    case business = "İşletme"
    case storage = "Depo"
    case service = "Servis"
    case economy = "Ekonomi"
    case prestige = "Prestij"

    var id: String { rawValue }

    func contains(_ upgrade: UpgradeID) -> Bool {
        switch self {
        case .business:
            false
        case .storage:
            [.basket, .thermos, .packingShelf, .waterCrate, .coldCase, .toppingShelf].contains(upgrade)
        case .service:
            [.awning, .tipJar].contains(upgrade)
        case .economy:
            [.supplierDeal].contains(upgrade)
        case .prestige:
            [.brandSign, .masterStaff, .cityCampaign].contains(upgrade)
        }
    }
}

private enum StorageCategory: String, CaseIterable, Identifiable {
    case core = "Ana"
    case drinks = "İçecek"
    case addOns = "Ek"
    case packing = "Paket"

    var id: String { rawValue }

    func contains(_ product: ProductID) -> Bool {
        switch self {
        case .core:
            [.simit, .acma, .oliveAcma, .cheesePogaca].contains(product)
        case .drinks:
            [.tea, .water, .ayran, .juiceBox].contains(product)
        case .addOns:
            product.isAddOn
        case .packing:
            product == .bag
        }
    }
}

private struct SupplyCategoryTabs: View {
    @Binding var selection: SupplyCategory

    var body: some View {
        CategoryPills(items: SupplyCategory.allCases, selection: $selection)
    }
}

private struct StorageCategoryTabs: View {
    @Binding var selection: StorageCategory

    var body: some View {
        CategoryPills(items: StorageCategory.allCases, selection: $selection)
    }
}

private struct UpgradeCategoryTabs: View {
    @Binding var selection: UpgradeCategory

    var body: some View {
        CategoryPills(items: UpgradeCategory.allCases, selection: $selection)
    }
}

private struct CategoryPills<Item: Identifiable & RawRepresentable & Equatable>: View where Item.RawValue == String {
    let items: [Item]
    @Binding var selection: Item

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(items) { item in
                Button {
                    selection = item
                } label: {
                    Text(item.rawValue.uppercased())
                        .font(.system(size: isPad ? 13 : 10, weight: .black))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, isPad ? 12 : 8)
                        .background(selection == item ? Color.simitCream : Color.black.opacity(0.16), in: Capsule())
                        .foregroundStyle(selection == item ? .black.opacity(0.82) : Color.simitCream.opacity(0.68))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private enum MarketCategory: String, CaseIterable, Identifiable {
    case supplies = "Tedarik"
    case storage = "Depo"
    case upgrades = "Geliştir"
    case expenses = "Masraf"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .supplies: "cart.fill"
        case .storage: "shippingbox.fill"
        case .upgrades: "wrench.and.screwdriver.fill"
        case .expenses: "receipt.fill"
        }
    }
}

private struct MarketCategoryTabs: View {
    @Binding var selection: MarketCategory

    var body: some View {
        HStack(spacing: 6) {
            ForEach(MarketCategory.allCases) { category in
                Button {
                    selection = category
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: category.systemImage)
                            .font(.headline.weight(.black))
                        Text(category.rawValue.uppercased())
                            .font(.system(size: 10, weight: .black))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .foregroundStyle(selection == category ? .black.opacity(0.84) : Color.simitCream.opacity(0.68))
                    .background(selection == category ? Color.simitAmber : Color.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(5)
        .background(.black.opacity(0.26), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.simitCream.opacity(0.12), lineWidth: 1)
        )
    }
}

private struct LockedStoragePanel: View {
    var body: some View {
        StandPanel {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Depo", systemImage: "lock.fill")

                HStack(spacing: 12) {
                    Image(systemName: "shippingbox.fill")
                        .font(.title2.weight(.black))
                        .foregroundStyle(Color.simitAmber)
                        .frame(width: 48, height: 48)
                        .background(Color.simitAmber.opacity(0.16), in: Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Depo Lv \(GameProgression.storageUnlockLevel)'te açılır")
                            .font(.headline.weight(.black))
                            .foregroundStyle(.white)
                        Text("Önce tezgâhı ayakta tut, sonra fazla stoğu depoda yönet.")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white.opacity(0.56))
                    }
                }
            }
        }
    }
}

private struct BusinessStageRow: View {
    let stage: BusinessStage
    @ObservedObject var game: GameSession

    private var isCurrent: Bool {
        game.businessStage == stage
    }

    private var isPast: Bool {
        game.businessStage.requiredLevel > stage.requiredLevel
    }

    private var canBuy: Bool {
        game.canBuyBusinessStage(stage)
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.18))
                Circle()
                    .stroke(tint.opacity(0.38), lineWidth: 1)
                Image(systemName: stage == .shop || stage == .istanbulSimitci ? "storefront.fill" : "cart.fill")
                    .font(.headline.weight(.black))
                    .foregroundStyle(tint)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(stage.title)
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(.white)
                Text(stage.detail)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.54))
                if stage != .smallCart {
                    Text("Lv \(stage.requiredLevel) · Günlük kira x\(stage.rentMultiplier.formatted(.number.precision(.fractionLength(2))))")
                        .font(.caption2.weight(.black))
                        .foregroundStyle(Color.simitAmber.opacity(0.78))
                }
            }

            Spacer(minLength: 8)

            Button {
                game.buyBusinessStage(stage)
            } label: {
                Text(buttonTitle)
                    .font(.caption.weight(.black))
                    .frame(width: 76)
                    .padding(.vertical, 10)
                    .background(buttonColor, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                    .foregroundStyle(buttonTextColor)
            }
            .buttonStyle(.plain)
        }
        .padding(11)
        .background(Color.black.opacity(isCurrent ? 0.24 : 0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isCurrent ? Color.simitAmber.opacity(0.42) : Color.white.opacity(0.05), lineWidth: 1)
        )
    }

    private var tint: Color {
        isCurrent ? .simitAmber : isPast ? .simitSuccess : .simitCream
    }

    private var buttonTitle: String {
        if isCurrent { return "Mevcut" }
        if isPast { return "Alındı" }
        if game.level < stage.requiredLevel { return "Lv \(stage.requiredLevel)" }
        return "\(stage.cost) TL"
    }

    private var buttonColor: Color {
        canBuy ? .simitAmber : Color.white.opacity(0.08)
    }

    private var buttonTextColor: Color {
        canBuy ? .black.opacity(0.82) : .white.opacity(0.34)
    }
}

private struct StoragePanel: View {
    @ObservedObject var game: GameSession
    @Binding var category: StorageCategory

    private var stockValue: Int {
        Products.all.reduce(0) { total, product in
            total + game.storageStock.quantity(for: product.id) * game.buyCost(for: product.id)
        }
    }

    private var visibleProducts: [ProductDefinition] {
        Products.all.filter { category.contains($0.id) }
    }

    var body: some View {
        StandPanel {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Depo", systemImage: "shippingbox.fill")
                StorageCategoryTabs(selection: $category)

                HStack(spacing: 10) {
                    MetricTile(title: "Depo Değeri", value: "\(stockValue) TL", systemImage: "shippingbox.fill")
                    MetricTile(title: "Bakım", value: "\(game.dailyStorageCost) TL", systemImage: "wrench.adjustable.fill", tint: .simitTeal)
                }

                AdaptiveMarketGrid {
                    ForEach(visibleProducts) { product in
                        StorageRow(product: product, game: game)
                    }
                }
            }
        }
    }
}

private struct StorageRow: View {
    let product: ProductDefinition
    @ObservedObject var game: GameSession

    private var current: Int {
        game.storageStock.quantity(for: product.id)
    }

    private var capacity: Int {
        game.storageCapacity(for: product.id)
    }

    private var isUnlocked: Bool {
        game.isProductUnlocked(product.id)
    }

    var body: some View {
        HStack(spacing: 10) {
            ProductMark(product: product, size: 34)
                .opacity(isUnlocked ? 1 : 0.35)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(product.name)
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(isUnlocked ? .white : .white.opacity(0.42))
                    Spacer()
                    Text(isUnlocked ? "\(current)/\(capacity)" : "Lv \(product.unlockLevel)")
                        .font(.caption.weight(.black))
                        .foregroundStyle(isUnlocked ? Color.simitCream : Color.simitAmber)
                }

                ProgressView(value: Double(current), total: Double(max(1, capacity)))
                    .tint(Color.simitAmber)
                    .opacity(isUnlocked ? 1 : 0.25)
            }
        }
        .padding(10)
        .background(Color.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct MarketProductRow: View {
    let product: ProductDefinition
    @ObservedObject var game: GameSession

    private var current: Int {
        game.isStorageUnlocked ? game.storageStock.quantity(for: product.id) : game.stock.quantity(for: product.id)
    }

    private var capacity: Int {
        game.isStorageUnlocked ? game.storageCapacity(for: product.id) : game.stockCapacity(for: product.id)
    }

    private func canBuy(amount: Int) -> Bool {
        guard game.isProductUnlocked(product.id), current < capacity else { return false }
        let quantity = min(amount, capacity - current)
        guard quantity > 0 else { return false }
        let cost = quantity * game.buyCost(for: product.id)
        let payableCost = cost - min(game.supplyCouponCredit, cost)
        return game.cash >= payableCost
    }

    private var isUnlocked: Bool {
        game.isProductUnlocked(product.id)
    }

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

	var body: some View {
	    HStack(spacing: isPad ? 15 : 10) {
	        ProductMark(product: product, size: isPad ? 58 : 42)
	            .opacity(isUnlocked ? 1 : 0.35)

	        VStack(alignment: .leading, spacing: 4) {
	            HStack {
	                Text(product.name)
	                    .font((isPad ? Font.headline : Font.subheadline).weight(.black))
	                    .foregroundStyle(isUnlocked ? .white : .white.opacity(0.42))
	                Spacer()
	                Text(isUnlocked ? stockBadge : "Lv \(product.unlockLevel)")
	                    .font((isPad ? Font.subheadline : Font.caption).weight(.black))
	                    .foregroundStyle(current >= capacity ? Color.simitAmber : .white.opacity(0.62))
	            }

	            Text(isUnlocked ? priceText : "Seviye \(product.unlockLevel)'de markete gelir")
	                .font((isPad ? Font.caption : Font.caption2).weight(.bold))
	                .foregroundStyle(.white.opacity(0.48))

	            if isUnlocked {
	                HStack(spacing: 7) {
	                    Label(stockLine, systemImage: game.isStorageUnlocked ? "shippingbox.fill" : "cart.fill")
	                        .foregroundStyle(current >= capacity ? Color.simitAmber : Color.simitCream.opacity(0.72))
	                }
	                .font((isPad ? Font.caption : Font.caption2).weight(.black))
	            }
	        }

	        VStack(spacing: isPad ? 9 : 6) {
	            MarketBuyButton(title: "+1", enabled: canBuy(amount: 1), icon: "plus") {
	                game.buyStock(product.id, amount: 1)
	            }

	            MarketBuyButton(title: "+5", enabled: canBuy(amount: 5), icon: "shippingbox.fill") {
	                game.buyStock(product.id, amount: 5)
	            }
	        }
        }
	    .padding(isPad ? 16 : 10)
	    .background(Color.black.opacity(isUnlocked ? 0.16 : 0.24), in: RoundedRectangle(cornerRadius: isPad ? 19 : 14, style: .continuous))
    }

	private var priceText: String {
	    let priceLabel = product.id.isAddOn ? "Ek fiyat" : "Satış"
	    let target = game.isStorageUnlocked ? "Depoya alış" : "Tezgâha alış"
	    return "\(target) \(game.buyCost(for: product.id)) TL / \(priceLabel) \(game.price(for: product.id)) TL"
	}

	private var stockBadge: String {
	    current >= capacity ? "Dolu" : "\(capacity - current) yer"
	}

	private var stockLine: String {
	    game.isStorageUnlocked ? "Depo \(current)/\(capacity)" : "Tezgâh \(current)/\(capacity)"
	}
}

private struct MarketUpgradeRow: View {
    let upgrade: UpgradeDefinition
    @ObservedObject var game: GameSession

    private var isBought: Bool {
        game.hasUpgrade(upgrade.id)
    }

    private var canBuy: Bool {
        game.canBuyUpgrade(upgrade)
    }

    private var isLevelLocked: Bool {
        game.level < upgrade.requiredLevel
    }

    private var isBusinessLocked: Bool {
        !game.hasRequiredBusinessStage(for: upgrade)
    }

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        HStack(spacing: isPad ? 16 : 12) {
            UpgradeMark(upgrade: upgrade, isBought: isBought)

            VStack(alignment: .leading, spacing: 4) {
                Text(upgrade.name)
                    .font((isPad ? Font.headline : Font.subheadline).weight(.black))
                    .foregroundStyle(.white)
                Text(upgrade.detail)
                    .font((isPad ? Font.caption : Font.caption2).weight(.bold))
                    .foregroundStyle(.white.opacity(0.54))
                    .lineLimit(2)
                if isLevelLocked {
                    Text("Lv \(upgrade.requiredLevel)'de açılır")
                        .font((isPad ? Font.caption : Font.caption2).weight(.black))
                        .foregroundStyle(Color.simitAmber)
                } else if isBusinessLocked, let required = game.requiredBusinessStage(for: upgrade) {
                    Text("\(required.title) gerekli")
                        .font(.caption2.weight(.black))
                        .foregroundStyle(Color.simitAmber)
                }
            }

            Spacer(minLength: 8)

            Button {
                game.buyUpgrade(upgrade)
            } label: {
                Text(buttonTitle)
                    .font((isPad ? Font.subheadline : Font.caption).weight(.black))
                    .frame(width: isPad ? 104 : 72)
                    .padding(.vertical, isPad ? 14 : 10)
                    .background(buttonColor, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                    .foregroundStyle(buttonTextColor)
            }
            .buttonStyle(.plain)
        }
        .padding(isPad ? 16 : 10)
        .background(Color.black.opacity(0.16), in: RoundedRectangle(cornerRadius: isPad ? 19 : 14, style: .continuous))
    }

    private var buttonColor: Color {
        if isBought { return Color.simitSuccess.opacity(0.18) }
        return canBuy ? Color.simitAmber : Color.white.opacity(0.08)
    }

    private var buttonTextColor: Color {
        if isBought { return Color.simitSuccess }
        return canBuy ? .black.opacity(0.82) : .white.opacity(0.30)
    }

    private var buttonTitle: String {
        if isBought { return "Açık" }
        if isLevelLocked { return "Lv \(upgrade.requiredLevel)" }
        if isBusinessLocked { return "Kilitli" }
        return "\(upgrade.cost) TL"
    }
}

private struct UpgradeMark: View {
    let upgrade: UpgradeDefinition
    let isBought: Bool

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(tint.opacity(isBought ? 0.22 : 0.16))
            Circle()
                .stroke(tint.opacity(0.34), lineWidth: 1)
            Image(systemName: upgrade.systemImage)
                .font((isPad ? Font.title2 : Font.title3).weight(.black))
                .foregroundStyle(tint)

            if upgrade.id == .supplierDeal {
                Image(systemName: "pencil.tip")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(Color.simitCream)
                    .offset(x: 12, y: 12)
            }
        }
        .frame(width: isPad ? 58 : 42, height: isPad ? 58 : 42)
    }

    private var tint: Color {
        isBought ? Color.simitSuccess : Color.simitAmber
    }
}

private struct ExpensesPanel: View {
    @ObservedObject var game: GameSession

    private var rentIncreaseText: String {
        guard game.currentDay <= 360 else { return "Tavan" }
        return "\(30 - ((game.currentDay - 1) % 30)) gün"
    }

    var body: some View {
        StandPanel {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Günlük Masraflar", systemImage: "receipt.fill")

                HStack(spacing: 10) {
                    ExpenseSummaryTile(title: "Bugün", value: "\(game.dailyFixedCost + game.dailyStorageCost + game.dailyLoanPayment) TL", systemImage: "receipt.fill", tint: .simitAmber)
                    ExpenseSummaryTile(title: "Zam", value: rentIncreaseText, systemImage: "chart.line.uptrend.xyaxis", tint: .simitTeal)
                }

                AdaptiveMarketGrid {
                    ExpenseRow(title: game.dailyPrestigeCost > 0 ? "Yer + Prestij" : "Yer Kirası", value: "\(game.dailyFixedCost) TL", detail: rentExpenseDetail, systemImage: "mappin.and.ellipse")
                    ExpenseRow(title: "Depo Bakımı", value: game.dailyStorageCost > 0 ? "\(game.dailyStorageCost) TL" : "Yok", detail: storageExpenseDetail, systemImage: "wrench.adjustable.fill")
                    ExpenseRow(title: "Kredi Ödeme", value: game.debt > 0 ? "\(game.dailyLoanPayment) TL/gün" : "Yok", detail: game.debt > 0 ? "Kalan borç \(game.debt) TL." : "Esnaf sekmesinden kredi alınır.", systemImage: "creditcard.fill")
                    ExpenseRow(title: "Stok Maliyeti", value: "Tedarik", detail: "Ürün alırken kasadan düşen maliyet.", systemImage: "shippingbox.fill")
                    ExpenseRow(title: "Son Net", value: game.lastReport.map { "\($0.netProfit) TL" } ?? "Yok", detail: "Son servisin kâr/zarar sonucu.", systemImage: "banknote.fill")
                }
            }
        }
    }

    private var storageExpenseDetail: String {
        if !game.isStorageUnlocked {
            return "Depo Lv \(GameProgression.storageUnlockLevel)'te açılır."
        }
        return game.isStorageActivated
            ? "Depo kullanıldığı için günlük bakım masrafı yazar."
            : "İlk ürün depoya alındığında bakım masrafı başlar."
    }

    private var rentExpenseDetail: String {
        if game.dailyPrestigeCost > 0 {
            return "Kira ve \(game.dailyPrestigeCost) TL prestij bakım/reklam gideri."
        }
        return "Gün sonunda kesilir; 30 günde bir zamlanır."
    }
}

private struct TipRow: View {
    let title: String
    let detail: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.caption.weight(.black))
                .foregroundStyle(Color.simitTeal)
                .frame(width: 26, height: 26)
                .background(Color.simitTeal.opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white)
                Text(detail)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.52))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.black.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct ExpenseSummaryTile: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: systemImage)
                .font(.headline.weight(.black))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.16), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(.white.opacity(0.44))
                Text(value)
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct ExpenseRow: View {
    let title: String
    let value: String
    let detail: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.headline.weight(.black))
                .foregroundStyle(Color.simitTeal)
                .frame(width: 38, height: 38)
                .background(Color.simitTeal.opacity(0.16), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(.white)
                Text(detail)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.52))
            }

            Spacer()

            Text(value)
                .font(.caption.weight(.black))
                .foregroundStyle(Color.simitCream)
        }
        .padding(10)
        .background(Color.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct MarketBuyButton: View {
    let title: String
    let enabled: Bool
    let icon: String
    let action: () -> Void

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: isPad ? 13 : 10, weight: .black))
                Text(title)
                    .font((isPad ? Font.subheadline : Font.caption).weight(.black))
            }
            .frame(width: isPad ? 72 : 50, height: isPad ? 42 : 30)
            .background(enabled ? Color.simitAmber : Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: isPad ? 12 : 9, style: .continuous))
            .foregroundStyle(enabled ? .black.opacity(0.82) : .white.opacity(0.28))
        }
        .buttonStyle(.plain)
    }
}
