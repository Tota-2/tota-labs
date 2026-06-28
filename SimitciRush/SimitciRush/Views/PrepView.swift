import SwiftUI

struct PrepView: View {
    @ObservedObject var game: GameSession
    @State private var category: PrepProductCategory = .core
    @AppStorage("simitci-first-day-prep-tip-dismissed") private var isFirstDayPrepTipDismissed = false
    @AppStorage("simitci-rush-notes-enabled") private var notesEnabled = true

    private var visibleProducts: [ProductDefinition] {
        Products.all.filter { category.contains($0.id) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HeaderBar(title: "Hazırlık") {
                game.backHome()
            }

            ScrollView {
                VStack(spacing: 14) {
                    GameCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Bugünkü tezgâh", systemImage: "shippingbox.fill")

                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "tram.fill")
                                    .font(.title2)
                                    .foregroundStyle(Color.simitAmber)
                                    .frame(width: 42, height: 42)
                                    .background(Color.simitAmber.opacity(0.16), in: RoundedRectangle(cornerRadius: 11))

                                VStack(alignment: .leading, spacing: 5) {
                                    Text(game.districtName)
                                        .font(.title2.weight(.black))
                                        .foregroundStyle(.white)
                                    Text("Yer ücreti \(game.dailyFixedCost) TL. Satış fiyatlarını ayarla, sonra servisi başlat.")
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.64))
                                }
                            }
                        }
                    }

                    if showsFirstDayTip {
                        FirstPrepCoachCard(game: game) {
                            isFirstDayPrepTipDismissed = true
                        }
                    }

                    StandPanel {
                        VStack(alignment: .leading, spacing: 12) {
	                            SectionHeader(title: game.isStorageUnlocked ? "Depodan tezgâha" : "Stok ve fiyat", systemImage: "slider.horizontal.3")
	                            if game.isStorageUnlocked {
	                                Text("Serviste sadece tezgâhtaki ürünler satılır. Depodaki ürünleri buradan tezgâha çıkar.")
	                                    .font(.caption.weight(.bold))
	                                    .foregroundStyle(.white.opacity(0.56))
	                            }
	                            PrepProductCategoryTabs(selection: $category)

                            ForEach(visibleProducts) { product in
                                ProductPrepRow(
                                    product: product,
                                    stock: game.stock.quantity(for: product.id),
                                    storageStock: game.storageStock.quantity(for: product.id),
                                    price: game.price(for: product.id),
                                    buyCost: game.buyCost(for: product.id),
                                    isUnlocked: game.isProductUnlocked(product.id),
                                    isStorageUnlocked: game.isStorageUnlocked,
                                    canTransferIn: game.isStorageUnlocked && game.storageStock.quantity(for: product.id) > 0 && game.stock.quantity(for: product.id) < game.stockCapacity(for: product.id),
                                    canTransferOut: game.isStorageUnlocked && game.stock.quantity(for: product.id) > 0 && game.storageStock.quantity(for: product.id) < game.storageCapacity(for: product.id),
                                    transferIn: { game.transferFromStorageToStand(product.id, amount: 1) },
                                    transferInBulk: { game.transferFromStorageToStand(product.id, amount: 5) },
                                    transferOut: { game.transferFromStandToStorage(product.id, amount: 1) },
                                    decrease: { game.adjustPrice(for: product.id, by: -1) },
                                    increase: { game.adjustPrice(for: product.id, by: 1) }
                                )
                            }
                        }
                    }

                    GameCard {
                        HStack(spacing: 12) {
                            Image(systemName: "receipt.fill")
                                .font(.title3)
                                .foregroundStyle(Color.simitTeal)
                                .frame(width: 38, height: 38)
                                .background(Color.simitTeal.opacity(0.14), in: RoundedRectangle(cornerRadius: 10))

                            VStack(alignment: .leading, spacing: 3) {
                                Text("Gün sonu hesabı")
                                    .font(.headline.weight(.black))
                                Text("Cirodan satılan stok maliyeti ve yer ücreti düşülür. Zamlar mutluluğu biraz etkiler.")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.62))
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 18)
                .frame(maxWidth: 840)
                .frame(maxWidth: .infinity)
            }

            VStack(spacing: 10) {
                if game.hasPlayedRushToday {
                    CompletedRushButton {
                        game.openDayClose()
                    }
                } else {
                    PrimaryGameButton(title: startButtonTitle, systemImage: startButtonIcon, enabled: game.canStartRush(.main)) {
                        game.startRush()
                    }
                }
            }
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(.black.opacity(0.18))
        }
    }

    private var startButtonTitle: String {
        if game.canStartRush(.main) { return "Ana Servisi Başlat" }
        if !game.hasSimitOnStand { return "Önce Simit Tedarik Et" }
        return "Yarın Açılır"
    }

    private var startButtonIcon: String {
        if game.canStartRush(.main) { return "timer" }
        if !game.hasSimitOnStand { return "cart.fill" }
        return "lock.fill"
    }

    private var showsFirstDayTip: Bool {
        notesEnabled && game.currentDay == 1 && !game.hasPlayedRushToday && !isFirstDayPrepTipDismissed
    }
}

private struct FirstPrepCoachCard: View {
    @ObservedObject var game: GameSession
    let dismiss: () -> Void

    var body: some View {
        CoachPanel {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: game.canStartRush(.main) ? "timer" : "cart.fill")
                        .font(.title3.weight(.black))
                        .foregroundStyle(.black.opacity(0.82))
                        .frame(width: 44, height: 44)
                        .background(game.canStartRush(.main) ? Color.simitAmber : Color.simitDanger.opacity(0.82), in: Circle())

                    VStack(alignment: .leading, spacing: 3) {
                        Text(game.canStartRush(.main) ? "3. Servisi başlat" : "Simit eksik")
                            .font(.headline.weight(.black))
                            .foregroundStyle(Color.simitCream)
                        Text(game.canStartRush(.main) ? "Fiyatı kontrol ettin. İlk servis kısa; sipariş balonundaki ürünlere dokunarak hızlı seç." : "Ana servise başlamak için tezgahta en az 1 simit olmalı.")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white.opacity(0.58))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                HStack(spacing: 10) {
                    Button("Anladım") {
                        dismiss()
                    }
                    .font(.subheadline.weight(.black))
                    .frame(width: 104)
                    .padding(.vertical, 13)
                    .background(Color.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .foregroundStyle(Color.simitCream.opacity(0.72))

                    Button {
                        dismiss()
                        if game.canStartRush(.main) {
                            game.startRush()
                        } else {
                            game.openMarket()
                        }
                    } label: {
                        Label(game.canStartRush(.main) ? "Servisi Başlat" : "Markete Dön", systemImage: game.canStartRush(.main) ? "arrow.right.circle.fill" : "cart.fill")
                            .font(.subheadline.weight(.black))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(Color.simitAmber, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .foregroundStyle(.black.opacity(0.82))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct CompletedRushButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Kapanışı Gör", systemImage: "checkmark.seal.fill")
                .font(.headline.weight(.black))
                .frame(maxWidth: 260)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color.simitAmber, Color.simitCounter.opacity(0.96), Color.simitStand],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
                .foregroundStyle(.black.opacity(0.82))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.simitCream.opacity(0.28), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

private enum PrepProductCategory: String, CaseIterable, Identifiable {
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

private struct PrepProductCategoryTabs: View {
    @Binding var selection: PrepProductCategory

    var body: some View {
        HStack(spacing: 6) {
            ForEach(PrepProductCategory.allCases) { category in
                Button {
                    selection = category
                } label: {
                    Text(category.rawValue.uppercased())
                        .font(.system(size: 10, weight: .black))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(selection == category ? Color.simitCream : Color.black.opacity(0.16), in: Capsule())
                        .foregroundStyle(selection == category ? .black.opacity(0.82) : Color.simitCream.opacity(0.68))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct HeaderBar: View {
    let title: String
    let back: () -> Void

    var body: some View {
        HStack {
            GameBackButton(action: back)

            Spacer()

            Text(title)
                .font(.headline.weight(.black))
                .foregroundStyle(.white)

            Spacer()

            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }
}

private struct ProductPrepRow: View {
    let product: ProductDefinition
    let stock: Int
    let storageStock: Int
    let price: Int
    let buyCost: Int
    let isUnlocked: Bool
    let isStorageUnlocked: Bool
    let canTransferIn: Bool
    let canTransferOut: Bool
    let transferIn: () -> Void
    let transferInBulk: () -> Void
    let transferOut: () -> Void
    let decrease: () -> Void
    let increase: () -> Void

    var body: some View {
        VStack(spacing: 9) {
            HStack(spacing: 10) {
                ProductMark(product: product, size: 40)
                    .opacity(isUnlocked ? 1 : 0.35)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(product.name)
                            .font(.subheadline.weight(.black))
                            .foregroundStyle(isUnlocked ? .white : .white.opacity(0.42))

                        if !isUnlocked {
                            Label("Lv \(product.unlockLevel)", systemImage: "lock.fill")
                                .font(.caption2.weight(.black))
                                .foregroundStyle(Color.simitAmber)
                        }
                    }

                    Text(isUnlocked ? detailText : "Seviye \(product.unlockLevel)'de açılır")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white.opacity(0.52))
                }

                Spacer(minLength: 8)

                if isUnlocked {
                    PriceStepper(
                        price: price,
                        basePrice: product.sellPrice,
                        buyCost: buyCost,
                        maximumPrice: product.maximumSellPrice,
                        decrease: decrease,
                        increase: increase
                    )
                }
            }

            if isUnlocked && isStorageUnlocked {
                HStack(spacing: 7) {
                    PrepTransferButton(title: "+1", enabled: canTransferIn, action: transferIn)
                    PrepTransferButton(title: "+5", enabled: canTransferIn, action: transferInBulk)
                    Spacer(minLength: 6)
                    PrepTransferButton(title: "Geri", enabled: canTransferOut, action: transferOut)
                }
            }
        }
        .padding(10)
        .background(Color.black.opacity(isUnlocked ? 0.16 : 0.24), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var detailText: String {
        if isStorageUnlocked {
            return "Tezgâh \(stock) / Depo \(storageStock) / Alış \(buyCost) TL"
        }
        return product.id.isAddOn ? "Ek malzeme \(stock) / Alış \(buyCost) TL" : "Tezgâh \(stock) / Alış \(buyCost) TL"
    }
}

private struct PrepTransferButton: View {
    let title: String
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption2.weight(.black))
                .frame(width: title == "Geri" ? 54 : 42, height: 28)
                .background(enabled ? Color.simitCream : Color.white.opacity(0.08), in: Capsule())
                .foregroundStyle(enabled ? .black.opacity(0.82) : .white.opacity(0.26))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

private struct PriceStepper: View {
    let price: Int
    let basePrice: Int
    let buyCost: Int
    let maximumPrice: Int
    let decrease: () -> Void
    let increase: () -> Void

    var body: some View {
        HStack(spacing: 7) {
            Button(action: decrease) {
                Image(systemName: "minus.circle.fill")
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .disabled(price <= buyCost + 1)
            .foregroundStyle(price <= buyCost + 1 ? .white.opacity(0.22) : Color.simitCream)

            VStack(spacing: 1) {
                Text("\(price)")
                    .font(.headline.weight(.black))
                    .foregroundStyle(price > basePrice ? Color.simitAmber : .white)
                Text("TL")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.white.opacity(0.45))
            }
            .frame(width: 42)

            Button(action: increase) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .disabled(price >= maximumPrice)
            .foregroundStyle(price >= maximumPrice ? .white.opacity(0.22) : Color.simitCream)
        }
    }
}
