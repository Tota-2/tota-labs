import Foundation

enum CustomerFactory {
    static func makeCustomer(
        random: inout SeededRandom,
        index: Int,
        availableProducts: [ProductID],
        standStock: StockState? = nil
    ) -> Customer {
        let type = weightedCustomerType(random: &random)
        let order = weightedOrder(random: &random, availableProducts: availableProducts, standStock: standStock)
        let dialogue = index % 5 == 0 ? dialogue(for: type, order: order, random: &random) : nil

        return Customer(
            id: UUID(),
            type: type,
            order: order,
            patienceSeconds: type.patienceSeconds,
            dialogue: dialogue
        )
    }

    private static func weightedCustomerType(random: inout SeededRandom) -> CustomerType {
        switch random.nextInt(upperBound: 100) {
        case 0..<30: .officeWorker
        case 30..<50: .taxiDriver
        case 50..<65: .student
        case 65..<80: .tourist
        case 80..<90: .elder
        default: .rushed
        }
    }

    private static func weightedOrder(random: inout SeededRandom, availableProducts: [ProductID], standStock: StockState?) -> [ProductID] {
        let baseOptions: [[ProductID]] = [
            [.simit],
            [.simit, .tea],
            [.simit, .water],
            [.simit, .ayran],
            [.simit, .bag],
            [.tea],
            [.water],
            [.ayran],
            [.juiceBox],
            [.simit, .cheese],
            [.simit, .olivePaste],
            [.simit, .chocolate],
            [.simit, .tea, .bag],
            [.simit, .ayran, .bag],
            [.simit, .cheese, .tea],
            [.simit, .olivePaste, .tea],
            [.acma],
            [.acma, .tea],
            [.acma, .juiceBox],
            [.oliveAcma],
            [.oliveAcma, .ayran],
            [.cheesePogaca],
            [.cheesePogaca, .tea],
            [.cheesePogaca, .juiceBox]
        ].filter { order in
            let includesAddOn = order.contains { $0.isAddOn }
            return order.allSatisfy { availableProducts.contains($0) }
                && (!includesAddOn || order.contains(.simit))
        }

        let options = baseOptions.flatMap { order in
            Array(repeating: order, count: weight(for: order))
        }

        guard !options.isEmpty else {
            return availableProducts.first(where: { !$0.isAddOn }).map { [$0] } ?? [.simit]
        }

        guard let standStock else {
            return options[random.nextInt(upperBound: options.count)]
        }

        if let stockoutDemand = realisticStockoutDemand(from: options, standStock: standStock, random: &random) {
            return stockoutDemand
        }

        let fulfillableOptions = options.filter { order in
            order.allSatisfy { standStock.quantity(for: $0) > 0 }
        }

        guard !fulfillableOptions.isEmpty else {
            return options[random.nextInt(upperBound: options.count)]
        }

        // Most customers naturally ask for what the stand seems to be selling, but demand
        // does not disappear just because the player understocked a popular item.
        let preferFulfillableOrder = random.nextInt(upperBound: 100) < 58
        let pool = preferFulfillableOrder ? fulfillableOptions : options
        return pool[random.nextInt(upperBound: pool.count)]
    }

    private static func realisticStockoutDemand(from options: [[ProductID]], standStock: StockState, random: inout SeededRandom) -> [ProductID]? {
        let emptyStaples = [ProductID.simit, .tea, .water, .ayran, .bag].filter { product in
            options.contains { $0.contains(product) } && standStock.quantity(for: product) == 0
        }

        guard !emptyStaples.isEmpty else { return nil }

        let chance: Int
        if emptyStaples.contains(.simit) {
            chance = 45
        } else if emptyStaples.contains(.tea) || emptyStaples.contains(.ayran) || emptyStaples.contains(.water) {
            chance = 26
        } else {
            chance = 16
        }

        guard random.nextInt(upperBound: 100) < chance else { return nil }

        let demandedProduct = emptyStaples[random.nextInt(upperBound: emptyStaples.count)]
        let demandedOptions = options.filter { $0.contains(demandedProduct) }
        guard !demandedOptions.isEmpty else { return nil }
        return demandedOptions[random.nextInt(upperBound: demandedOptions.count)]
    }

    private static func weight(for order: [ProductID]) -> Int {
        if order == [.simit] { return 7 }
        if order == [.simit, .tea] { return 6 }
        if order == [.simit, .bag] { return 4 }
        if order == [.tea] || order == [.water] || order == [.ayran] || order == [.juiceBox] { return 2 }
        if order.contains(.simit), order.contains(where: { $0.isAddOn }) { return 3 }
        if order.contains(.simit) { return 3 }
        if order.contains(.acma) || order.contains(.oliveAcma) || order.contains(.cheesePogaca) { return 2 }
        return 1
    }

    private static func dialogue(for type: CustomerType, order: [ProductID], random: inout SeededRandom) -> DialoguePrompt {
        var prompts: [DialoguePrompt] = []

        if order.contains(where: { [.simit, .acma, .oliveAcma, .cheesePogaca].contains($0) }) {
            prompts.append(DialoguePrompt(
                id: "fresh_bakery",
                line: "Taze mi usta?",
                responses: [
                    .init(id: "fresh", text: "Sıcak sıcak", effect: .trust),
                    .init(id: "tea", text: "Çay öner", effect: .combo)
                ]
            ))
        }

        if order.contains(where: { [.cheese, .olivePaste, .chocolate].contains($0) }) {
            prompts.append(DialoguePrompt(
                id: "spread",
                line: "Bol sürer misin?",
                responses: [
                    .init(id: "balanced", text: "Tam kıvam", effect: .trust),
                    .init(id: "fast", text: "Az bekle", effect: .risky)
                ]
            ))
        }

        switch type {
        case .student:
            prompts.append(DialoguePrompt(
                id: "student_budget",
                line: "Uygun olur mu?",
                responses: [
                    .init(id: "fair", text: "Esnaf fiyatı", effect: .trust),
                    .init(id: "fixed", text: "Fiyat aynı", effect: .risky)
                ]
            ))
        case .taxiDriver, .rushed:
            prompts.append(DialoguePrompt(
                id: "quick_service",
                line: "Hızlı olsun.",
                responses: [
                    .init(id: "ready", text: "Hemen", effect: .trust),
                    .init(id: "bag", text: "Poşet hazır", effect: .combo)
                ]
            ))
        case .tourist:
            prompts.append(DialoguePrompt(
                id: "tourist_help",
                line: "Neyle yenir?",
                responses: [
                    .init(id: "tea", text: "Çayla", effect: .combo),
                    .init(id: "plain", text: "Sade güzel", effect: .trust)
                ]
            ))
        case .elder:
            prompts.append(DialoguePrompt(
                id: "elder_kind",
                line: "Taze olsun.",
                responses: [
                    .init(id: "respect", text: "En tazesi", effect: .trust),
                    .init(id: "same", text: "Hepsi aynı", effect: .risky)
                ]
            ))
        case .officeWorker:
            prompts.append(DialoguePrompt(
                id: "office_time",
                line: "Yetişmem lazım.",
                responses: [
                    .init(id: "fast", text: "Al çık", effect: .trust),
                    .init(id: "bag", text: "Poşetle", effect: .combo)
                ]
            ))
        }

        return prompts[random.nextInt(upperBound: prompts.count)]
    }
}

struct SeededRandom {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func nextInt(upperBound: Int) -> Int {
        state = 2862933555777941757 &* state &+ 3037000493
        return Int(state % UInt64(upperBound))
    }
}
