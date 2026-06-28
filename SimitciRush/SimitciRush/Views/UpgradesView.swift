import SwiftUI

struct UpgradesView: View {
    @ObservedObject var game: GameSession

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ScreenTitle(
                    title: "Geliştirmeler",
                    subtitle: "Tezgâhı büyüt, stok kapasitesini aç, servise daha rahat gir."
                )
                .padding(.top, 18)

                CartStatusCard(game: game)

                VStack(spacing: 12) {
                    ForEach(game.upgrades) { upgrade in
                        UpgradeRow(upgrade: upgrade, game: game)
                    }
                }

                Spacer(minLength: 18)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
}

private struct CartStatusCard: View {
    @ObservedObject var game: GameSession

    var body: some View {
        StandPanel {
            VStack(alignment: .leading, spacing: 13) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(game.cartLevelName)
                            .font(.title3.weight(.black))
                            .foregroundStyle(.white)
                        Text("\(game.purchasedUpgrades.count)/\(game.upgrades.count) geliştirme açıldı")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white.opacity(0.56))
                    }

                    Spacer()

                    Label("\(game.cash) TL", systemImage: "banknote.fill")
                        .font(.caption.weight(.black))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color.black.opacity(0.20), in: Capsule())
                }

                HStack(spacing: 10) {
                    CapacityChip(product: .simit, game: game)
                    CapacityChip(product: .tea, game: game)
                    CapacityChip(product: .bag, game: game)
                }

                HStack(spacing: 10) {
                    UnlockChip(product: .cheese, game: game)
                    UnlockChip(product: .olivePaste, game: game)
                }

                HStack(spacing: 10) {
                    UnlockChip(product: .chocolate, game: game)
                }
            }
        }
    }
}

private struct CapacityChip: View {
    let product: ProductID
    @ObservedObject var game: GameSession

    var body: some View {
        let definition = Products.definition(for: product)

        VStack(spacing: 5) {
            ProductMark(product: definition, size: 32)
            Text("\(game.stockCapacity(for: product))")
                .font(.headline.weight(.black))
                .foregroundStyle(.white)
            Text(definition.name)
                .font(.caption2.weight(.black))
                .foregroundStyle(.white.opacity(0.48))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct UnlockChip: View {
    let product: ProductID
    @ObservedObject var game: GameSession

    var body: some View {
        let definition = Products.definition(for: product)
        let isUnlocked = game.isProductUnlocked(product)

        HStack(spacing: 8) {
            ProductMark(product: definition, size: 30)
                .opacity(isUnlocked ? 1 : 0.35)

            VStack(alignment: .leading, spacing: 2) {
                Text(definition.name)
                    .font(.caption.weight(.black))
                    .foregroundStyle(isUnlocked ? .white : .white.opacity(0.48))
                Text(isUnlocked ? "Açık" : "Lv \(definition.unlockLevel)'de açılır")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(isUnlocked ? Color.simitSuccess : Color.simitAmber)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(Color.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct UpgradeRow: View {
    let upgrade: UpgradeDefinition
    @ObservedObject var game: GameSession

    private var isBought: Bool {
        game.hasUpgrade(upgrade.id)
    }

    private var canBuy: Bool {
        !isBought && game.cash >= upgrade.cost
    }

    var body: some View {
        GameCard {
            HStack(spacing: 12) {
                Image(systemName: upgrade.systemImage)
                    .font(.title2.weight(.black))
                    .foregroundStyle(isBought ? Color.simitSuccess : Color.simitAmber)
                    .frame(width: 48, height: 48)
                    .background((isBought ? Color.simitSuccess : Color.simitAmber).opacity(0.14), in: RoundedRectangle(cornerRadius: 13))

                VStack(alignment: .leading, spacing: 5) {
                    Text(upgrade.name)
                        .font(.headline.weight(.black))
                        .foregroundStyle(.white)
                    Text(upgrade.detail)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.56))
                }

                Spacer(minLength: 8)

                Button {
                    game.buyUpgrade(upgrade)
                } label: {
                    Text(isBought ? "Açıldı" : "\(upgrade.cost) TL")
                        .font(.caption.weight(.black))
                        .frame(width: 74)
                        .padding(.vertical, 10)
                        .background(buttonColor, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                        .foregroundStyle(buttonTextColor)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var buttonColor: Color {
        if isBought { return Color.simitSuccess.opacity(0.18) }
        return canBuy ? Color.simitAmber : Color.white.opacity(0.08)
    }

    private var buttonTextColor: Color {
        if isBought { return Color.simitSuccess }
        return canBuy ? .black.opacity(0.82) : .white.opacity(0.30)
    }
}
