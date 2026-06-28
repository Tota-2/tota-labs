import SwiftUI

struct DayCloseView: View {
    @ObservedObject var game: GameSession

    private var report: DayReport? {
        game.lastReport
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ScreenTitle(
                    title: "Gün Kapandı",
                    subtitle: "Masraflar işlendi, taze stok kontrol edildi. Yeni servis takvim gününde açılır."
                )
                .padding(.top, 18)

                if let report {
                    DayCloseHero(game: game, report: report)

                    GameCard {
                        VStack(spacing: 12) {
                            SectionHeader(title: "Kapanış Defteri", systemImage: "receipt.fill")

                            HStack(spacing: 10) {
                                LedgerSummaryTile(title: "Ciro", value: "\(report.revenue) TL", tint: .simitSuccess)
                                LedgerSummaryTile(title: "Gider", value: "-\(report.totalCost) TL", tint: .simitDanger)
                                LedgerSummaryTile(title: "Gün Neti", value: "\(report.netProfit) TL", tint: report.netProfit >= 0 ? .simitAmber : .simitDanger)
                            }

                            CloseLedgerRow(title: "Satış geliri", value: "+\(report.revenue) TL", note: "\(report.served) servis", tint: .simitSuccess)
                            CloseLedgerRow(title: "Stok maliyeti", value: "-\(report.supplyCost) TL", note: "Bugün satılan ürünlerin alış maliyeti")
                            CloseLedgerRow(title: "Yer ücreti", value: "-\(report.fixedCost) TL", note: "Günlük sabit masraf")
                            if report.storageCost > 0 {
                                CloseLedgerRow(title: "Depo bakımı", value: "-\(report.storageCost) TL", note: "Depo açık kaldığı için")
                            }
                            if report.spoilageCost > 0 {
                                CloseLedgerRow(title: "Bozulan stok", value: "-\(report.spoilageCost) TL", note: "\(report.spoiledStock.values.reduce(0, +)) ürün kaybı", tint: .simitDanger)
                            }
                            if report.loanPayment > 0 {
                                CloseLedgerRow(title: "Kredi ödemesi", value: "-\(report.loanPayment) TL", note: "Esnaf bankası taksidi")
                            }

                            SpoiledStockBreakdown(report: report)

                            Divider().overlay(Color.white.opacity(0.12))
                            HStack(spacing: 10) {
                                MetricTile(title: "Kasa", value: "\(game.cash) TL", systemImage: "banknote.fill", tint: .simitAmber)
                                MetricTile(title: "İtibar", value: "\(game.reputation)", systemImage: "heart.fill", tint: .simitDanger)
                            }
                        }
                    }

                    TomorrowPlanCard(game: game, report: report)

                    PrimaryGameButton(title: game.canPrepareNextDay ? "Yeni Güne Başla" : "Yarın Açılır", systemImage: game.canPrepareNextDay ? "arrow.right.circle.fill" : "lock.fill", enabled: game.canPrepareNextDay) {
                        game.restartDay()
                    }
                    .frame(maxWidth: 520)

                    Button {
                        game.backHome()
                    } label: {
                        Label("Dükkâna Dön", systemImage: "house.fill")
                            .font(.subheadline.weight(.black))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(Color.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .foregroundStyle(Color.simitCream)
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 18)
                } else {
                    GameCard {
                        VStack(spacing: 12) {
                            SectionHeader(title: "Rapor Yok", systemImage: "exclamationmark.triangle.fill")
                            Text("Önce servis tamamlanmalı. Sonra gün kapatma ekranı açılır.")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.62))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    PrimaryGameButton(title: "Dükkâna Dön", systemImage: "house.fill") {
                        game.backHome()
                    }
                }
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: 780)
            .frame(maxWidth: .infinity)
        }
    }
}

private extension DayReport {
    var totalCost: Int {
        supplyCost + fixedCost + storageCost + spoilageCost + loanPayment
    }
}

private struct DayCloseInsightCard: View {
    @ObservedObject var game: GameSession
    let report: DayReport

    private var title: String {
        if report.netProfit < 0 { return "Bugün zarar yazdı" }
        if report.spoilageCost > 0 { return "Kâr var ama stok kaybı oldu" }
        if report.missed > report.served / 2 { return "Kuyruk kaçırdı" }
        return "Dükkân ayakta"
    }

    private var detail: String {
        if report.netProfit < 0 {
            if report.missed > report.served {
                return "Zararın ana sebebi kaçan müşteri. Yarın siparişi sade tut, stok yoksa hızlıca bildir."
            }
            return "Yarın daha az stok riski al, fiyatları kontrol et ve yer ücretini çıkaracak ciroya odaklan."
        }
        if report.spoilageCost > 0 {
            return "Depoda fazla taze ürün kaldı. Yarın daha kontrollü tedarik veya soğuk dolap mantıklı olabilir."
        }
        if game.debt > 0 {
            return "Kasa iyi görünse de her gün \(game.dailyLoanPayment) TL kredi ödemesi var."
        }
        return "Ciro giderleri karşıladı. Yarın kapasiteyi abartmadan büyümeye devam edebilirsin."
    }

    private var tint: Color {
        report.netProfit < 0 ? .simitDanger : report.spoilageCost > 0 ? .simitAmber : .simitSuccess
    }

    var body: some View {
        GameCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: report.netProfit < 0 ? "exclamationmark.triangle.fill" : "checkmark.seal.fill")
                    .font(.title3.weight(.black))
                    .foregroundStyle(tint)
                    .frame(width: 42, height: 42)
                    .background(tint.opacity(0.16), in: Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.headline.weight(.black))
                        .foregroundStyle(Color.simitCream)
                    Text(detail)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.58))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

private struct DayCloseHero: View {
    @ObservedObject var game: GameSession
    let report: DayReport

    private var netTint: Color {
        report.netProfit >= 0 ? .simitSuccess : .simitDanger
    }

    var body: some View {
        StandPanel {
            VStack(spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Gün \(game.currentDay)")
                            .font(.caption.weight(.black))
                            .textCase(.uppercase)
                            .foregroundStyle(.white.opacity(0.58))
                        Text(report.netProfit >= 0 ? "Kazanç var" : "Zarar yazdı")
                            .font(.title2.weight(.black))
                            .foregroundStyle(Color.simitCream)
                    }

                    Spacer()

                    Image(systemName: report.netProfit >= 0 ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                        .font(.title2.weight(.black))
                        .foregroundStyle(netTint)
                        .frame(width: 42, height: 42)
                        .background(netTint.opacity(0.16), in: Circle())
                }

                Text("\(report.netProfit) TL")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(netTint)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                HStack(spacing: 10) {
                    MiniCloseStat(title: "Servis", value: "\(report.served)")
                    MiniCloseStat(title: "Kaçan", value: "\(report.missed)")
                    MiniCloseStat(title: "Combo", value: "x\(report.bestCombo)")
                }
            }
        }
    }
}

private struct MiniCloseStat: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.headline.weight(.black))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text(title.uppercased())
                .font(.caption2.weight(.black))
                .foregroundStyle(.white.opacity(0.46))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.black.opacity(0.15), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct LedgerSummaryTile: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.black))
                .foregroundStyle(.white.opacity(0.46))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text(value)
                .font(.subheadline.weight(.black))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.68)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct CloseLedgerRow: View {
    let title: String
    let value: String
    let note: String
    var tint: Color = .white.opacity(0.72)

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white.opacity(0.72))
                Text(note)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.42))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 10)
            Text(value)
                .font(.headline.weight(.black))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(.vertical, 2)
    }
}

private struct SpoiledStockBreakdown: View {
    let report: DayReport

    private var items: [(ProductID, Int)] {
        report.spoiledStock
            .filter { $0.value > 0 }
            .sorted { Products.definition(for: $0.key).name < Products.definition(for: $1.key).name }
    }

    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Stok kaybı")
                    .font(.caption.weight(.black))
                    .textCase(.uppercase)
                    .foregroundStyle(.white.opacity(0.46))

                ForEach(items, id: \.0) { product, quantity in
                    HStack(spacing: 10) {
                        let definition = Products.definition(for: product)

                        ProductMark(product: definition, size: 28)
                        Text(definition.name)
                            .font(.caption.weight(.black))
                            .foregroundStyle(Color.simitCream)
                        Spacer()
                        Text("-\(quantity)")
                            .font(.caption.weight(.black))
                            .foregroundStyle(Color.simitDanger)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.13), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .padding(.top, 2)
        }
    }
}

private struct TomorrowPlanCard: View {
    @ObservedObject var game: GameSession
    let report: DayReport

    private var title: String {
        if report.netProfit < 0 { return "Yarın daha temkinli" }
        if report.spoilageCost > 0 { return "Stoku sıkı tut" }
        if game.debt > 0 { return "Borcu unutma" }
        return "Yarın hazır"
    }

    private var detail: String {
        if report.netProfit < 0 {
            return "Kasa zorlandı. Daha az tedarik al, yer ücretini çıkaracak ana ürünlere odaklan."
        }
        if report.spoilageCost > 0 {
            return "Fazla ürün kayıp yazdı. Yarın taze stokta daha kontrollü git."
        }
        if game.debt > 0 {
            return "Her gün \(game.dailyLoanPayment) TL kredi ödemesi var. Yeni kredi almadan kasayı rahatlat."
        }
        return "Gün neti artıda. Kasa uygunsa küçük bir geliştirme veya dengeli tedarik mantıklı."
    }

    var body: some View {
        GameCard {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: game.canPrepareNextDay ? "sunrise.fill" : "lock.clock.fill")
                        .font(.headline.weight(.black))
                        .foregroundStyle(game.canPrepareNextDay ? Color.simitAmber : Color.simitTeal)
                        .frame(width: 40, height: 40)
                        .background((game.canPrepareNextDay ? Color.simitAmber : Color.simitTeal).opacity(0.15), in: Circle())

                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(.headline.weight(.black))
                            .foregroundStyle(Color.simitCream)
                        Text(detail)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white.opacity(0.56))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)
                }

                Divider().overlay(Color.white.opacity(0.10))

                HStack(spacing: 10) {
                    MiniCloseStat(title: "Yeni Gün", value: "Gün \(game.currentDay + 1)")
                    MiniCloseStat(title: "Yer Ücreti", value: "\(game.fixedCost(for: game.currentDay + 1)) TL")
                    MiniCloseStat(title: "Kredi", value: game.debt > 0 ? "\(game.dailyLoanPayment) TL" : "Yok")
                }

                Text(game.nextServiceLockText)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.46))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

private struct TomorrowAdviceCard: View {
    @ObservedObject var game: GameSession
    let report: DayReport

    private var advice: [(String, String, String, Color)] {
        var rows: [(String, String, String, Color)] = []

        if report.spoilageCost > 0 {
            rows.append(("Tedarik", "Daha az taze stok al", "Bozulan ürün kârlılığı düşürdü.", .simitAmber))
        } else if report.supplyCost > max(0, report.revenue - report.fixedCost) {
            rows.append(("Tedarik", "Alış maliyeti yüksek", "Satış ciroyu getirdi ama stok maliyeti kârı ezdi.", .simitAmber))
        } else {
            rows.append(("Tedarik", "Stok dengesi iyi", "Yarın aynı tempoda kontrollü alış yap.", .simitSuccess))
        }

        if report.wrong > report.missed, report.wrong > 0 {
            rows.append(("Servis", "Doğru siparişe odaklan", "\(report.wrong) yanlış servis itibar ve XP'yi düşürdü.", .simitDanger))
        } else if report.missed > 0 {
            rows.append(("Servis", "Kuyruğu hızlandır", "\(report.missed) müşteri kaçtı; stok yoksa hızlıca söyle.", .simitDanger))
        } else {
            rows.append(("Servis", "Kuyruk temiz", "Kaçan müşteri yok; yarın combo kovalamak mantıklı.", .simitSuccess))
        }

        if game.debt > 0 {
            rows.append(("Kredi", "\(game.dailyLoanPayment) TL/gün ödeme", "Kasa rahatlamadan yeni kredi riskli.", .simitDanger))
        } else if report.netProfit < 0 {
            rows.append(("Kasa", "Nakit tamponu koru", "Zarar günlerinde market alışını kıs, iflas limitine yaklaşma.", .simitAmber))
        } else if report.netProfit > 0 {
            rows.append(("Büyüme", "Geliştirme düşün", "Kasa artıdaysa kapasite veya soğutma yatırımı mantıklı olabilir.", .simitTeal))
        }

        return rows
    }

    var body: some View {
        GameCard {
            VStack(spacing: 12) {
                SectionHeader(title: "Yarın İçin Not", systemImage: "lightbulb.fill")

                ForEach(advice, id: \.0) { item in
                    AdviceRow(category: item.0, title: item.1, detail: item.2, tint: item.3)
                }
            }
        }
    }
}

private struct AdviceRow: View {
    let category: String
    let title: String
    let detail: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(tint)
                .frame(width: 8, height: 8)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 3) {
                Text(category.uppercased())
                    .font(.caption2.weight(.black))
                    .foregroundStyle(tint)
                Text(title)
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(Color.simitCream)
                Text(detail)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.48))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.black.opacity(0.13), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct CloseRow: View {
    let title: String
    let value: String
    var tint: Color = .white.opacity(0.72)

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.62))
            Spacer()
            Text(value)
                .font(.headline.weight(.black))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
    }
}
