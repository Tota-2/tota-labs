import Foundation

enum UpgradeID: String, CaseIterable, Identifiable, Codable {
    case basket
    case thermos
    case packingShelf
    case waterCrate
    case coldCase
    case toppingShelf
    case awning
    case tipJar
    case supplierDeal
    case brandSign
    case masterStaff
    case cityCampaign

    var id: String { rawValue }
}

struct UpgradeDefinition: Identifiable, Equatable {
    let id: UpgradeID
    let name: String
    let detail: String
    let systemImage: String
    let cost: Int
    let requiredLevel: Int

    init(id: UpgradeID, name: String, detail: String, systemImage: String, cost: Int, requiredLevel: Int = 1) {
        self.id = id
        self.name = name
        self.detail = detail
        self.systemImage = systemImage
        self.cost = cost
        self.requiredLevel = requiredLevel
    }
}

enum BusinessStage: String, CaseIterable, Identifiable, Codable {
    case smallCart
    case largeCart
    case shop
    case istanbulSimitci

    var id: String { rawValue }

    var title: String {
        switch self {
        case .smallCart: "Küçük Seyyar Tabla"
        case .largeCart: "Büyük Seyyar Tabla"
        case .shop: "Simitçi Dükkânı"
        case .istanbulSimitci: "İstanbul Simitçisi"
        }
    }

    var detail: String {
        switch self {
        case .smallCart: "Başlangıç işletmesi"
        case .largeCart: "Temel tezgâh kapasitesi +4, müşteri sabrı +%4"
        case .shop: "Temel tezgâh kapasitesi +8, müşteri sabrı +%8"
        case .istanbulSimitci: "Temel tezgâh kapasitesi +12, müşteri sabrı +%12"
        }
    }

    var requiredLevel: Int {
        switch self {
        case .smallCart: 1
        case .largeCart: 10
        case .shop: 20
        case .istanbulSimitci: 30
        }
    }

    var cost: Int {
        switch self {
        case .smallCart: 0
        case .largeCart: 1_800
        case .shop: 5_200
        case .istanbulSimitci: 11_000
        }
    }

    var rentMultiplier: Double {
        switch self {
        case .smallCart: 1
        case .largeCart: 1.25
        case .shop: 1.65
        case .istanbulSimitci: 2
        }
    }

    var capacityBonus: Int {
        switch self {
        case .smallCart: 0
        case .largeCart: 4
        case .shop: 8
        case .istanbulSimitci: 12
        }
    }

    var servicePatienceMultiplier: Double {
        switch self {
        case .smallCart: 1
        case .largeCart: 1.04
        case .shop: 1.08
        case .istanbulSimitci: 1.12
        }
    }

    var previous: BusinessStage? {
        switch self {
        case .smallCart: nil
        case .largeCart: .smallCart
        case .shop: .largeCart
        case .istanbulSimitci: .shop
        }
    }
}

enum GameProgression {
    static let maxLevel = 30
    static let storageUnlockLevel = 5

    static func level(for xp: Int) -> Int {
        var resolvedLevel = 1
        for level in 2...maxLevel where xp >= requiredXP(for: level) {
            resolvedLevel = level
        }
        return resolvedLevel
    }

    static func requiredXP(for level: Int) -> Int {
        guard level > 1 else { return 0 }
        let previousLevel = level - 1
        return Int((70.0 * pow(Double(previousLevel), 1.58)).rounded())
    }

    static func xpForNextLevel(currentLevel: Int) -> Int? {
        currentLevel >= maxLevel ? nil : requiredXP(for: currentLevel + 1)
    }

    static func milestoneBonus(for level: Int) -> StockState {
        switch level {
        case 2...5:
            return StockState(quantities: [.bag: 5])
        case 6...10:
            return StockState(quantities: [.simit: 4, .tea: 2])
        case 11...15:
            return StockState(quantities: [.water: 3, .ayran: 2])
        case 16...20:
            return StockState(quantities: [.simit: 5, .bag: 8])
        case 21...25:
            return StockState(quantities: [.tea: 3, .water: 3, .ayran: 2])
        case 26...30:
            return StockState(quantities: [.simit: 6, .cheese: 2, .olivePaste: 2])
        default:
            return StockState(quantities: [:])
        }
    }
}

enum GameScreen {
    case mainMenu
    case introStory
    case home
    case prep
    case rush
    case report
    case dayClose
    case absenceReport
    case store
    case settings
    case market
    case upgrades
    case profile
    case bankruptcy
}

enum CloudSaveStatus: Equatable {
    case localOnly
    case synced
    case restoredFromCloud

    var title: String {
        switch self {
        case .localOnly: "Bu cihazda"
        case .synced: "iCloud eşitlendi"
        case .restoredFromCloud: "iCloud'dan yüklendi"
        }
    }

    var detail: String {
        switch self {
        case .localOnly: "iCloud yoksa ilerleme bu cihazda saklanır."
        case .synced: "İlerleme bu cihaz ve iCloud arasında saklanıyor."
        case .restoredFromCloud: "Daha yeni kayıt iCloud'dan alındı."
        }
    }

    var systemImage: String {
        switch self {
        case .localOnly: "iphone"
        case .synced: "icloud.fill"
        case .restoredFromCloud: "icloud.and.arrow.down.fill"
        }
    }
}

enum RushMode: String, Codable {
    case main
    case extra

    var duration: Double {
        switch self {
        case .main: 60
        case .extra: 20
        }
    }

    var fixedCost: Int {
        switch self {
        case .main: 0
        case .extra: 120
        }
    }

    var xpMultiplier: Double {
        switch self {
        case .main: 1
        case .extra: 0.30
        }
    }

    var patienceMultiplier: Double {
        switch self {
        case .main: 1
        case .extra: 0.70
        }
    }
}

enum StoreItemID: String, CaseIterable, Identifiable, Codable {
    case rentSupport
    case supplyCoupon
    case starterStock
    case dailyBonus
    case eveningTheme
    case rainyTheme

    var id: String { rawValue }
}

enum GameTheme: String, CaseIterable, Identifiable, Codable {
    case morning
    case evening
    case rainy

    var id: String { rawValue }

    var title: String {
        switch self {
        case .morning: "İstanbul Sabahı"
        case .evening: "Boğaz Akşamı"
        case .rainy: "Yağmurlu Sahil"
        }
    }

    var storeSubtitle: String {
        switch self {
        case .morning: "Varsayılan sahil manzarası"
        case .evening: "Sıcak ışıklı akşam atmosferi"
        case .rainy: "Yağmur sonrası serin İstanbul"
        }
    }

    var unlockPrice: Int {
        switch self {
        case .morning: 0
        case .evening: 15_000
        case .rainy: 25_000
        }
    }

    var systemImage: String {
        switch self {
        case .morning: "sun.max.fill"
        case .evening: "sunset.fill"
        case .rainy: "cloud.rain.fill"
        }
    }
}

struct BankruptcySummary: Codable, Equatable {
    let day: Int
    let level: Int
    let debt: Int
}

struct LevelUpPresentation: Equatable {
    let level: Int
    let unlocks: [String]
}

struct AbsenceReport: Codable, Equatable {
    let missedDays: Int
    let chargedDays: Int
    let rentCost: Int
    let reputationLoss: Int
    let spoiledStock: [ProductID: Int]
}

enum PlayerAvatar: String, CaseIterable, Identifiable, Codable {
    case simit
    case tea
    case ferry
    case shop

    var id: String { rawValue }

    var title: String {
        switch self {
        case .simit: "Simitçi"
        case .tea: "Çaycı"
        case .ferry: "İskele"
        case .shop: "Dükkân"
        }
    }

    var systemImage: String {
        switch self {
        case .simit: "circle.hexagongrid.fill"
        case .tea: "cup.and.saucer.fill"
        case .ferry: "ferry.fill"
        case .shop: "storefront.fill"
        }
    }
}

struct EsnafTitle: Equatable {
    let title: String
    let detail: String
    let systemImage: String

    static func title(for level: Int, businessStage: BusinessStage) -> EsnafTitle {
        if level >= 30 {
            return EsnafTitle(title: "İstanbul Simitçisi", detail: "Şehrin tanıdığı büyük esnaf.", systemImage: "crown.fill")
        }

        switch level {
        case 25...:
            return EsnafTitle(title: "İstanbul Esnafı", detail: "Kasa, itibar ve tempo oturdu.", systemImage: "building.2.fill")
        case 20...:
            return EsnafTitle(title: "Dükkân Sahibi", detail: businessStage.title, systemImage: "storefront.fill")
        case 15...:
            return EsnafTitle(title: "Mahalle Ustası", detail: "Müdavim kazanan simitçi.", systemImage: "person.2.fill")
        case 10...:
            return EsnafTitle(title: "Büyük Tabla Sahibi", detail: "Tezgâh büyüyor, risk de büyüyor.", systemImage: "cart.fill")
        case 5...:
            return EsnafTitle(title: "İskele Esnafı", detail: "Kuyruk ve kira yönetimi başladı.", systemImage: "ferry.fill")
        default:
            return EsnafTitle(title: "Çırak Simitçi", detail: "İlk hedef: günü kârda kapat.", systemImage: "circle.hexagongrid.fill")
        }
    }
}

enum DailyTaskID: String, CaseIterable, Identifiable, Codable {
    case serve
    case combo
    case profit

    var id: String { rawValue }
}

struct DailyTaskDefinition: Identifiable, Equatable {
    let id: DailyTaskID
    let title: String
    let detail: String
    let target: Int
    let rewardCash: Int
    let rewardXP: Int
    let systemImage: String
}

struct AchievementProgressItem: Identifiable, Equatable {
    let id: GameCenterAchievementID
    let title: String
    let detail: String
    let systemImage: String
    let current: Int
    let target: Int

    var fraction: Double {
        target > 0 ? min(1, Double(current) / Double(target)) : 0
    }

    var isComplete: Bool {
        current >= target
    }
}

struct GameTelemetry: Codable, Equatable {
    var totalRushes = 0
    var mainRushes = 0
    var extraRushes = 0
    var totalRevenue = 0
    var totalNetProfit = 0
    var extraRevenue = 0
    var extraNetProfit = 0
    var served = 0
    var missed = 0
    var wrong = 0
    var completedOrderSeconds: Double = 0
    var storageCosts = 0
    var spoilageCosts = 0
    var priceAdjustments = 0
    var totalPriceDelta = 0
    var loansTaken = 0
    var totalSimitSold = 0
    var bestCombo = 0
    var debtFreeMainServiceStreak = 0

    var averageOrderSeconds: Double {
        served > 0 ? completedOrderSeconds / Double(served) : 0
    }

    var serviceSuccessRate: Int {
        let total = served + missed + wrong
        return total > 0 ? Int((Double(served) / Double(total) * 100).rounded()) : 0
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        totalRushes = try container.decodeIfPresent(Int.self, forKey: .totalRushes) ?? 0
        mainRushes = try container.decodeIfPresent(Int.self, forKey: .mainRushes) ?? 0
        extraRushes = try container.decodeIfPresent(Int.self, forKey: .extraRushes) ?? 0
        totalRevenue = try container.decodeIfPresent(Int.self, forKey: .totalRevenue) ?? 0
        totalNetProfit = try container.decodeIfPresent(Int.self, forKey: .totalNetProfit) ?? 0
        extraRevenue = try container.decodeIfPresent(Int.self, forKey: .extraRevenue) ?? 0
        extraNetProfit = try container.decodeIfPresent(Int.self, forKey: .extraNetProfit) ?? 0
        served = try container.decodeIfPresent(Int.self, forKey: .served) ?? 0
        missed = try container.decodeIfPresent(Int.self, forKey: .missed) ?? 0
        wrong = try container.decodeIfPresent(Int.self, forKey: .wrong) ?? 0
        completedOrderSeconds = try container.decodeIfPresent(Double.self, forKey: .completedOrderSeconds) ?? 0
        storageCosts = try container.decodeIfPresent(Int.self, forKey: .storageCosts) ?? 0
        spoilageCosts = try container.decodeIfPresent(Int.self, forKey: .spoilageCosts) ?? 0
        priceAdjustments = try container.decodeIfPresent(Int.self, forKey: .priceAdjustments) ?? 0
        totalPriceDelta = try container.decodeIfPresent(Int.self, forKey: .totalPriceDelta) ?? 0
        loansTaken = try container.decodeIfPresent(Int.self, forKey: .loansTaken) ?? 0
        totalSimitSold = try container.decodeIfPresent(Int.self, forKey: .totalSimitSold) ?? 0
        bestCombo = try container.decodeIfPresent(Int.self, forKey: .bestCombo) ?? 0
        debtFreeMainServiceStreak = try container.decodeIfPresent(Int.self, forKey: .debtFreeMainServiceStreak) ?? 0
    }

    mutating func record(report: DayReport, mode: RushMode) {
        totalRushes += 1
        mainRushes += mode == .main ? 1 : 0
        extraRushes += mode == .extra ? 1 : 0
        totalRevenue += report.revenue
        totalNetProfit += report.netProfit
        served += report.served
        missed += report.missed
        wrong += report.wrong
        completedOrderSeconds += report.completedOrderSeconds
        totalSimitSold += report.soldProducts[.simit, default: 0]
        bestCombo = max(bestCombo, report.bestCombo)
        if mode == .extra {
            extraRevenue += report.revenue
            extraNetProfit += report.netProfit
        }
    }
}

enum LoanPlan: String, CaseIterable, Identifiable, Codable {
    case small
    case medium
    case large

    var id: String { title }

    var title: String {
        switch self {
        case .small: "Küçük Kredi"
        case .medium: "Orta Kredi"
        case .large: "Büyük Kredi"
        }
    }

    var cashAmount: Int {
        switch self {
        case .small: 450
        case .medium: 1_100
        case .large: 2_800
        }
    }

    var debtAmount: Int {
        switch self {
        case .small: 520
        case .medium: 1_350
        case .large: 3_500
        }
    }

    var dailyPayment: Int {
        switch self {
        case .small: 40
        case .medium: 85
        case .large: 170
        }
    }

    var requiredLevel: Int {
        switch self {
        case .small: 5
        case .medium: 10
        case .large: 20
        }
    }
}

@MainActor
final class GameSession: ObservableObject {
    @Published var screen: GameScreen = .mainMenu
    @Published var currentDay: Int = 1
    @Published var hasPlayedRushToday: Bool = false
    @Published var hasPlayedExtraServiceToday: Bool = false
    @Published var hasAppliedEndOfDayCostsToday: Bool = false
    @Published var cash: Int = 520
    @Published var level: Int = 1
    @Published var xp: Int = 0
    @Published var reputation: Int = 20
    @Published var stock: StockState = .empty
    @Published var storageStock: StockState = .empty
    @Published var isStorageActivated: Bool = false
    @Published var prices: [ProductID: Int] = Products.basePrices
    @Published var purchasedUpgrades: Set<UpgradeID> = []
    @Published var businessStage: BusinessStage = .smallCart
    @Published var purchasedStoreItems: Set<StoreItemID> = []
    @Published var usedStoreConsumablesToday: Set<StoreItemID> = []
    @Published var supplyCouponCredit: Int = 0
    @Published var activeTheme: GameTheme = .morning
    @Published var debt: Int = 0
    @Published var activeLoanPlan: LoanPlan?
    @Published var lastBankruptcy: BankruptcySummary?
    @Published var lastAbsenceReport: AbsenceReport?
    @Published var lastReport: DayReport?
    @Published var rush: RushEngine?
    @Published var levelUpPresentation: LevelUpPresentation?
    @Published var telemetry = GameTelemetry()
    @Published var playerName: String = "Simitçi"
    @Published var playerAvatar: PlayerAvatar = .simit
    @Published var dailyTaskProgress: [DailyTaskID: Int] = [:]
    @Published var claimedDailyTasks: Set<DailyTaskID> = []
    @Published var lastMainServiceDate: String?

    private var pendingSaveTask: Task<Void, Never>?
    @Published var lastMainServiceAt: TimeInterval?
    @Published private(set) var cloudSaveStatus: CloudSaveStatus = .localOnly
    private var currentRushMode: RushMode = .main
    private var lastVisitDate: String = SaveDateKey.today()
    private let cloudSave = CloudSaveService.shared
    private let gameCenter = GameCenterService.shared
    private let notificationService = NotificationService.shared

    let upgrades: [UpgradeDefinition] = [
        .init(id: .basket, name: "Simit Deposu", detail: "+10 simit kapasitesi", systemImage: "basket.fill", cost: 620, requiredLevel: 3),
        .init(id: .thermos, name: "Büyük Çay Termosu", detail: "+6 çay kapasitesi", systemImage: "cup.and.saucer.fill", cost: 740, requiredLevel: 5),
        .init(id: .packingShelf, name: "Poşet Rafı", detail: "+20 poşet kapasitesi", systemImage: "bag.fill", cost: 520, requiredLevel: 7),
        .init(id: .waterCrate, name: "Su Kasası", detail: "+10 su kapasitesi", systemImage: "waterbottle.fill", cost: 680, requiredLevel: 9),
        .init(id: .awning, name: "Gölgelik Branda", detail: "Müşteri sabrı %15 daha yavaş azalır", systemImage: "sun.max.fill", cost: 980, requiredLevel: 11),
        .init(id: .coldCase, name: "Soğuk Dolap", detail: "+8 ayran ve meyve suyu kapasitesi", systemImage: "snowflake", cost: 1_250, requiredLevel: 14),
        .init(id: .toppingShelf, name: "Ek Malzeme Rafı", detail: "+6 peynir, zeytin ezmesi ve çikolata kapasitesi", systemImage: "cabinet.fill", cost: 1_450, requiredLevel: 20),
        .init(id: .tipJar, name: "Bahşiş Kutusu", detail: "Combo ödemelerine +%5 bonus", systemImage: "banknote.fill", cost: 2_400, requiredLevel: 24),
        .init(id: .supplierDeal, name: "Toptancı Anlaşması", detail: "Ürün alış maliyetleri 1 TL azalır", systemImage: "doc.text.fill", cost: 3_600, requiredLevel: 27),
        .init(id: .brandSign, name: "Altın Tabela", detail: "Marka güveni artar, müşteri sabrı +%4", systemImage: "medal.fill", cost: 18_000, requiredLevel: 30),
        .init(id: .masterStaff, name: "Usta Ekibi", detail: "Combo ödemelerine +%5, günlük bakım +90 TL", systemImage: "person.2.fill", cost: 32_000, requiredLevel: 30),
        .init(id: .cityCampaign, name: "İstanbul Kampanyası", detail: "Her yeni gün itibar +1, günlük reklam +160 TL", systemImage: "megaphone.fill", cost: 50_000, requiredLevel: 30)
    ]

    let districtName = "Vapur İskelesi"
    let marketEvent = "Yağmurlu sabah: çay talebi yüksek"

    var dailyFixedCost: Int {
        fixedCost(for: currentDay)
    }

    var dailyLoanPayment: Int {
        guard debt > 0, let activeLoanPlan else { return 0 }
        return min(debt, activeLoanPlan.dailyPayment)
    }

    var dailyStorageCost: Int {
        guard isStorageUnlocked, isStorageActivated else { return 0 }

        var cost = 16
        if hasUpgrade(.coldCase) { cost += 12 }
        if hasUpgrade(.toppingShelf) { cost += 8 }
        return cost
    }

    var dailyPrestigeCost: Int {
        (hasUpgrade(.masterStaff) ? 90 : 0) + (hasUpgrade(.cityCampaign) ? 160 : 0)
    }

    var dailyTasks: [DailyTaskDefinition] {
        [
            DailyTaskDefinition(
                id: .serve,
                title: "Kuyruğu Erit",
                detail: "Bugün \(dailyTaskTarget(.serve)) doğru servis yap",
                target: dailyTaskTarget(.serve),
                rewardCash: 70 + level * 4,
                rewardXP: 8,
                systemImage: "checkmark.seal.fill"
            ),
            DailyTaskDefinition(
                id: .combo,
                title: "Combo Yakala",
                detail: "En az x\(dailyTaskTarget(.combo)) combo gör",
                target: dailyTaskTarget(.combo),
                rewardCash: 55 + level * 3,
                rewardXP: 10,
                systemImage: "bolt.fill"
            ),
            DailyTaskDefinition(
                id: .profit,
                title: "Kârlı Kapat",
                detail: "Bugün \(dailyTaskTarget(.profit)) TL net kâr yap",
                target: dailyTaskTarget(.profit),
                rewardCash: 90 + level * 5,
                rewardXP: 12,
                systemImage: "banknote.fill"
            )
        ]
    }

    var bankruptcyLimit: Int {
        -(1_000 + max(0, level - 1) * 90)
    }

    var esnafTitle: EsnafTitle {
        EsnafTitle.title(for: level, businessStage: businessStage)
    }

    var esnafScore: Int {
        let bestDayScore = max(0, lastReport?.score ?? 0)
        let revenueScore = max(0, cash)
        let serviceScore = telemetry.served * 60
        let reputationScore = reputation * 1_200
        let levelScore = level * 2_500
        let dayScore = currentDay * 600
        let bestDayBonus = bestDayScore * 5
        let debtFreeBonus = debt == 0 ? min(50_000, currentDay * 500 + level * 900) : 0
        let debtPenalty = debt * 2

        return max(0, revenueScore + serviceScore + reputationScore + levelScore + dayScore + bestDayBonus + debtFreeBonus - debtPenalty)
    }

    var achievementProgress: [AchievementProgressItem] {
        [
            AchievementProgressItem(
                id: .debtFreeSevenDays,
                title: "Borçsuz 7 Gün",
                detail: "Ana servisleri borçsuz kapat.",
                systemImage: "checkmark.shield.fill",
                current: min(7, telemetry.debtFreeMainServiceStreak),
                target: 7
            ),
            AchievementProgressItem(
                id: .hundredSimitSold,
                title: "100 Simit Satıldı",
                detail: "Toplam simit satışını büyüt.",
                systemImage: "seal.fill",
                current: min(100, telemetry.totalSimitSold),
                target: 100
            ),
            AchievementProgressItem(
                id: .firstComboFive,
                title: "İlk Combo x5",
                detail: "Bir serviste x5 combo yakala.",
                systemImage: "bolt.fill",
                current: min(5, telemetry.bestCombo),
                target: 5
            ),
            AchievementProgressItem(
                id: .istanbulSimitcisi,
                title: "İstanbul Simitçisi",
                detail: "Lv 30'a ulaşıp şehrin simitçisi ol.",
                systemImage: "crown.fill",
                current: min(GameProgression.maxLevel, level),
                target: GameProgression.maxLevel
            )
        ]
    }

    var canPrepareNextDay: Bool {
        hasPlayedRushToday && lastMainServiceDate != SaveDateKey.today()
    }

    var nextServiceLockText: String {
        canPrepareNextDay ? "Yeni gün hazır." : "Bugünün ana servisi bitti. Yeni servis yarın açılır."
    }

    init() {
        load()
        evaluateAbsenceOnLaunch()
    }

    func refreshForForeground() {
        guard screen != .rush else {
            refreshNotificationReminders()
            return
        }

        evaluateAbsenceOnLaunch()
    }

    var availableProducts: [ProductDefinition] {
        Products.all.filter { isProductUnlocked($0.id) }
    }

    func openPrep() {
        screen = .prep
    }

    func startRush(mode: RushMode = .main) {
        guard canStartRush(mode) else {
            GameAudio.shared.play(.denied, volume: 0.48)
            return
        }

        let engine = RushEngine(
            startingStock: stock,
            prices: prices,
            buyCosts: buyCosts,
            availableProducts: availableProducts.map(\.id),
            duration: mode.duration,
            patienceMultiplier: patienceMultiplier * mode.patienceMultiplier,
            comboPayoutBonus: comboPayoutBonus,
            reputation: reputation,
            pricePressure: pricePressure
        )
        currentRushMode = mode
        rush = engine
        screen = .rush
        engine.start()
    }

    func finishRush() {
        guard let rush else { return }
        let mode = currentRushMode
        let startedMainServiceDebtFree = mode == .main && debt == 0
        let report = rush.makeReport(
            dailyFixedCost: mode == .main ? dailyFixedCost : mode.fixedCost,
            loanPayment: mode == .main ? dailyLoanPayment : 0,
            xpMultiplier: mode.xpMultiplier,
            extraReputationRisk: mode == .extra
        )
        telemetry.record(report: report, mode: mode)
        let previousLevel = level
        let dailyReport = mode == .extra ? lastReport?.merged(with: report) ?? report : report
        lastReport = dailyReport
        stock = rush.stock
        cash += report.cashDelta
        debt = max(0, debt - report.loanPayment)
        if debt == 0 {
            activeLoanPlan = nil
        }
        if mode == .main {
            telemetry.debtFreeMainServiceStreak = startedMainServiceDebtFree && debt == 0 ? telemetry.debtFreeMainServiceStreak + 1 : 0
        }
        xp += report.xpEarned
        level = GameProgression.level(for: xp)
        applyLevelRewards(from: previousLevel, to: level)
        if level > previousLevel {
            levelUpPresentation = LevelUpPresentation(level: level, unlocks: unlocks(reachedFrom: previousLevel, to: level))
            GameAudio.shared.play(.levelUp, volume: 0.72)
        }
        reputation = max(0, min(100, reputation + report.reputationDelta))
        if mode == .main {
            hasPlayedRushToday = true
            lastMainServiceDate = SaveDateKey.today()
            lastMainServiceAt = Date().timeIntervalSince1970
        } else {
            hasPlayedExtraServiceToday = true
        }
        updateDailyTasks(with: report)
        submitGameCenterScores(bestDayScore: dailyReport.score)
        submitGameCenterAchievements()
        self.rush = nil
        if cash <= bankruptcyLimit {
            triggerBankruptcy()
        } else {
            screen = .report
        }
        save()
    }

    func openGameCenterLeaderboards() {
        gameCenter.showLeaderboards()
    }

    func authenticateGameCenter() {
        gameCenter.authenticate()
    }

    func refreshNotificationReminders() {
        let remindersEnabled = UserDefaults.standard.object(forKey: "simitci-rush-notifications-enabled") as? Bool
            ?? UserDefaults.standard.object(forKey: "simitci-rush-notes-enabled") as? Bool
            ?? true
        notificationService.scheduleGameReminders(
            enabled: remindersEnabled,
            hasPlayedMainService: hasPlayedRushToday || lastMainServiceDate == SaveDateKey.today(),
            hasExtraServiceAvailable: hasExtraServiceOpportunity || hasPendingExtraServiceOpportunity,
            extraServiceUnlockDate: extraServiceUnlockDate,
            hasClaimableDailyReward: hasClaimableDailyReward
        )
    }

    func updatePlayerName(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        playerName = String(trimmed.isEmpty ? "Simitçi" : trimmed.prefix(18))
        save()
    }

    func selectAvatar(_ avatar: PlayerAvatar) {
        playerAvatar = avatar
        save()
    }

    func progress(for task: DailyTaskDefinition) -> Int {
        min(task.target, dailyTaskProgress[task.id, default: 0])
    }

    func canClaimDailyTask(_ task: DailyTaskDefinition) -> Bool {
        progress(for: task) >= task.target && !claimedDailyTasks.contains(task.id)
    }

    var hasClaimableDailyReward: Bool {
        dailyTasks.contains { canClaimDailyTask($0) }
    }

    func claimDailyTask(_ task: DailyTaskDefinition) {
        guard canClaimDailyTask(task) else {
            GameAudio.shared.play(.denied, volume: 0.45)
            return
        }
        claimedDailyTasks.insert(task.id)
        cash += task.rewardCash
        xp += task.rewardXP
        let previousLevel = level
        level = GameProgression.level(for: xp)
        applyLevelRewards(from: previousLevel, to: level)
        if level > previousLevel {
            levelUpPresentation = LevelUpPresentation(level: level, unlocks: unlocks(reachedFrom: previousLevel, to: level))
            GameAudio.shared.play(.levelUp, volume: 0.72)
        } else {
            GameAudio.shared.play(.upgrade, volume: 0.44)
        }
        submitGameCenterAchievements()
        save()
    }

    func canStartRush(_ mode: RushMode) -> Bool {
        switch mode {
        case .main:
            return !hasPlayedRushToday && lastMainServiceDate != SaveDateKey.today() && hasSimitOnStand
        case .extra:
            return hasExtraServiceOpportunity
        }
    }

    func backHome() {
        screen = .home
    }

    func openMainMenu() {
        screen = .mainMenu
    }

    func openIntroStory() {
        screen = .introStory
    }

    func openMarket() {
        guard canOpenManagementAfterService else {
            openPostServiceDecision()
            return
        }
        screen = .market
    }

    func openStore() {
        screen = .store
    }

    func openSettings() {
        screen = .settings
    }

    func openUpgrades() {
        openMarket()
    }

    func openProfile() {
        screen = .profile
    }

    func openDayClose() {
        applyEndOfDayCostsIfNeeded()
        if cash <= bankruptcyLimit {
            triggerBankruptcy()
            save()
            return
        }
        screen = .dayClose
        save()
    }

    func dismissAbsenceReport() {
        lastAbsenceReport = nil
        if cash <= bankruptcyLimit {
            triggerBankruptcy()
        } else {
            screen = .mainMenu
        }
        save()
    }

    func takeLoan(_ plan: LoanPlan) {
        guard canTakeLoan(plan) else {
            GameAudio.shared.play(.denied, volume: 0.55)
            return
        }
        cash += plan.cashAmount
        debt += plan.debtAmount
        activeLoanPlan = plan
        telemetry.loansTaken += 1
        GameAudio.shared.play(.loan, volume: 0.68)
        save()
    }

    func canTakeLoan(_ plan: LoanPlan) -> Bool {
        debt == 0 && level >= plan.requiredLevel && plan.debtAmount <= loanLimit
    }

    func buyStoreItem(_ item: StoreItemID) {
        guard canUseStoreItem(item) else {
            GameAudio.shared.play(.denied, volume: 0.48)
            return
        }
        let cost = storeItemCost(item)
        if cost > 0 {
            cash -= cost
        }

        switch item {
        case .rentSupport:
            cash += max(55, Int((Double(dailyFixedCost) * 0.45).rounded()))
            usedStoreConsumablesToday.insert(item)
        case .supplyCoupon:
            supplyCouponCredit += 120
            usedStoreConsumablesToday.insert(item)
        case .starterStock:
            addStockBonus(StockState(quantities: Self.starterStockBonus))
            usedStoreConsumablesToday.insert(item)
        case .dailyBonus:
            cash += 145
            reputation = min(100, reputation + 1)
            usedStoreConsumablesToday.insert(item)
        case .eveningTheme:
            purchasedStoreItems.insert(.eveningTheme)
            activeTheme = .evening
        case .rainyTheme:
            purchasedStoreItems.insert(.rainyTheme)
            activeTheme = .rainy
        }
        save()
    }

    func canUseStoreItem(_ item: StoreItemID) -> Bool {
        switch item {
        case .rentSupport, .supplyCoupon, .dailyBonus:
            !usedStoreConsumablesToday.contains(item) && cash >= storeItemCost(item)
        case .starterStock:
            !usedStoreConsumablesToday.contains(item) && cash >= storeItemCost(item) && canReceiveStarterStock
        case .eveningTheme, .rainyTheme:
            purchasedStoreItems.contains(item)
        }
    }

    var canReceiveStarterStock: Bool {
        Self.starterStockBonus.contains { product, _ in
            stock.quantity(for: product) < stockCapacity(for: product)
        }
    }

    func storeItemCost(_ item: StoreItemID) -> Int {
        switch item {
        case .rentSupport:
            max(45, Int((Double(dailyFixedCost) * 0.35).rounded()))
        case .supplyCoupon:
            75
        case .starterStock:
            145
        case .dailyBonus:
            110
        case .eveningTheme, .rainyTheme:
            0
        }
    }

    func isThemeUnlocked(_ theme: GameTheme) -> Bool {
        theme == .morning || purchasedStoreItems.contains(theme.storeItem)
    }

    func canUnlockTheme(_ theme: GameTheme) -> Bool {
        theme != .morning && !isThemeUnlocked(theme) && cash >= theme.unlockPrice
    }

    func unlockTheme(_ theme: GameTheme) {
        guard canUnlockTheme(theme) else {
            GameAudio.shared.play(.denied, volume: 0.50)
            return
        }
        cash -= theme.unlockPrice
        purchasedStoreItems.insert(theme.storeItem)
        activeTheme = theme
        GameAudio.shared.play(.upgrade, volume: 0.58)
        save()
    }

    func selectTheme(_ theme: GameTheme) {
        guard isThemeUnlocked(theme) else {
            GameAudio.shared.play(.denied, volume: 0.50)
            return
        }
        activeTheme = theme
        save()
    }

    func activateTheme(_ theme: GameTheme) {
        selectTheme(theme)
    }

    func restartDay() {
        guard canPrepareNextDay else {
            GameAudio.shared.play(.denied, volume: 0.48)
            return
        }

        applyEndOfDayCostsIfNeeded()

        if cash <= bankruptcyLimit {
            triggerBankruptcy()
            save()
            return
        }

        currentDay += 1
        hasPlayedRushToday = false
        hasPlayedExtraServiceToday = false
        hasAppliedEndOfDayCostsToday = false
        usedStoreConsumablesToday = []
        supplyCouponCredit = 0
        dailyTaskProgress = [:]
        claimedDailyTasks = []
        lastMainServiceDate = nil
        lastMainServiceAt = nil
        if hasUpgrade(.cityCampaign) {
            reputation = min(100, reputation + 1)
        }
        stock = stockClampedToCapacity(stock)
        screen = .home
        save()
    }

    func price(for product: ProductID) -> Int {
        prices[product, default: Products.definition(for: product).sellPrice]
    }

    func adjustPrice(for product: ProductID, by delta: Int) {
        let definition = Products.definition(for: product)
        let minimum = definition.buyCost + 1
        let maximum = definition.maximumSellPrice
        let previousPrice = price(for: product)
        let adjustedPrice = min(maximum, max(minimum, previousPrice + delta))
        prices[product] = adjustedPrice
        if adjustedPrice != previousPrice {
            telemetry.priceAdjustments += 1
            telemetry.totalPriceDelta += adjustedPrice - previousPrice
        }
        save()
    }

    func fixedCost(for day: Int) -> Int {
        let monthIndex = min(10, max(0, (day - 1) / 30))
        let rent = Int((120.0 * pow(1.08, Double(monthIndex)) * businessStage.rentMultiplier).rounded())
        return rent + dailyPrestigeCost
    }

    func stockCapacity(for product: ProductID) -> Int {
        guard isProductUnlocked(product) else { return 0 }

        let base = baseCapacity(for: product) + businessStage.capacityBonus
        switch product {
        case .simit:
            return base + (hasUpgrade(.basket) ? 10 : 0)
        case .acma, .oliveAcma, .cheesePogaca:
            return base + (hasUpgrade(.basket) ? 4 : 0)
        case .tea:
            return base + (hasUpgrade(.thermos) ? 6 : 0)
        case .water:
            return base + (hasUpgrade(.waterCrate) ? 10 : 0)
        case .ayran, .juiceBox:
            return base + (hasUpgrade(.coldCase) ? 8 : 0)
        case .bag:
            return base + (hasUpgrade(.packingShelf) ? 20 : 0)
        case .cheese, .olivePaste, .chocolate:
            return base + (hasUpgrade(.toppingShelf) ? 6 : 0)
        }
    }

    func storageCapacity(for product: ProductID) -> Int {
        guard isProductUnlocked(product), isStorageUnlocked else { return 0 }

        let base = max(4, baseCapacity(for: product))
        switch product {
        case .simit:
            return base + 20 + (hasUpgrade(.basket) ? 16 : 0)
        case .acma, .oliveAcma, .cheesePogaca:
            return base + 8 + (hasUpgrade(.basket) ? 8 : 0)
        case .tea:
            return base + 12 + (hasUpgrade(.thermos) ? 10 : 0)
        case .water:
            return base + 16 + (hasUpgrade(.waterCrate) ? 14 : 0)
        case .ayran, .juiceBox:
            return base + 10 + (hasUpgrade(.coldCase) ? 12 : 0)
        case .bag:
            return base + 40 + (hasUpgrade(.packingShelf) ? 30 : 0)
        case .cheese, .olivePaste, .chocolate:
            return base + 8 + (hasUpgrade(.toppingShelf) ? 10 : 0)
        }
    }

    func buyStock(_ product: ProductID, amount: Int) {
        guard isProductUnlocked(product) else {
            GameAudio.shared.play(.denied, volume: 0.48)
            return
        }

        let current = isStorageUnlocked ? storageStock.quantity(for: product) : stock.quantity(for: product)
        let capacity = isStorageUnlocked ? storageCapacity(for: product) : stockCapacity(for: product)
        let availableSpace = capacity - current
        let quantity = min(amount, max(0, availableSpace))
        let cost = quantity * buyCost(for: product)
        let couponDiscount = min(supplyCouponCredit, cost)
        let payableCost = cost - couponDiscount

        guard quantity > 0, cash >= payableCost else {
            GameAudio.shared.play(.denied, volume: 0.48)
            return
        }

        cash -= payableCost
        supplyCouponCredit -= couponDiscount
        if isStorageUnlocked {
            isStorageActivated = true
            storageStock.quantities[product, default: 0] = current + quantity
        } else {
            stock.quantities[product, default: 0] = current + quantity
        }
        if pendingSaveTask == nil {
            GameAudio.shared.play(.coin, volume: 0.30)
        }
        saveSoon()
    }

    func transferFromStorageToStand(_ product: ProductID, amount: Int) {
        guard isStorageUnlocked, isProductUnlocked(product) else { return }

        let standCurrent = stock.quantity(for: product)
        let storageCurrent = storageStock.quantity(for: product)
        let availableSpace = stockCapacity(for: product) - standCurrent
        let quantity = min(amount, storageCurrent, max(0, availableSpace))
        guard quantity > 0 else { return }

        storageStock.quantities[product, default: 0] = storageCurrent - quantity
        stock.quantities[product, default: 0] = standCurrent + quantity
        save()
    }

    func transferFromStandToStorage(_ product: ProductID, amount: Int) {
        guard isStorageUnlocked, isProductUnlocked(product) else { return }

        let standCurrent = stock.quantity(for: product)
        let storageCurrent = storageStock.quantity(for: product)
        let availableSpace = storageCapacity(for: product) - storageCurrent
        let quantity = min(amount, standCurrent, max(0, availableSpace))
        guard quantity > 0 else { return }

        isStorageActivated = true
        stock.quantities[product, default: 0] = standCurrent - quantity
        storageStock.quantities[product, default: 0] = storageCurrent + quantity
        save()
    }

    func buyUpgrade(_ upgrade: UpgradeDefinition) {
        guard canBuyUpgrade(upgrade) else {
            GameAudio.shared.play(.denied, volume: 0.48)
            return
        }

        cash -= upgrade.cost
        purchasedUpgrades.insert(upgrade.id)
        if upgrade.id == .brandSign {
            reputation = min(100, reputation + 5)
        }
        stock = stockClampedToCapacity(stock)
        storageStock = storageClampedToCapacity(storageStock)
        GameAudio.shared.play(.upgrade, volume: 0.72)
        save()
    }

    func hasUpgrade(_ id: UpgradeID) -> Bool {
        purchasedUpgrades.contains(id)
    }

    func canBuyUpgrade(_ upgrade: UpgradeDefinition) -> Bool {
        !hasUpgrade(upgrade.id)
            && level >= upgrade.requiredLevel
            && hasRequiredBusinessStage(for: upgrade)
            && cash >= upgrade.cost
    }

    func requiredBusinessStage(for upgrade: UpgradeDefinition) -> BusinessStage? {
        switch upgrade.id {
        case .toppingShelf:
            return .shop
        case .brandSign, .masterStaff, .cityCampaign:
            return .istanbulSimitci
        case .basket, .thermos, .packingShelf, .waterCrate, .coldCase, .awning, .tipJar, .supplierDeal:
            return nil
        }
    }

    func hasRequiredBusinessStage(for upgrade: UpgradeDefinition) -> Bool {
        guard let required = requiredBusinessStage(for: upgrade) else { return true }
        return businessStage.requiredLevel >= required.requiredLevel
    }

    func canBuyBusinessStage(_ stage: BusinessStage) -> Bool {
        guard stage != businessStage, let previous = stage.previous else { return false }
        return businessStage == previous && level >= stage.requiredLevel && cash >= stage.cost
    }

    func buyBusinessStage(_ stage: BusinessStage) {
        guard canBuyBusinessStage(stage) else {
            GameAudio.shared.play(.denied, volume: 0.48)
            return
        }

        cash -= stage.cost
        businessStage = stage
        stock = stockClampedToCapacity(stock)
        storageStock = storageClampedToCapacity(storageStock)
        GameAudio.shared.play(.upgrade, volume: 0.76)
        save()
    }

    func isProductUnlocked(_ product: ProductID) -> Bool {
        level >= Products.definition(for: product).unlockLevel
    }

    func buyCost(for product: ProductID) -> Int {
        max(1, Products.definition(for: product).buyCost - (hasUpgrade(.supplierDeal) ? 1 : 0))
    }

    var cartLevelName: String {
        businessStage.title
    }

    var xpForNextLevel: Int? {
        GameProgression.xpForNextLevel(currentLevel: level)
    }

    var isStorageUnlocked: Bool {
        level >= GameProgression.storageUnlockLevel
    }

    var hasSellableStandStock: Bool {
        availableProducts.contains { stock.quantity(for: $0.id) > 0 }
    }

    var hasSimitOnStand: Bool {
        stock.quantity(for: .simit) > 0
    }

    var hasExtraServiceOpportunity: Bool {
        hasQualifiedExtraServiceOpportunity && isExtraServiceUnlocked
    }

    var hasPendingExtraServiceOpportunity: Bool {
        hasQualifiedExtraServiceOpportunity && !isExtraServiceUnlocked
    }

    var extraServiceUnlockDate: Date? {
        guard let lastMainServiceAt else { return nil }
        return Date(timeIntervalSince1970: lastMainServiceAt + Self.extraServiceDelay)
    }

    private var hasQualifiedExtraServiceOpportunity: Bool {
        guard
            hasPlayedRushToday,
            !hasPlayedExtraServiceToday,
            !hasAppliedEndOfDayCostsToday,
            hasSimitOnStand,
            let report = lastReport
        else { return false }

        let mistakes = report.missed + report.wrong
        return report.served >= 5 && report.happiness >= 45 && mistakes <= max(3, report.served)
    }

    private var isExtraServiceUnlocked: Bool {
        guard let extraServiceUnlockDate else { return true }
        return Date() >= extraServiceUnlockDate
    }

    var extraServiceOpportunityText: String {
        guard hasPlayedRushToday, !hasPlayedExtraServiceToday, !hasAppliedEndOfDayCostsToday else {
            return "Bugünün ek servis fırsatı kapandı."
        }

        guard hasSimitOnStand else {
            return "Ek servis için tezgahta simit kalmalı."
        }

        guard let report = lastReport else {
            return "Ana servis raporu bekleniyor."
        }

        let mistakes = report.missed + report.wrong
        if report.served < 5 {
            return "Ek servis için önce ana serviste biraz daha kuyruk eritmen gerekir."
        }
        if report.happiness < 45 {
            return "Müşteri memnuniyeti düşük; bugün tezgâhı kapatmak daha doğru."
        }
        if mistakes > max(3, report.served) {
            return "Kaçan ve yanlış servis çok arttı; ek servis bugün riskli."
        }

        if let extraServiceUnlockDate, !isExtraServiceUnlocked {
            return "Ek servis \(extraServiceUnlockDate.formatted(date: .omitted, time: .shortened)) saatinde açılır. Hazır olduğunda bildirim gelir."
        }

        return "Kuyruk hâlâ sıcak. İstersen kısa ve riskli bir ek servis açabilirsin."
    }

    var canOpenManagementAfterService: Bool {
        !hasPlayedRushToday || hasAppliedEndOfDayCostsToday
    }

    var loanLimit: Int {
        1_200 + level * 140
    }

    private var buyCosts: [ProductID: Int] {
        Dictionary(uniqueKeysWithValues: Products.all.map { ($0.id, buyCost(for: $0.id)) })
    }

    private func openPostServiceDecision() {
        if hasQualifiedExtraServiceOpportunity {
            screen = .report
        } else {
            openDayClose()
        }
    }


    private static let extraServiceDelay: TimeInterval = 6 * 60 * 60
    private static let starterStockBonus: [ProductID: Int] = [.simit: 8, .tea: 4, .water: 4, .bag: 8]

    private var patienceMultiplier: Double {
        let upgradeMultiplier = (hasUpgrade(.awning) ? 1.15 : 1) * (hasUpgrade(.brandSign) ? 1.04 : 1)
        let reputationMultiplier: Double
        switch reputation {
        case 80...100:
            reputationMultiplier = 1.08
        case 50..<80:
            reputationMultiplier = 1.0
        case 20..<50:
            reputationMultiplier = 0.94
        default:
            reputationMultiplier = 0.84
        }
        return upgradeMultiplier * reputationMultiplier * businessStage.servicePatienceMultiplier
    }

    private var comboPayoutBonus: Double {
        (hasUpgrade(.tipJar) ? 0.05 : 0) + (hasUpgrade(.masterStaff) ? 0.05 : 0)
    }

    private var pricePressure: Int {
        Products.all.reduce(0) { total, product in
            guard isProductUnlocked(product.id) else { return total }
            let overBase = max(0, price(for: product.id) - product.sellPrice)
            return total + (product.id.isAddOn ? overBase / 2 : overBase)
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

    private func applyLevelRewards(from oldLevel: Int, to newLevel: Int) {
        guard newLevel > oldLevel else { return }

        for reachedLevel in (oldLevel + 1)...newLevel {
            addStockBonus(GameProgression.milestoneBonus(for: reachedLevel))

            if reachedLevel % 5 == 0 {
                cash += 75 + reachedLevel * 8
            }
        }
    }

    private func addStockBonus(_ bonus: StockState) {
        for product in ProductID.allCases {
            let current = stock.quantity(for: product)
            let added = bonus.quantity(for: product)
            guard added > 0 else { continue }
            stock.quantities[product, default: 0] = min(stockCapacity(for: product), current + added)
        }
    }

    private func triggerBankruptcy() {
        lastBankruptcy = BankruptcySummary(day: currentDay, level: level, debt: cash)
        resetRunState()
        screen = .bankruptcy
        GameAudio.shared.play(.bankruptcy, volume: 0.78)
    }

    private func unlocks(reachedFrom oldLevel: Int, to newLevel: Int) -> [String] {
        var results: [String] = []

        if oldLevel < GameProgression.storageUnlockLevel, newLevel >= GameProgression.storageUnlockLevel {
            results.append("Depo yönetimi açıldı")
        }

        results += Products.all
            .filter { $0.unlockLevel > oldLevel && $0.unlockLevel <= newLevel }
            .map { "\($0.name) satışa açıldı" }

        results += upgrades
            .filter { $0.requiredLevel > oldLevel && $0.requiredLevel <= newLevel }
            .map { "\($0.name) geliştirilebilir" }

        results += LoanPlan.allCases
            .filter { $0.requiredLevel > oldLevel && $0.requiredLevel <= newLevel }
            .map { "\($0.title) açıldı" }

        results += BusinessStage.allCases
            .filter { $0.requiredLevel > oldLevel && $0.requiredLevel <= newLevel }
            .map { "\($0.title) satın alınabilir" }

        if newLevel % 5 == 0 {
            results.append("Seviye kasa bonusu alındı")
        }

        return results.isEmpty ? ["Yeni stok bonusu tezgâha eklendi"] : results
    }

    func resetGame() {
        lastBankruptcy = nil
        lastAbsenceReport = nil
        resetRunState()
        screen = .introStory
        save()
    }

    private func resetRunState() {
        currentDay = 1
        hasPlayedRushToday = false
        hasPlayedExtraServiceToday = false
        hasAppliedEndOfDayCostsToday = false
        cash = 520
        level = 1
        xp = 0
        reputation = 20
        stock = .empty
        storageStock = .empty
        isStorageActivated = false
        prices = Products.basePrices
        purchasedUpgrades = []
        businessStage = .smallCart
        purchasedStoreItems = []
        usedStoreConsumablesToday = []
        supplyCouponCredit = 0
        activeTheme = .morning
        debt = 0
        activeLoanPlan = nil
        lastReport = nil
        telemetry = GameTelemetry()
        playerName = "Simitçi"
        playerAvatar = .simit
        dailyTaskProgress = [:]
        claimedDailyTasks = []
        lastMainServiceDate = nil
        lastMainServiceAt = nil
    }

    private func stockClampedToCapacity(_ source: StockState) -> StockState {
        var result = source
        for product in ProductID.allCases {
            result.quantities[product, default: 0] = isProductUnlocked(product) ? min(source.quantity(for: product), stockCapacity(for: product)) : 0
        }
        return result
    }

    private func storageClampedToCapacity(_ source: StockState) -> StockState {
        var result = source
        for product in ProductID.allCases {
            result.quantities[product, default: 0] = isProductUnlocked(product) ? min(source.quantity(for: product), storageCapacity(for: product)) : 0
        }
        return result
    }

    private func applyEndOfDayCostsIfNeeded() {
        guard hasPlayedRushToday, !hasAppliedEndOfDayCostsToday, let report = lastReport else { return }

        let storageCost = dailyStorageCost
        let spoiledStock = gameDaySpoiledStockLoss()
        let spoilageCost = spoiledStock.reduce(0) { total, item in
            total + item.value * buyCost(for: item.key)
        }

        for (product, quantity) in spoiledStock {
            let standLoss = min(stock.quantity(for: product), quantity)
            stock.quantities[product, default: 0] = max(0, stock.quantity(for: product) - standLoss)
            let remainingLoss = quantity - standLoss
            if remainingLoss > 0 {
                storageStock.quantities[product, default: 0] = max(0, storageStock.quantity(for: product) - remainingLoss)
            }
        }

        if storageCost > 0 {
            cash -= storageCost
        }
        telemetry.storageCosts += storageCost
        telemetry.spoilageCosts += spoilageCost
        telemetry.totalNetProfit -= storageCost + spoilageCost

        lastReport = report.applyingEndOfDayCosts(
            storageCost: storageCost,
            spoilageCost: spoilageCost,
            spoiledStock: spoiledStock
        )
        hasAppliedEndOfDayCostsToday = true
    }

    private func gameDaySpoiledStockLoss() -> [ProductID: Int] {
        let products: [ProductID] = [.tea, .ayran, .acma, .oliveAcma, .cheesePogaca, .juiceBox, .cheese, .olivePaste, .chocolate]
        var result: [ProductID: Int] = [:]

        for product in products where isProductUnlocked(product) {
            let total = stock.quantity(for: product) + storageStock.quantity(for: product)
            guard total >= 4 else { continue }

            let ratio = gameDaySpoilageRatio(for: product)
            let loss = min(total, max(0, Int((Double(total) * ratio).rounded())))
            if loss > 0 {
                result[product] = min(4, loss)
            }
        }

        return result
    }

    private func gameDaySpoilageRatio(for product: ProductID) -> Double {
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

        if [.ayran, .juiceBox].contains(product), hasUpgrade(.coldCase) {
            return base * 0.45
        }
        if product.isAddOn, hasUpgrade(.toppingShelf) {
            return base * 0.60
        }
        return base
    }

    private func evaluateAbsenceOnLaunch() {
        defer {
            lastVisitDate = SaveDateKey.today()
            save()
        }

        if lastAbsenceReport != nil {
            screen = .absenceReport
            return
        }

        guard let missedDays = missedCalendarDays(since: lastVisitDate), missedDays > 0 else { return }

        let chargedDays = min(missedDays, 3)
        let rentCost = dailyFixedCost * chargedDays
        let reputationLoss = min(6, missedDays)
        let spoiledStock = spoiledStockLoss(for: missedDays)

        cash -= rentCost
        reputation = max(0, reputation - reputationLoss)
        for (product, quantity) in spoiledStock {
            let standLoss = min(stock.quantity(for: product), quantity)
            stock.quantities[product, default: 0] = max(0, stock.quantity(for: product) - standLoss)
            let remainingLoss = quantity - standLoss
            if remainingLoss > 0 {
                storageStock.quantities[product, default: 0] = max(0, storageStock.quantity(for: product) - remainingLoss)
            }
        }

        lastAbsenceReport = AbsenceReport(
            missedDays: missedDays,
            chargedDays: chargedDays,
            rentCost: rentCost,
            reputationLoss: reputationLoss,
            spoiledStock: spoiledStock
        )
        screen = .absenceReport
    }

    private func missedCalendarDays(since savedDate: String) -> Int? {
        guard
            let previous = SaveDateKey.date(from: savedDate),
            let today = SaveDateKey.date(from: SaveDateKey.today())
        else { return nil }

        let previousStart = Calendar.current.startOfDay(for: previous)
        let todayStart = Calendar.current.startOfDay(for: today)
        let elapsedDays = Calendar.current.dateComponents([.day], from: previousStart, to: todayStart).day ?? 0
        return max(0, elapsedDays - 1)
    }

    private func spoiledStockLoss(for missedDays: Int) -> [ProductID: Int] {
        let spoilableProducts: [ProductID] = [.tea, .ayran, .acma, .oliveAcma, .cheesePogaca, .juiceBox, .cheese, .olivePaste, .chocolate]
        var result: [ProductID: Int] = [:]

        for product in spoilableProducts where isProductUnlocked(product) {
            let current = stock.quantity(for: product)
            let stored = storageStock.quantity(for: product)
            let total = current + stored
            guard total > 0 else { continue }
            let ratio = min(0.35, 0.12 * Double(missedDays))
            let loss = min(total, max(1, Int((Double(total) * ratio).rounded())))
            result[product] = loss
        }

        return result
    }

    private func saveSoon() {
        pendingSaveTask?.cancel()
        pendingSaveTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            self?.saveNow()
            self?.pendingSaveTask = nil
        }
    }

    private func save() {
        pendingSaveTask?.cancel()
        pendingSaveTask = nil
        saveNow()
    }

    private func saveNow() {
        let state = GameSaveState(
            currentDay: currentDay,
            hasPlayedRushToday: hasPlayedRushToday,
            hasPlayedExtraServiceToday: hasPlayedExtraServiceToday,
            hasAppliedEndOfDayCostsToday: hasAppliedEndOfDayCostsToday,
            cash: cash,
            level: level,
            xp: xp,
            reputation: reputation,
            stock: stock,
            storageStock: storageStock,
            isStorageActivated: isStorageActivated,
            prices: prices,
            purchasedUpgrades: purchasedUpgrades,
            businessStage: businessStage,
            purchasedStoreItems: purchasedStoreItems,
            usedStoreConsumablesToday: usedStoreConsumablesToday,
            supplyCouponCredit: supplyCouponCredit,
            activeTheme: activeTheme,
            debt: debt,
            activeLoanPlan: activeLoanPlan,
            lastBankruptcy: lastBankruptcy,
            lastAbsenceReport: lastAbsenceReport,
            lastReport: lastReport,
            telemetry: telemetry,
            playerName: playerName,
            playerAvatar: playerAvatar,
            dailyTaskProgress: dailyTaskProgress,
            claimedDailyTasks: claimedDailyTasks,
            lastMainServiceDate: lastMainServiceDate,
            lastMainServiceAt: lastMainServiceAt
        )

        guard let data = try? JSONEncoder().encode(state) else { return }
        UserDefaults.standard.set(data, forKey: GameSaveState.storageKey)
        cloudSaveStatus = cloudSave.save(data: data, for: GameSaveState.storageKey) ? .synced : .localOnly
        refreshNotificationReminders()
    }

    private func submitGameCenterScores(bestDayScore: Int) {
        gameCenter.submit(
            GameCenterScores(
                esnafScore: esnafScore,
                cash: cash,
                bestDay: bestDayScore,
                days: currentDay
            )
        )
    }

    private func submitGameCenterAchievements() {
        gameCenter.submitAchievements([
            GameCenterAchievementProgress(
                id: .debtFreeSevenDays,
                percent: Double(min(7, telemetry.debtFreeMainServiceStreak)) / 7 * 100
            ),
            GameCenterAchievementProgress(
                id: .hundredSimitSold,
                percent: Double(min(100, telemetry.totalSimitSold))
            ),
            GameCenterAchievementProgress(
                id: .firstComboFive,
                percent: Double(min(5, telemetry.bestCombo)) / 5 * 100
            ),
            GameCenterAchievementProgress(
                id: .istanbulSimitcisi,
                percent: level >= 30 ? 100 : Double(level) / 30 * 100
            )
        ])
    }

    private func load() {
        let localData = UserDefaults.standard.data(forKey: GameSaveState.storageKey)
        let localState = localData.flatMap { try? JSONDecoder().decode(GameSaveState.self, from: $0) }
        let cloudData = cloudSave.data(for: GameSaveState.storageKey)
        let cloudState = cloudData.flatMap { try? JSONDecoder().decode(GameSaveState.self, from: $0) }

        switch (localState, cloudState) {
        case let (local?, cloud?) where cloud.savedAt > local.savedAt:
            applySavedState(cloud)
            if let cloudData {
                UserDefaults.standard.set(cloudData, forKey: GameSaveState.storageKey)
            }
            cloudSaveStatus = .restoredFromCloud
        case let (local?, cloud?):
            applySavedState(local)
            if local.savedAt > cloud.savedAt, let localData {
                cloudSaveStatus = cloudSave.save(data: localData, for: GameSaveState.storageKey) ? .synced : .localOnly
            } else {
                cloudSaveStatus = cloudSave.isAvailable ? .synced : .localOnly
            }
        case let (nil, cloud?):
            applySavedState(cloud)
            if let cloudData {
                UserDefaults.standard.set(cloudData, forKey: GameSaveState.storageKey)
            }
            cloudSaveStatus = .restoredFromCloud
        case let (local?, nil):
            applySavedState(local)
            if let localData {
                cloudSaveStatus = cloudSave.save(data: localData, for: GameSaveState.storageKey) ? .synced : .localOnly
            }
        case (nil, nil):
            cloudSaveStatus = cloudSave.isAvailable ? .synced : .localOnly
        }
    }

    private func applySavedState(_ state: GameSaveState) {
        currentDay = state.currentDay
        hasPlayedRushToday = state.hasPlayedRushToday
        hasPlayedExtraServiceToday = state.hasPlayedExtraServiceToday
        hasAppliedEndOfDayCostsToday = state.hasAppliedEndOfDayCostsToday
        cash = state.cash
        level = state.level
        xp = state.xp
        reputation = state.reputation
        prices = Dictionary(uniqueKeysWithValues: Products.all.map { product in
            let savedPrice = state.prices[product.id, default: product.sellPrice]
            return (product.id, min(product.maximumSellPrice, max(product.buyCost + 1, savedPrice)))
        })
        purchasedUpgrades = state.purchasedUpgrades
        businessStage = state.businessStage
        purchasedStoreItems = state.purchasedStoreItems
        usedStoreConsumablesToday = state.usedStoreConsumablesToday
        supplyCouponCredit = state.supplyCouponCredit
        activeTheme = state.activeTheme
        debt = state.debt
        activeLoanPlan = state.activeLoanPlan ?? inferredLoanPlan(for: state.debt)
        lastBankruptcy = state.lastBankruptcy
        lastAbsenceReport = state.lastAbsenceReport
        lastVisitDate = state.lastVisitDate
        stock = stockClampedToCapacity(state.stock)
        storageStock = storageClampedToCapacity(state.storageStock)
        isStorageActivated = state.isStorageActivated || storageStock.quantities.values.contains(where: { $0 > 0 })
        lastReport = state.lastReport
        telemetry = state.telemetry
        playerName = state.playerName
        playerAvatar = state.playerAvatar
        dailyTaskProgress = state.dailyTaskProgress
        claimedDailyTasks = state.claimedDailyTasks
        lastMainServiceDate = state.lastMainServiceDate
        lastMainServiceAt = state.lastMainServiceAt
    }

    private func dailyTaskTarget(_ task: DailyTaskID) -> Int {
        switch task {
        case .serve:
            return min(14, 5 + level / 4)
        case .combo:
            return min(6, 2 + level / 8)
        case .profit:
            return 90 + level * 12
        }
    }

    private func updateDailyTasks(with report: DayReport) {
        dailyTaskProgress[.serve, default: 0] += report.served
        dailyTaskProgress[.combo] = max(dailyTaskProgress[.combo, default: 0], report.bestCombo)
        dailyTaskProgress[.profit, default: 0] += max(0, report.netProfit)
    }

    private func inferredLoanPlan(for debt: Int) -> LoanPlan? {
        guard debt > 0 else { return nil }
        if debt > LoanPlan.medium.debtAmount { return .large }
        if debt > LoanPlan.small.debtAmount { return .medium }
        return .small
    }
}

extension GameTheme {
    var storeItem: StoreItemID {
        switch self {
        case .morning: .rentSupport
        case .evening: .eveningTheme
        case .rainy: .rainyTheme
        }
    }
}

private enum SaveDateKey {
    static func today() -> String {
        formatter.string(from: Date())
    }

    static func date(from value: String) -> Date? {
        formatter.date(from: value)
    }

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

private struct GameSaveState: Codable {
    static let storageKey = "simitci-rush-save-v2"

    let currentDay: Int
    let hasPlayedRushToday: Bool
    let hasPlayedExtraServiceToday: Bool
    let hasAppliedEndOfDayCostsToday: Bool
    let cash: Int
    let level: Int
    let xp: Int
    let reputation: Int
    let stock: StockState
    let storageStock: StockState
    let isStorageActivated: Bool
    let prices: [ProductID: Int]
    let purchasedUpgrades: Set<UpgradeID>
    let businessStage: BusinessStage
    let purchasedStoreItems: Set<StoreItemID>
    let usedStoreConsumablesToday: Set<StoreItemID>
    let supplyCouponCredit: Int
    let activeTheme: GameTheme
    let debt: Int
    let activeLoanPlan: LoanPlan?
    let lastBankruptcy: BankruptcySummary?
    let lastAbsenceReport: AbsenceReport?
    let lastReport: DayReport?
    let telemetry: GameTelemetry
    let playerName: String
    let playerAvatar: PlayerAvatar
    let dailyTaskProgress: [DailyTaskID: Int]
    let claimedDailyTasks: Set<DailyTaskID>
    let lastMainServiceDate: String?
    let lastMainServiceAt: TimeInterval?
    let lastVisitDate: String
    let savedAt: TimeInterval

    init(
        currentDay: Int,
        hasPlayedRushToday: Bool,
        hasPlayedExtraServiceToday: Bool,
        hasAppliedEndOfDayCostsToday: Bool,
        cash: Int,
        level: Int,
        xp: Int,
        reputation: Int,
        stock: StockState,
        storageStock: StockState,
        isStorageActivated: Bool,
        prices: [ProductID: Int],
        purchasedUpgrades: Set<UpgradeID>,
        businessStage: BusinessStage,
        purchasedStoreItems: Set<StoreItemID>,
        usedStoreConsumablesToday: Set<StoreItemID>,
        supplyCouponCredit: Int,
        activeTheme: GameTheme,
        debt: Int,
        activeLoanPlan: LoanPlan?,
        lastBankruptcy: BankruptcySummary?,
        lastAbsenceReport: AbsenceReport?,
        lastReport: DayReport?,
        telemetry: GameTelemetry,
        playerName: String,
        playerAvatar: PlayerAvatar,
        dailyTaskProgress: [DailyTaskID: Int],
        claimedDailyTasks: Set<DailyTaskID>,
        lastMainServiceDate: String?,
        lastMainServiceAt: TimeInterval?
    ) {
        self.currentDay = currentDay
        self.hasPlayedRushToday = hasPlayedRushToday
        self.hasPlayedExtraServiceToday = hasPlayedExtraServiceToday
        self.hasAppliedEndOfDayCostsToday = hasAppliedEndOfDayCostsToday
        self.cash = cash
        self.level = level
        self.xp = xp
        self.reputation = reputation
        self.stock = stock
        self.storageStock = storageStock
        self.isStorageActivated = isStorageActivated
        self.prices = prices
        self.purchasedUpgrades = purchasedUpgrades
        self.businessStage = businessStage
        self.purchasedStoreItems = purchasedStoreItems
        self.usedStoreConsumablesToday = usedStoreConsumablesToday
        self.supplyCouponCredit = supplyCouponCredit
        self.activeTheme = activeTheme
        self.debt = debt
        self.activeLoanPlan = activeLoanPlan
        self.lastBankruptcy = lastBankruptcy
        self.lastAbsenceReport = lastAbsenceReport
        self.lastReport = lastReport
        self.telemetry = telemetry
        self.playerName = playerName
        self.playerAvatar = playerAvatar
        self.dailyTaskProgress = dailyTaskProgress
        self.claimedDailyTasks = claimedDailyTasks
        self.lastMainServiceDate = lastMainServiceDate
        self.lastMainServiceAt = lastMainServiceAt
        self.lastVisitDate = SaveDateKey.today()
        self.savedAt = Date().timeIntervalSince1970
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        currentDay = try container.decode(Int.self, forKey: .currentDay)
        hasPlayedRushToday = try container.decode(Bool.self, forKey: .hasPlayedRushToday)
        hasPlayedExtraServiceToday = try container.decodeIfPresent(Bool.self, forKey: .hasPlayedExtraServiceToday) ?? false
        hasAppliedEndOfDayCostsToday = try container.decodeIfPresent(Bool.self, forKey: .hasAppliedEndOfDayCostsToday) ?? false
        cash = try container.decode(Int.self, forKey: .cash)
        level = try container.decode(Int.self, forKey: .level)
        xp = try container.decode(Int.self, forKey: .xp)
        reputation = try container.decode(Int.self, forKey: .reputation)
        stock = try container.decode(StockState.self, forKey: .stock)
        storageStock = try container.decodeIfPresent(StockState.self, forKey: .storageStock) ?? .empty
        isStorageActivated = try container.decodeIfPresent(Bool.self, forKey: .isStorageActivated) ?? storageStock.quantities.values.contains(where: { $0 > 0 })
        prices = try container.decode([ProductID: Int].self, forKey: .prices)
        purchasedUpgrades = try container.decode(Set<UpgradeID>.self, forKey: .purchasedUpgrades)
        businessStage = try container.decodeIfPresent(BusinessStage.self, forKey: .businessStage) ?? .smallCart
        purchasedStoreItems = try container.decode(Set<StoreItemID>.self, forKey: .purchasedStoreItems)
        usedStoreConsumablesToday = try container.decodeIfPresent(Set<StoreItemID>.self, forKey: .usedStoreConsumablesToday) ?? []
        supplyCouponCredit = try container.decodeIfPresent(Int.self, forKey: .supplyCouponCredit) ?? 0
        activeTheme = try container.decode(GameTheme.self, forKey: .activeTheme)
        debt = try container.decode(Int.self, forKey: .debt)
        activeLoanPlan = try container.decodeIfPresent(LoanPlan.self, forKey: .activeLoanPlan)
        lastBankruptcy = try container.decodeIfPresent(BankruptcySummary.self, forKey: .lastBankruptcy)
        lastAbsenceReport = try container.decodeIfPresent(AbsenceReport.self, forKey: .lastAbsenceReport)
        lastReport = try container.decodeIfPresent(DayReport.self, forKey: .lastReport)
        telemetry = try container.decodeIfPresent(GameTelemetry.self, forKey: .telemetry) ?? GameTelemetry()
        playerName = try container.decodeIfPresent(String.self, forKey: .playerName) ?? "Simitçi"
        playerAvatar = try container.decodeIfPresent(PlayerAvatar.self, forKey: .playerAvatar) ?? .simit
        dailyTaskProgress = try container.decodeIfPresent([DailyTaskID: Int].self, forKey: .dailyTaskProgress) ?? [:]
        claimedDailyTasks = try container.decodeIfPresent(Set<DailyTaskID>.self, forKey: .claimedDailyTasks) ?? []
        lastMainServiceDate = try container.decodeIfPresent(String.self, forKey: .lastMainServiceDate)
        lastMainServiceAt = try container.decodeIfPresent(TimeInterval.self, forKey: .lastMainServiceAt)
        lastVisitDate = try container.decodeIfPresent(String.self, forKey: .lastVisitDate) ?? SaveDateKey.today()
        savedAt = try container.decodeIfPresent(TimeInterval.self, forKey: .savedAt) ?? 0
    }
}

struct DayReport: Equatable, Codable {
    let revenue: Int
    let supplyCost: Int
    let fixedCost: Int
    let storageCost: Int
    let spoilageCost: Int
    let loanPayment: Int
    let pricePenalty: Int
    let netProfit: Int
    let spoiledStock: [ProductID: Int]
    let served: Int
    let missed: Int
    let wrong: Int
    let happiness: Int
    let bestCombo: Int
    let score: Int
    let xpEarned: Int
    let reputationDelta: Int
    let completedOrderSeconds: Double
    let soldProducts: [ProductID: Int]

    init(
        revenue: Int,
        supplyCost: Int,
        fixedCost: Int,
        storageCost: Int = 0,
        spoilageCost: Int = 0,
        loanPayment: Int,
        pricePenalty: Int,
        netProfit: Int,
        spoiledStock: [ProductID: Int] = [:],
        served: Int,
        missed: Int,
        wrong: Int,
        happiness: Int,
        bestCombo: Int,
        score: Int,
        xpEarned: Int,
        reputationDelta: Int,
        completedOrderSeconds: Double = 0,
        soldProducts: [ProductID: Int] = [:]
    ) {
        self.revenue = revenue
        self.supplyCost = supplyCost
        self.fixedCost = fixedCost
        self.storageCost = storageCost
        self.spoilageCost = spoilageCost
        self.loanPayment = loanPayment
        self.pricePenalty = pricePenalty
        self.netProfit = netProfit
        self.spoiledStock = spoiledStock
        self.served = served
        self.missed = missed
        self.wrong = wrong
        self.happiness = happiness
        self.bestCombo = bestCombo
        self.score = score
        self.xpEarned = xpEarned
        self.reputationDelta = reputationDelta
        self.completedOrderSeconds = completedOrderSeconds
        self.soldProducts = soldProducts
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        revenue = try container.decode(Int.self, forKey: .revenue)
        supplyCost = try container.decode(Int.self, forKey: .supplyCost)
        fixedCost = try container.decode(Int.self, forKey: .fixedCost)
        storageCost = try container.decodeIfPresent(Int.self, forKey: .storageCost) ?? 0
        spoilageCost = try container.decodeIfPresent(Int.self, forKey: .spoilageCost) ?? 0
        loanPayment = try container.decode(Int.self, forKey: .loanPayment)
        pricePenalty = try container.decode(Int.self, forKey: .pricePenalty)
        netProfit = try container.decode(Int.self, forKey: .netProfit)
        spoiledStock = try container.decodeIfPresent([ProductID: Int].self, forKey: .spoiledStock) ?? [:]
        served = try container.decode(Int.self, forKey: .served)
        missed = try container.decode(Int.self, forKey: .missed)
        wrong = try container.decode(Int.self, forKey: .wrong)
        happiness = try container.decode(Int.self, forKey: .happiness)
        bestCombo = try container.decode(Int.self, forKey: .bestCombo)
        score = try container.decode(Int.self, forKey: .score)
        xpEarned = try container.decode(Int.self, forKey: .xpEarned)
        reputationDelta = try container.decode(Int.self, forKey: .reputationDelta)
        completedOrderSeconds = try container.decodeIfPresent(Double.self, forKey: .completedOrderSeconds) ?? 0
        soldProducts = try container.decodeIfPresent([ProductID: Int].self, forKey: .soldProducts) ?? [:]
    }

    var cashDelta: Int {
        revenue - fixedCost - storageCost - loanPayment
    }

    func applyingEndOfDayCosts(storageCost: Int, spoilageCost: Int, spoiledStock: [ProductID: Int]) -> DayReport {
        DayReport(
            revenue: revenue,
            supplyCost: supplyCost,
            fixedCost: fixedCost,
            storageCost: self.storageCost + storageCost,
            spoilageCost: self.spoilageCost + spoilageCost,
            loanPayment: loanPayment,
            pricePenalty: pricePenalty,
            netProfit: netProfit - storageCost - spoilageCost,
            spoiledStock: spoiledStock.merging(self.spoiledStock) { new, old in old + new },
            served: served,
            missed: missed,
            wrong: wrong,
            happiness: happiness,
            bestCombo: bestCombo,
            score: max(0, score - storageCost - spoilageCost),
            xpEarned: xpEarned,
            reputationDelta: reputationDelta,
            completedOrderSeconds: completedOrderSeconds,
            soldProducts: soldProducts
        )
    }

    func merged(with other: DayReport) -> DayReport {
        let servedTotal = served + other.served
        let weightedHappiness: Int
        if servedTotal > 0 {
            weightedHappiness = ((happiness * max(1, served)) + (other.happiness * max(1, other.served))) / (max(1, served) + max(1, other.served))
        } else {
            weightedHappiness = min(happiness, other.happiness)
        }

        return DayReport(
            revenue: revenue + other.revenue,
            supplyCost: supplyCost + other.supplyCost,
            fixedCost: fixedCost + other.fixedCost,
            storageCost: storageCost + other.storageCost,
            spoilageCost: spoilageCost + other.spoilageCost,
            loanPayment: loanPayment + other.loanPayment,
            pricePenalty: pricePenalty + other.pricePenalty,
            netProfit: netProfit + other.netProfit,
            spoiledStock: spoiledStock.merging(other.spoiledStock) { current, incoming in current + incoming },
            served: servedTotal,
            missed: missed + other.missed,
            wrong: wrong + other.wrong,
            happiness: weightedHappiness,
            bestCombo: max(bestCombo, other.bestCombo),
            score: score + other.score,
            xpEarned: xpEarned + other.xpEarned,
            reputationDelta: reputationDelta + other.reputationDelta,
            completedOrderSeconds: completedOrderSeconds + other.completedOrderSeconds,
            soldProducts: soldProducts.merging(other.soldProducts) { current, incoming in current + incoming }
        )
    }
}
