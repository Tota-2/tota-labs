import Foundation

enum ProductID: String, Codable, CaseIterable, Identifiable {
    case simit
    case acma
    case oliveAcma
    case cheesePogaca
    case tea
    case water
    case ayran
    case juiceBox
    case cheese
    case chocolate
    case olivePaste
    case bag

    var id: String { rawValue }

    var isAddOn: Bool {
        switch self {
        case .cheese, .olivePaste, .chocolate:
            true
        case .simit, .acma, .oliveAcma, .cheesePogaca, .tea, .water, .ayran, .juiceBox, .bag:
            false
        }
    }
}

struct ProductDefinition: Identifiable, Codable, Equatable {
    let id: ProductID
    let name: String
    let symbol: String
    let buyCost: Int
    let sellPrice: Int
    let unlockLevel: Int

    var maximumSellPrice: Int {
        sellPrice + max(1, Int((Double(sellPrice) * 0.25).rounded()))
    }
}

enum Products {
    static let all: [ProductDefinition] = [
        .init(id: .simit, name: "Simit", symbol: "circle", buyCost: 13, sellPrice: 25, unlockLevel: 1),
        .init(id: .acma, name: "Açma", symbol: "circle.dotted", buyCost: 19, sellPrice: 35, unlockLevel: 8),
        .init(id: .oliveAcma, name: "Zeytinli Açma", symbol: "leaf.fill", buyCost: 24, sellPrice: 42, unlockLevel: 13),
        .init(id: .cheesePogaca, name: "Peynirli Poğaça", symbol: "takeoutbag.and.cup.and.straw.fill", buyCost: 22, sellPrice: 40, unlockLevel: 17),
        .init(id: .tea, name: "Çay", symbol: "cup.and.saucer.fill", buyCost: 6, sellPrice: 15, unlockLevel: 1),
        .init(id: .water, name: "Su", symbol: "waterbottle.fill", buyCost: 5, sellPrice: 10, unlockLevel: 1),
        .init(id: .ayran, name: "Ayran", symbol: "cup.and.saucer.fill", buyCost: 9, sellPrice: 18, unlockLevel: 1),
        .init(id: .juiceBox, name: "Kutu Meyve Suyu", symbol: "takeoutbag.and.cup.and.straw.fill", buyCost: 12, sellPrice: 22, unlockLevel: 10),
        .init(id: .cheese, name: "Peynir", symbol: "triangle.fill", buyCost: 5, sellPrice: 8, unlockLevel: 3),
        .init(id: .olivePaste, name: "Zeytin Ezmesi", symbol: "drop.fill", buyCost: 6, sellPrice: 9, unlockLevel: 5),
        .init(id: .chocolate, name: "Çikolata", symbol: "takeoutbag.and.cup.and.straw.fill", buyCost: 7, sellPrice: 10, unlockLevel: 7),
        .init(id: .bag, name: "Poşet", symbol: "bag.fill", buyCost: 1, sellPrice: 2, unlockLevel: 1)
    ]

    static func definition(for id: ProductID) -> ProductDefinition {
        guard let definition = all.first(where: { $0.id == id }) else {
            assertionFailure("Missing product definition for \(id.rawValue)")
            return all[0]
        }
        return definition
    }

    static var basePrices: [ProductID: Int] {
        Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0.sellPrice) })
    }

    static var addOns: [ProductDefinition] {
        all.filter { $0.id.isAddOn }
    }
}

struct StockState: Codable, Equatable {
    var quantities: [ProductID: Int]

    static let empty = StockState(quantities: [:])

    static let starter = StockState(quantities: [
        .simit: 20,
        .tea: 12,
        .water: 14,
        .ayran: 10,
        .bag: 30
    ])

    func quantity(for product: ProductID) -> Int {
        quantities[product, default: 0]
    }
}
