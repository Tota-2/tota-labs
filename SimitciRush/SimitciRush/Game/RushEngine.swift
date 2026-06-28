import Foundation

enum RushFeedbackKind {
    case neutral
    case success
    case warning
    case danger
}

struct PayoutPop: Identifiable, Equatable {
    let id = UUID()
    let base: Int
    let bonus: Int
    let total: Int
    let combo: Int
}

enum RushServiceEventKind: Equatable {
    case success
    case wrong
    case missed
}

struct RushServiceEvent: Identifiable, Equatable {
    let id = UUID()
    let kind: RushServiceEventKind
    let products: [ProductID]
    let total: Int
    let combo: Int
}

@MainActor
final class RushEngine: ObservableObject {
    @Published var timeRemaining: Double = 60
    @Published var activeCustomer: Customer
    @Published var queue: [Customer]
    @Published var selectedItems: [ProductID] = []
    @Published var stock: StockState
    @Published var earnedCash: Int = 0
    @Published var servedCount: Int = 0
    @Published var missedCount: Int = 0
    @Published var wrongCount: Int = 0
    @Published var happiness: Int = 80
    @Published var combo: Int = 0
    @Published var bestCombo: Int = 0
    @Published var customerPatience: Double
    @Published var feedback: String = "Hazır"
    @Published var feedbackKind: RushFeedbackKind = .neutral
    @Published var payoutPop: PayoutPop?
    @Published var serviceEvent: RushServiceEvent?
    @Published var isPaused: Bool = false

    let availableProducts: [ProductID]
    private(set) var completedOrderSeconds: Double = 0

    var activeCustomerMaxPatience: Double {
        maxPatience(for: activeCustomer)
    }

    var activeOrderCanBeFulfilled: Bool {
        canFulfill(activeCustomer.order)
    }

    var missingOrderItems: [ProductID] {
        activeCustomer.order.filter { stock.quantity(for: $0) <= 0 }
    }

    private let startingStock: StockState
    private let prices: [ProductID: Int]
    private let buyCosts: [ProductID: Int]
    private let duration: Double
    private let patienceMultiplier: Double
    private let comboPayoutBonus: Double
    private let reputation: Int
    private let pricePressure: Int
    private var timer: Timer?
    private var random: SeededRandom
    private var customerStartedAtRemaining: Double
    private var answeredDialogueIDs: Set<String> = []
    private var soldProducts: [ProductID: Int] = [:]

    init(
        startingStock: StockState,
        prices: [ProductID: Int],
        buyCosts: [ProductID: Int],
        availableProducts: [ProductID],
        duration: Double = 60,
        patienceMultiplier: Double,
        comboPayoutBonus: Double,
        reputation: Int,
        pricePressure: Int,
        seed: UInt64 = UInt64(Date().timeIntervalSince1970 * 1_000) ^ UInt64.random(in: 1...UInt64.max)
    ) {
        self.startingStock = startingStock
        self.prices = prices
        self.buyCosts = buyCosts
        self.availableProducts = availableProducts
        self.duration = duration
        self.patienceMultiplier = patienceMultiplier
        self.comboPayoutBonus = comboPayoutBonus
        self.reputation = reputation
        self.pricePressure = pricePressure
        random = SeededRandom(seed: seed)
        timeRemaining = duration
        customerStartedAtRemaining = duration
        stock = startingStock
        happiness = min(95, max(58, 72 + reputation / 4 - min(12, pricePressure / 2)))
        var generator = random
        let firstCustomer = CustomerFactory.makeCustomer(
            random: &generator,
            index: 0,
            availableProducts: availableProducts,
            standStock: startingStock
        )
        activeCustomer = firstCustomer
        queue = (1...3).map {
            CustomerFactory.makeCustomer(
                random: &generator,
                index: $0,
                availableProducts: availableProducts,
                standStock: startingStock
            )
        }
        customerPatience = firstCustomer.patienceSeconds * patienceMultiplier
        random = generator
    }

    deinit {
        timer?.invalidate()
    }

    func start() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func pause() {
        isPaused = true
    }

    func resume() {
        isPaused = false
    }

    func select(_ product: ProductID) {
        guard availableProducts.contains(product) else {
            setFeedback("Ürün kilitli", kind: .warning)
            return
        }

        guard stock.quantity(for: product) > 0 else {
            setFeedback("Stok bitti", kind: .warning)
            return
        }
        guard activeCustomer.order.contains(product) else {
            setFeedback("Siparişte yok", kind: .warning)
            return
        }
        guard !selectedItems.contains(product) else {
            setFeedback("Zaten tepside", kind: .warning)
            return
        }
        selectedItems.append(product)
        setFeedback("\(Products.definition(for: product).name) eklendi", kind: .neutral)
    }

    func clearTray() {
        selectedItems.removeAll()
        setFeedback("Tepsi temizlendi", kind: .neutral)
    }

    func serve() {
        guard !selectedItems.isEmpty else {
            setFeedback("Önce ürün seç", kind: .warning)
            return
        }

        let expected = activeCustomer.order.sorted { $0.rawValue < $1.rawValue }
        let selected = selectedItems.sorted { $0.rawValue < $1.rawValue }

        if expected == selected {
            completeCorrectOrder()
        } else {
            publishServiceEvent(kind: .wrong, products: selectedItems, total: 0, combo: combo)
            wrongCount += 1
            happiness = max(0, happiness - 5)
            combo = 0
            setFeedback(wrongOrderMessage(expected: expected, selected: selected), kind: .danger)
            selectedItems.removeAll()
        }
    }

    func declineUnavailableOrder() {
        guard !activeOrderCanBeFulfilled else {
            setFeedback("Sipariş hazırlanabilir", kind: .neutral)
            return
        }

        missedCount += 1
        happiness = max(0, happiness - 2)
        combo = 0
        selectedItems.removeAll()
        let missingNames = missingOrderItems.map { Products.definition(for: $0).name }.joined(separator: ", ")
        setFeedback(missingNames.isEmpty ? "Stok yok dendi" : "\(missingNames) yok dendi", kind: .warning)
        publishServiceEvent(kind: .missed, products: [], total: 0, combo: combo)
        advanceCustomer()
    }

    func chooseDialogue(_ response: DialogueResponse) {
        guard let dialogue = activeCustomer.dialogue, !answeredDialogueIDs.contains(dialogue.id) else {
            setFeedback("Cevap verildi", kind: .neutral)
            return
        }

        answeredDialogueIDs.insert(dialogue.id)

        switch response.effect {
        case .trust:
            happiness = min(100, happiness + 2)
            setFeedback("Güven arttı", kind: .success)
        case .neutral:
            setFeedback("Tamam", kind: .neutral)
        case .combo:
            happiness = min(100, happiness + 1)
            customerPatience = min(activeCustomer.patienceSeconds + 2, customerPatience + 0.8)
            setFeedback("Ritim yakalandı", kind: .success)
        case .upsell:
            happiness = min(100, happiness + 1)
            setFeedback("Müşteri memnun", kind: .success)
        case .risky:
            customerPatience = max(1, customerPatience - 1)
            setFeedback("Riskli cevap", kind: .warning)
        }
    }

    func makeReport(dailyFixedCost: Int, loanPayment: Int, xpMultiplier: Double = 1, extraReputationRisk: Bool = false) -> DayReport {
        stop()
        let supplyCost = Products.all.reduce(0) { total, product in
            let soldQuantity = max(0, startingStock.quantity(for: product.id) - stock.quantity(for: product.id))
            return total + soldQuantity * buyCost(for: product.id)
        }
        let totalCosts = supplyCost + dailyFixedCost + loanPayment
        let netProfit = earnedCash - totalCosts
        let basePricePenalty = Products.all.reduce(0) { total, product in
            let overBase = max(0, price(for: product.id) - product.sellPrice)
            return total + (product.id.isAddOn ? overBase / 2 : overBase)
        } / 3
        let pricePenalty = min(22, basePricePenalty)
        let finalHappiness = max(0, happiness - pricePenalty)
        let score = netProfit + (finalHappiness * 3) + (bestCombo * 20) - (missedCount * 25) - (wrongCount * 15)
        let happinessBonus = finalHappiness >= 90 ? 10 : (finalHappiness >= 80 ? 6 : (finalHappiness >= 70 ? 3 : 0))
        let profitBonus = max(0, min(18, netProfit / 45))
        let errorPenalty = missedCount * 3 + wrongCount * 4
        let baseXP = max(8, servedCount * 3 + bestCombo * 2 + happinessBonus + profitBonus - errorPenalty)
        let xpEarned = max(3, Int((Double(baseXP) * xpMultiplier).rounded()))
        let baseReputationDelta = finalHappiness >= 88 ? 2 : (finalHappiness >= 75 ? 1 : (finalHappiness < 30 ? -2 : (finalHappiness < 45 ? -1 : 0)))
        let extraRiskPenalty = extraReputationRisk && missedCount + wrongCount >= 5 ? 1 : 0
        let reputationDelta = baseReputationDelta - extraRiskPenalty
        return DayReport(
            revenue: earnedCash,
            supplyCost: supplyCost,
            fixedCost: dailyFixedCost,
            loanPayment: loanPayment,
            pricePenalty: pricePenalty,
            netProfit: netProfit,
            served: servedCount,
            missed: missedCount,
            wrong: wrongCount,
            happiness: finalHappiness,
            bestCombo: bestCombo,
            score: max(0, score),
            xpEarned: xpEarned,
            reputationDelta: reputationDelta,
            completedOrderSeconds: completedOrderSeconds,
            soldProducts: soldProducts
        )
    }

    private func tick() {
        guard !isPaused else { return }

        timeRemaining = max(0, timeRemaining - 0.1)
        customerPatience = max(0, customerPatience - 0.1)

        if customerPatience <= 0 {
            missCustomer()
        }

        if timeRemaining <= 0 {
            stop()
        }
    }

    private func completeCorrectOrder() {
        for product in selectedItems {
            stock.quantities[product, default: 0] = max(0, stock.quantity(for: product) - 1)
            soldProducts[product, default: 0] += 1
        }

        combo += 1
        bestCombo = max(bestCombo, combo)
        servedCount += 1
        completedOrderSeconds += max(0, customerStartedAtRemaining - timeRemaining)
        happiness = min(100, happiness + 1)

        let basePayout = orderTotal(activeCustomer.order)
        let multiplier: Double = (combo >= 6 ? 1.2 : (combo >= 3 ? 1.1 : 1.0)) + comboPayoutBonus
        let payout = Int(Double(basePayout) * multiplier)
        let bonus = max(0, payout - basePayout)
        earnedCash += payout
        showPayoutPop(base: basePayout, bonus: bonus, total: payout, combo: combo)
        publishServiceEvent(kind: .success, products: selectedItems, total: payout, combo: combo)
        GameAudio.shared.play(.coin, volume: bonus > 0 ? 0.52 : 0.44)
        setFeedback("+\(payout) TL", kind: .success)
        selectedItems.removeAll()
        advanceCustomer()
    }

    private func missCustomer() {
        missedCount += 1
        happiness = max(0, happiness - 3)
        combo = 0
        setFeedback("Müşteri kaçtı", kind: .danger)
        selectedItems.removeAll()
        publishServiceEvent(kind: .missed, products: [], total: 0, combo: combo)
        advanceCustomer()
    }

    private func advanceCustomer() {
        let queuedCustomer = queue.removeFirst()
        activeCustomer = queuedCustomer
        queue.append(makeCustomer(index: servedCount + missedCount + wrongCount + queue.count))
        customerStartedAtRemaining = timeRemaining
        customerPatience = maxPatience(for: activeCustomer)
        answeredDialogueIDs.removeAll()
    }

    private func makeCustomer(index: Int) -> Customer {
        CustomerFactory.makeCustomer(
            random: &random,
            index: index,
            availableProducts: availableProducts,
            standStock: stock
        )
    }

    private func canFulfill(_ order: [ProductID]) -> Bool {
        order.allSatisfy { stock.quantity(for: $0) > 0 }
    }

    private func setFeedback(_ message: String, kind: RushFeedbackKind) {
        feedback = message
        feedbackKind = kind
    }

    private func wrongOrderMessage(expected: [ProductID], selected: [ProductID]) -> String {
        let missing = expected.filter { !selected.contains($0) }
        let extra = selected.filter { !expected.contains($0) }

        if let product = missing.first {
            return "\(Products.definition(for: product).name) eksik"
        }

        if let product = extra.first {
            return "\(Products.definition(for: product).name) fazla"
        }

        return "Yanlış sipariş"
    }

    private func showPayoutPop(base: Int, bonus: Int, total: Int, combo: Int) {
        let pop = PayoutPop(base: base, bonus: bonus, total: total, combo: combo)
        payoutPop = pop

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(bonus > 0 ? 1150 : 820))
            if self.payoutPop?.id == pop.id {
                self.payoutPop = nil
            }
        }
    }

    private func publishServiceEvent(kind: RushServiceEventKind, products: [ProductID], total: Int, combo: Int) {
        let event = RushServiceEvent(kind: kind, products: products, total: total, combo: combo)
        serviceEvent = event

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(kind == .success ? 920 : 520))
            if self.serviceEvent?.id == event.id {
                self.serviceEvent = nil
            }
        }
    }

    private func orderTotal(_ order: [ProductID]) -> Int {
        order.reduce(0) { $0 + price(for: $1) }
    }

    private func price(for product: ProductID) -> Int {
        prices[product, default: Products.definition(for: product).sellPrice]
    }

    private func buyCost(for product: ProductID) -> Int {
        buyCosts[product, default: Products.definition(for: product).buyCost]
    }

    private func maxPatience(for customer: Customer) -> Double {
        let priceDrag = max(0.64, 1.0 - Double(min(24, pricePressure)) * 0.018)
        return customer.patienceSeconds * patienceMultiplier * priceDrag
    }
}
