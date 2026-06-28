import Foundation

#if DEBUG
enum EconomySimulation {
    static func run(days: Int = 30) -> EconomySimulationSummary {
        EconomySimulationSummary(
            runs: PlayerProfile.allCases.map { profile in
                runEconomyProfile(profile, days: days)
            }
        )
    }
}

struct EconomySimulationSummary: Equatable {
    let runs: [EconomyRunResult]

    var markdownSummary: String {
        var lines: [String] = [
            "| Oyuncu | Gün | İşletme | Kasa | Borç | Level | XP | İtibar | İflas |",
            "|---|---:|---|---:|---:|---:|---:|---:|---|"
        ]

        for run in runs {
            lines.append("| \(run.profile.title) | \(run.finalDay) | \(run.businessStage.title) | \(run.cash) TL | \(run.debt) TL | \(run.level) | \(run.xp) | \(run.reputation) | \(run.bankruptcyDay.map { "Gün \($0)" } ?? "-") |")
        }

        return lines.joined(separator: "\n")
    }
}

private func runEconomyProfile(_ profile: PlayerProfile, days: Int) -> EconomyRunResult {
    var runner = EconomyRunner(profile: profile, days: days)
    return runner.run()
}

struct EconomyRunResult: Equatable {
    let profile: PlayerProfile
    let finalDay: Int
    let businessStage: BusinessStage
    let cash: Int
    let debt: Int
    let level: Int
    let xp: Int
    let reputation: Int
    let bankruptcyDay: Int?
    let days: [EconomyDayResult]
}

struct EconomyDayResult: Equatable {
    let day: Int
    let level: Int
    let cash: Int
    let debt: Int
    let reputation: Int
    let revenue: Int
    let supplyCost: Int
    let fixedCost: Int
    let storageCost: Int
    let spoilageCost: Int
    let loanPayment: Int
    let netProfit: Int
    let xpEarned: Int
    let served: Int
    let missed: Int
    let wrong: Int
}

enum PlayerProfile: CaseIterable {
    case struggling
    case average
    case skilled
    case aggressivePricing
    case overstocked

    var title: String {
        switch self {
        case .struggling: "Zorlanan"
        case .average: "Ortalama"
        case .skilled: "İyi"
        case .aggressivePricing: "Yüksek Fiyat"
        case .overstocked: "Fazla Stok"
        }
    }

    var servedBase: Int {
        switch self {
        case .struggling: 9
        case .average, .aggressivePricing, .overstocked: 14
        case .skilled: 19
        }
    }

    var missedBase: Int {
        switch self {
        case .struggling: 5
        case .average, .aggressivePricing, .overstocked: 2
        case .skilled: 1
        }
    }

    var wrongBase: Int {
        switch self {
        case .struggling: 3
        case .average, .aggressivePricing, .overstocked: 1
        case .skilled: 0
        }
    }

    var comboBase: Int {
        switch self {
        case .struggling: 2
        case .average, .aggressivePricing, .overstocked: 5
        case .skilled: 8
        }
    }

    var priceMarkup: Int {
        switch self {
        case .struggling: 0
        case .average, .overstocked: 2
        case .skilled: 4
        case .aggressivePricing: 12
        }
    }

    var stockBuffer: Double {
        switch self {
        case .struggling: 0.95
        case .average, .aggressivePricing: 1.18
        case .skilled: 1.35
        case .overstocked: 2.10
        }
    }

    func usesExtraService(on day: Int) -> Bool {
        switch self {
        case .struggling:
            false
        case .average, .overstocked:
            day.isMultiple(of: 2)
        case .skilled, .aggressivePricing:
            true
        }
    }
}

private struct EconomyRunner {
    let profile: PlayerProfile
    let days: Int

    private var state = EconomyState()

    init(profile: PlayerProfile, days: Int) {
        self.profile = profile
        self.days = days
    }

    mutating func run() -> EconomyRunResult {
        var results: [EconomyDayResult] = []
        var bankruptcyDay: Int?

        for day in 1...days {
            state.day = day
            state.level = GameProgression.level(for: state.xp)
            buyRecommendedBusinessStage()
            buyRecommendedUpgrades()
            buyStockForDay()
            takeEmergencyLoanIfNeeded()

            let result = playDay()
            results.append(result)

            if state.cash <= bankruptcyLimit {
                bankruptcyDay = day
                break
            }
        }

        return EconomyRunResult(
            profile: profile,
            finalDay: results.last?.day ?? 0,
            businessStage: state.businessStage,
            cash: state.cash,
            debt: state.debt,
            level: state.level,
            xp: state.xp,
            reputation: state.reputation,
            bankruptcyDay: bankruptcyDay,
            days: results
        )
    }

    private mutating func buyRecommendedUpgrades() {
        let plan: [UpgradeID] = [.basket, .thermos, .packingShelf, .waterCrate, .awning, .coldCase, .toppingShelf, .tipJar, .supplierDeal, .brandSign, .masterStaff, .cityCampaign]

        for upgradeID in plan where !state.upgrades.contains(upgradeID) {
            guard let upgrade = upgradeDefinition(for: upgradeID), state.level >= upgrade.requiredLevel else { continue }
            if upgradeID == .toppingShelf, state.businessStage.requiredLevel < BusinessStage.shop.requiredLevel {
                continue
            }
            if [.brandSign, .masterStaff, .cityCampaign].contains(upgradeID), state.businessStage != .istanbulSimitci {
                continue
            }
            let reserve = 260 + fixedCost(for: state.day) + dailyLoanPayment
            guard state.cash - upgrade.cost >= reserve else { continue }

            state.cash -= upgrade.cost
            state.upgrades.insert(upgradeID)
            if upgradeID == .brandSign {
                state.reputation = min(100, state.reputation + 5)
            }
            break
        }
    }

    private mutating func buyRecommendedBusinessStage() {
        guard let next = BusinessStage.allCases.first(where: { $0.previous == state.businessStage }) else { return }
        guard state.level >= next.requiredLevel else { return }
        let reserve = 420 + fixedCost(for: state.day) + dailyLoanPayment
        guard state.cash - next.cost >= reserve else { return }

        state.cash -= next.cost
        state.businessStage = next
    }

    private mutating func buyStockForDay() {
        for product in unlockedProducts {
            let target = targetStock(for: product.id)
            if state.level >= GameProgression.storageUnlockLevel {
                refillStandFromStorage(product.id, target: target)
                buyIntoStorage(product.id, target: targetStorage(for: product.id, standTarget: target))
                refillStandFromStorage(product.id, target: target)
            } else {
                buyDirectlyToStand(product.id, target: target)
            }
        }
    }

    private mutating func buyDirectlyToStand(_ product: ProductID, target: Int) {
        let current = state.stock.quantity(for: product)
        let missing = max(0, min(target, capacity(for: product)) - current)
        let cost = missing * buyCost(for: product)
        guard missing > 0, state.cash >= cost else { return }

        state.cash -= cost
        state.stock.quantities[product, default: 0] = current + missing
    }

    private mutating func buyIntoStorage(_ product: ProductID, target: Int) {
        let current = state.storageStock.quantity(for: product)
        let missing = max(0, min(target, storageCapacity(for: product)) - current)
        let cost = missing * buyCost(for: product)
        guard missing > 0, state.cash >= cost else { return }

        state.cash -= cost
        state.storageStock.quantities[product, default: 0] = current + missing
        state.storageActivated = true
    }

    private mutating func refillStandFromStorage(_ product: ProductID, target: Int) {
        let current = state.stock.quantity(for: product)
        let storageCurrent = state.storageStock.quantity(for: product)
        let needed = max(0, min(target, capacity(for: product)) - current)
        let moved = min(needed, storageCurrent)
        guard moved > 0 else { return }

        state.stock.quantities[product, default: 0] = current + moved
        state.storageStock.quantities[product, default: 0] = storageCurrent - moved
    }

    private mutating func takeEmergencyLoanIfNeeded() {
        guard state.debt == 0, state.cash < 120 else { return }

        let plan: LoanPlan?
        if state.level >= LoanPlan.large.requiredLevel {
            plan = .large
        } else if state.level >= LoanPlan.medium.requiredLevel {
            plan = .medium
        } else if state.level >= LoanPlan.small.requiredLevel {
            plan = .small
        } else {
            plan = nil
        }

        guard let plan, plan.debtAmount <= loanLimit else { return }
        state.cash += plan.cashAmount
        state.debt += plan.debtAmount
        state.loanPlan = plan
    }

    private mutating func playDay() -> EconomyDayResult {
        let priceDemandPenalty = max(0, profile.priceMarkup - 3) / 3
        let reputationDemandPenalty = state.reputation < 15 ? 2 : (state.reputation < 35 ? 1 : 0)
        let businessServiceBonus: Int
        switch state.businessStage {
        case .smallCart: businessServiceBonus = 0
        case .largeCart: businessServiceBonus = 1
        case .shop: businessServiceBonus = 3
        case .istanbulSimitci: businessServiceBonus = 5
        }
        let servedPotential = profile.servedBase
            + min(8, state.level / 3)
            + businessServiceBonus
            - priceDemandPenalty
            - reputationDemandPenalty
        let availableOrdersBeforeMain = availableOrderCount
        let mainServed = min(availableOrdersBeforeMain, max(1, servedPotential))
        let unmetDemandMissed = min(5, max(0, servedPotential - availableOrdersBeforeMain))
        let mainMissed = max(0, profile.missedBase + priceDemandPenalty + reputationDemandPenalty + unmetDemandMissed - state.level / 10)
        let mainWrong = max(0, profile.wrongBase - state.level / 12)
        let bestCombo = profile.comboBase + state.level / 6
        let mainSales = salesMix(served: mainServed)

        for (product, quantity) in mainSales {
            state.stock.quantities[product, default: 0] = max(0, state.stock.quantity(for: product) - quantity)
        }

        let comboMultiplier = (bestCombo >= 8 ? 1.14 : (bestCombo >= 5 ? 1.08 : (bestCombo >= 3 ? 1.04 : 1.0))) + (state.upgrades.contains(.masterStaff) ? 0.05 : 0)
        let mainBaseRevenue = mainSales.reduce(0) { total, item in
            total + item.value * price(for: item.key)
        }
        let mainRevenue = Int((Double(mainBaseRevenue) * comboMultiplier).rounded())

        let availableOrdersBeforeExtra = availableOrderCount
        let runsExtraService = profile.usesExtraService(on: state.day) && availableOrdersBeforeExtra > 0
        let extraDemand = max(1, mainServed / 3 - mainMissed / 2)
        let extraServed = runsExtraService ? min(availableOrdersBeforeExtra, extraDemand) : 0
        let extraStockoutMissed = runsExtraService ? min(3, max(0, extraDemand - availableOrdersBeforeExtra)) : 0
        let extraMissed = runsExtraService ? mainMissed / 2 + extraStockoutMissed : 0
        let extraWrong = runsExtraService ? max(0, mainWrong / 2) : 0
        let extraSales = salesMix(served: extraServed)

        for (product, quantity) in extraSales {
            state.stock.quantities[product, default: 0] = max(0, state.stock.quantity(for: product) - quantity)
        }

        let extraBaseRevenue = extraSales.reduce(0) { total, item in
            total + item.value * price(for: item.key)
        }
        let extraRevenue = Int((Double(extraBaseRevenue) * min(1.08, comboMultiplier)).rounded())
        let revenue = mainRevenue + extraRevenue
        let supplyCost = mainSales.merging(extraSales, uniquingKeysWith: +).reduce(0) { total, item in
            total + item.value * buyCost(for: item.key)
        }
        let fixedCost = fixedCost(for: state.day) + (runsExtraService ? RushMode.extra.fixedCost : 0)
        let storageCost = dailyStorageCost
        let spoiled = spoiledStockLoss()
        let spoilageCost = spoiled.reduce(0) { total, item in
            total + item.value * buyCost(for: item.key)
        }
        let loanPayment = dailyLoanPayment
        let netProfit = revenue - supplyCost - fixedCost - storageCost - spoilageCost - loanPayment

        for (product, quantity) in spoiled {
            let standLoss = min(state.stock.quantity(for: product), quantity)
            state.stock.quantities[product, default: 0] = max(0, state.stock.quantity(for: product) - standLoss)
            let remainingLoss = quantity - standLoss
            if remainingLoss > 0 {
                state.storageStock.quantities[product, default: 0] = max(0, state.storageStock.quantity(for: product) - remainingLoss)
            }
        }

        state.cash += revenue
        state.cash -= fixedCost + storageCost + loanPayment
        state.debt = max(0, state.debt - loanPayment)
        if state.debt == 0 {
            state.loanPlan = nil
        }

        let pricePenalty = min(22, unlockedProducts.reduce(0) { total, product in
            total + max(0, price(for: product.id) - product.sellPrice)
        } / 3)
        let served = mainServed + extraServed
        let missed = mainMissed + extraMissed
        let wrong = mainWrong + extraWrong
        let happiness = max(0, min(100, 74 + state.reputation / 5 + bestCombo - missed * 3 - wrong * 5 - pricePenalty))
        let mainXP = xpForDay(served: mainServed, missed: mainMissed, wrong: mainWrong, bestCombo: bestCombo, happiness: happiness, netProfit: netProfit)
        let extraXP = runsExtraService
            ? Int((Double(xpForDay(served: extraServed, missed: extraMissed, wrong: extraWrong, bestCombo: max(1, bestCombo / 2), happiness: happiness, netProfit: netProfit)) * RushMode.extra.xpMultiplier).rounded())
            : 0
        let xpEarned = mainXP + extraXP
        let previousLevel = state.level
        state.xp += xpEarned
        state.level = GameProgression.level(for: state.xp)
        applyLevelRewards(from: previousLevel, to: state.level)
        let extraRiskPenalty = runsExtraService && extraMissed + extraWrong >= 5 ? 1 : 0
        state.reputation = max(0, min(100, state.reputation + reputationDelta(happiness: happiness) - extraRiskPenalty + (state.upgrades.contains(.cityCampaign) ? 1 : 0)))

        return EconomyDayResult(
            day: state.day,
            level: state.level,
            cash: state.cash,
            debt: state.debt,
            reputation: state.reputation,
            revenue: revenue,
            supplyCost: supplyCost,
            fixedCost: fixedCost,
            storageCost: storageCost,
            spoilageCost: spoilageCost,
            loanPayment: loanPayment,
            netProfit: netProfit,
            xpEarned: xpEarned,
            served: served,
            missed: missed,
            wrong: wrong
        )
    }

    private var unlockedProducts: [ProductDefinition] {
        Products.all.filter { state.level >= $0.unlockLevel }
    }

    private var availableOrderCount: Int {
        let primaryStock = [.simit, .acma, .oliveAcma, .cheesePogaca].reduce(0) { $0 + state.stock.quantity(for: $1) }
        let drinkStock = [.tea, .water, .ayran, .juiceBox].reduce(0) { $0 + state.stock.quantity(for: $1) }
        return max(0, primaryStock + min(primaryStock, drinkStock))
    }

    private var dailyLoanPayment: Int {
        guard state.debt > 0, let loanPlan = state.loanPlan else { return 0 }
        return min(state.debt, loanPlan.dailyPayment)
    }

    private var dailyStorageCost: Int {
        guard state.storageActivated else { return 0 }
        var cost = 16
        if state.upgrades.contains(.coldCase) { cost += 12 }
        if state.upgrades.contains(.toppingShelf) { cost += 8 }
        return cost
    }

    private var loanLimit: Int {
        1_200 + state.level * 140
    }

    private var bankruptcyLimit: Int {
        -(1_000 + max(0, state.level - 1) * 90)
    }

    private func salesMix(served: Int) -> [ProductID: Int] {
        var result: [ProductID: Int] = [:]
        let primaryProducts = [ProductID.simit, .acma, .oliveAcma, .cheesePogaca].filter { state.level >= Products.definition(for: $0).unlockLevel }
        let drinkProducts = [ProductID.tea, .water, .ayran, .juiceBox].filter { state.level >= Products.definition(for: $0).unlockLevel }
        let addOns = [ProductID.cheese, .olivePaste, .chocolate].filter { state.level >= Products.definition(for: $0).unlockLevel }

        for index in 0..<served {
            if let primary = primaryProducts.first(where: { state.stock.quantity(for: $0) > result[$0, default: 0] }) {
                result[primary, default: 0] += 1
            }

            if index % 2 == 0, let drink = drinkProducts.first(where: { state.stock.quantity(for: $0) > result[$0, default: 0] }) {
                result[drink, default: 0] += 1
            }

            if index % 3 == 0, let addOn = addOns.first(where: { state.stock.quantity(for: $0) > result[$0, default: 0] }) {
                result[addOn, default: 0] += 1
            }

            if index % 4 == 0, state.stock.quantity(for: .bag) > result[.bag, default: 0] {
                result[.bag, default: 0] += 1
            }
        }

        return result
    }

    private func targetStock(for product: ProductID) -> Int {
        let expectedSales = profile.servedBase + min(8, state.level / 3)
        let ratio: Double
        switch product {
        case .simit:
            ratio = 1.0
        case .acma, .oliveAcma, .cheesePogaca:
            ratio = state.level >= Products.definition(for: product).unlockLevel ? 0.35 : 0
        case .tea, .water, .ayran:
            ratio = 0.45
        case .juiceBox:
            ratio = 0.25
        case .cheese, .olivePaste, .chocolate:
            ratio = 0.22
        case .bag:
            ratio = 0.55
        }

        let wanted = Int((Double(expectedSales) * ratio * profile.stockBuffer).rounded(.up))
        return min(wanted, capacity(for: product))
    }

    private func targetStorage(for product: ProductID, standTarget: Int) -> Int {
        guard state.level >= GameProgression.storageUnlockLevel else { return 0 }

        let reserveRatio = max(0.18, min(1.1, profile.stockBuffer - 0.85))
        let wanted = Int((Double(standTarget) * reserveRatio).rounded(.up))
        return min(wanted, storageCapacity(for: product))
    }

    private func capacity(for product: ProductID) -> Int {
        let base: Int
        switch product {
        case .simit:
            base = 20
        case .acma:
            base = 10
        case .oliveAcma, .cheesePogaca:
            base = 8
        case .tea:
            base = 12
        case .water:
            base = 14
        case .ayran:
            base = 10
        case .juiceBox:
            base = 12
        case .cheese:
            base = 8
        case .olivePaste:
            base = 7
        case .chocolate:
            base = 6
        case .bag:
            base = 30
        }

        let stagedBase = base + state.businessStage.capacityBonus

        switch product {
        case .simit:
            return stagedBase + (state.upgrades.contains(.basket) ? 10 : 0)
        case .acma, .oliveAcma, .cheesePogaca:
            return stagedBase + (state.upgrades.contains(.basket) ? 4 : 0)
        case .tea:
            return stagedBase + (state.upgrades.contains(.thermos) ? 6 : 0)
        case .water:
            return stagedBase + (state.upgrades.contains(.waterCrate) ? 10 : 0)
        case .ayran, .juiceBox:
            return stagedBase + (state.upgrades.contains(.coldCase) ? 8 : 0)
        case .bag:
            return stagedBase + (state.upgrades.contains(.packingShelf) ? 20 : 0)
        case .cheese, .olivePaste, .chocolate:
            return stagedBase + (state.upgrades.contains(.toppingShelf) ? 6 : 0)
        }
    }

    private func storageCapacity(for product: ProductID) -> Int {
        let base = max(4, baseCapacity(for: product))
        switch product {
        case .simit:
            return base + 20 + (state.upgrades.contains(.basket) ? 16 : 0)
        case .acma, .oliveAcma, .cheesePogaca:
            return base + 8 + (state.upgrades.contains(.basket) ? 8 : 0)
        case .tea:
            return base + 12 + (state.upgrades.contains(.thermos) ? 10 : 0)
        case .water:
            return base + 16 + (state.upgrades.contains(.waterCrate) ? 14 : 0)
        case .ayran, .juiceBox:
            return base + 10 + (state.upgrades.contains(.coldCase) ? 12 : 0)
        case .bag:
            return base + 40 + (state.upgrades.contains(.packingShelf) ? 30 : 0)
        case .cheese, .olivePaste, .chocolate:
            return base + 8 + (state.upgrades.contains(.toppingShelf) ? 10 : 0)
        }
    }

    private func baseCapacity(for product: ProductID) -> Int {
        switch product {
        case .simit:
            20
        case .acma:
            10
        case .oliveAcma, .cheesePogaca:
            8
        case .tea:
            12
        case .water:
            14
        case .ayran:
            10
        case .juiceBox:
            12
        case .cheese:
            8
        case .olivePaste:
            7
        case .chocolate:
            6
        case .bag:
            30
        }
    }

    private func buyCost(for product: ProductID) -> Int {
        max(1, Products.definition(for: product).buyCost - (state.upgrades.contains(.supplierDeal) ? 1 : 0))
    }

    private func price(for product: ProductID) -> Int {
        let definition = Products.definition(for: product)
        return min(definition.maximumSellPrice, definition.sellPrice + profile.priceMarkup)
    }

    private func fixedCost(for day: Int) -> Int {
        let monthIndex = min(10, max(0, (day - 1) / 30))
        let rent = Int((120.0 * pow(1.08, Double(monthIndex)) * state.businessStage.rentMultiplier).rounded())
        return rent + (state.upgrades.contains(.masterStaff) ? 90 : 0) + (state.upgrades.contains(.cityCampaign) ? 160 : 0)
    }

    private func upgradeDefinition(for id: UpgradeID) -> UpgradeDefinition? {
        let definitions: [UpgradeDefinition] = [
            .init(id: .basket, name: "Simit Deposu", detail: "", systemImage: "", cost: 620, requiredLevel: 3),
            .init(id: .thermos, name: "Büyük Çay Termosu", detail: "", systemImage: "", cost: 740, requiredLevel: 5),
            .init(id: .packingShelf, name: "Poşet Rafı", detail: "", systemImage: "", cost: 520, requiredLevel: 7),
            .init(id: .waterCrate, name: "Su Kasası", detail: "", systemImage: "", cost: 680, requiredLevel: 9),
            .init(id: .awning, name: "Gölgelik Branda", detail: "", systemImage: "", cost: 980, requiredLevel: 11),
            .init(id: .coldCase, name: "Soğuk Dolap", detail: "", systemImage: "", cost: 1_250, requiredLevel: 14),
            .init(id: .toppingShelf, name: "Ek Malzeme Rafı", detail: "", systemImage: "", cost: 1_450, requiredLevel: 20),
            .init(id: .tipJar, name: "Bahşiş Kutusu", detail: "", systemImage: "", cost: 2_400, requiredLevel: 24),
            .init(id: .supplierDeal, name: "Toptancı Anlaşması", detail: "", systemImage: "", cost: 3_600, requiredLevel: 27),
            .init(id: .brandSign, name: "Altın Tabela", detail: "", systemImage: "", cost: 18_000, requiredLevel: 30),
            .init(id: .masterStaff, name: "Usta Ekibi", detail: "", systemImage: "", cost: 32_000, requiredLevel: 30),
            .init(id: .cityCampaign, name: "İstanbul Kampanyası", detail: "", systemImage: "", cost: 50_000, requiredLevel: 30)
        ]
        return definitions.first { $0.id == id }
    }

    private func spoiledStockLoss() -> [ProductID: Int] {
        let products: [ProductID] = [.tea, .ayran, .acma, .oliveAcma, .cheesePogaca, .juiceBox, .cheese, .olivePaste, .chocolate]
        var result: [ProductID: Int] = [:]

        for product in products where state.level >= Products.definition(for: product).unlockLevel {
            let total = state.stock.quantity(for: product) + state.storageStock.quantity(for: product)
            guard total >= 4 else { continue }

            let loss = min(4, max(0, Int((Double(total) * spoilageRatio(for: product)).rounded())))
            if loss > 0 {
                result[product] = loss
            }
        }

        return result
    }

    private func spoilageRatio(for product: ProductID) -> Double {
        let base: Double
        switch product {
        case .ayran, .juiceBox:
            base = 0.055
        case .acma, .oliveAcma, .cheesePogaca:
            base = 0.065
        case .cheese, .olivePaste, .chocolate:
            base = 0.050
        case .tea:
            base = 0.035
        case .simit, .water, .bag:
            base = 0
        }

        if [.ayran, .juiceBox].contains(product), state.upgrades.contains(.coldCase) {
            return base * 0.45
        }
        if product.isAddOn, state.upgrades.contains(.toppingShelf) {
            return base * 0.60
        }
        return base
    }

    private mutating func applyLevelRewards(from oldLevel: Int, to newLevel: Int) {
        guard newLevel > oldLevel else { return }

        for reachedLevel in (oldLevel + 1)...newLevel {
            let bonus = GameProgression.milestoneBonus(for: reachedLevel)
            for product in ProductID.allCases {
                let added = bonus.quantity(for: product)
                guard added > 0 else { continue }
                let current = state.stock.quantity(for: product)
                state.stock.quantities[product, default: 0] = min(capacity(for: product), current + added)
            }

            if reachedLevel % 5 == 0 {
                state.cash += 75 + reachedLevel * 8
            }
        }
    }

    private func xpForDay(served: Int, missed: Int, wrong: Int, bestCombo: Int, happiness: Int, netProfit: Int) -> Int {
        let happinessBonus = happiness >= 90 ? 10 : (happiness >= 80 ? 6 : (happiness >= 70 ? 3 : 0))
        let profitBonus = max(0, min(18, netProfit / 45))
        let errorPenalty = missed * 3 + wrong * 4
        return max(3, max(8, served * 3 + bestCombo * 2 + happinessBonus + profitBonus - errorPenalty))
    }

    private func reputationDelta(happiness: Int) -> Int {
        happiness >= 88 ? 2 : (happiness >= 75 ? 1 : (happiness < 30 ? -2 : (happiness < 45 ? -1 : 0)))
    }
}

private struct EconomyState {
    var day = 1
    var cash = 520
    var debt = 0
    var loanPlan: LoanPlan?
    var xp = 0
    var level = 1
    var reputation = 20
    var stock = StockState.starter
    var storageStock = StockState.empty
    var storageActivated = false
    var upgrades: Set<UpgradeID> = []
    var businessStage: BusinessStage = .smallCart
}
#endif
