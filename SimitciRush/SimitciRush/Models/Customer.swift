import Foundation

enum CustomerType: String, Codable, CaseIterable {
    case student
    case officeWorker
    case tourist
    case taxiDriver
    case elder
    case rushed

    var displayName: String {
        switch self {
        case .student: "Öğrenci"
        case .officeWorker: "Plaza"
        case .tourist: "Turist"
        case .taxiDriver: "Taksici"
        case .elder: "Mahalleli"
        case .rushed: "Aceleci"
        }
    }

    var patienceSeconds: Double {
        switch self {
        case .student: 5
        case .officeWorker: 4
        case .tourist: 7
        case .taxiDriver: 6
        case .elder: 8
        case .rushed: 3
        }
    }
}

struct Customer: Identifiable, Codable, Equatable {
    let id: UUID
    let type: CustomerType
    let order: [ProductID]
    let patienceSeconds: Double
    let dialogue: DialoguePrompt?

    var orderTotal: Int {
        order.reduce(0) { $0 + Products.definition(for: $1).sellPrice }
    }
}

struct DialoguePrompt: Identifiable, Codable, Equatable {
    let id: String
    let line: String
    let responses: [DialogueResponse]
}

struct DialogueResponse: Identifiable, Codable, Equatable {
    let id: String
    let text: String
    let effect: DialogueEffect
}

enum DialogueEffect: String, Codable, Equatable {
    case trust
    case neutral
    case combo
    case upsell
    case risky
}
