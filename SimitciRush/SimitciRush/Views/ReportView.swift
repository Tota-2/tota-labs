import SwiftUI

struct ReportView: View {
    @ObservedObject var game: GameSession

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ScreenTitle(title: "Servis Raporu", subtitle: "Satış sonucu. Asıl muhasebe kapanışta netleşir.")
                    .padding(.top, 18)

                if let report = game.lastReport {
                    ScoreCard(report: report)

                    GameCard {
                        VStack(spacing: 12) {
                            SectionHeader(title: "Servis Performansı", systemImage: "chart.bar.fill")
                            HStack(spacing: 10) {
                                MetricTile(title: "Servis", value: "\(report.served)", systemImage: "checkmark.circle.fill", tint: .simitSuccess)
                                MetricTile(title: "Kaçan", value: "\(report.missed)", systemImage: "figure.walk", tint: .simitDanger)
                                MetricTile(title: "Yanlış", value: "\(report.wrong)", systemImage: "xmark.circle.fill", tint: .simitDanger)
                            }

                            HStack(spacing: 10) {
                                ReportPill(title: "Combo", value: "x\(report.bestCombo)", tint: .simitTeal)
                                ReportPill(title: "Mutluluk", value: "\(report.happiness)", tint: .simitCream)
                                ReportPill(title: "Ciro", value: "\(report.revenue) TL", tint: .simitSuccess)
                            }
                        }
                    }

                    ReportHintCard(report: report)
                }

                if game.hasPlayedRushToday && !game.hasPlayedExtraServiceToday && !game.hasAppliedEndOfDayCostsToday {
                    GameCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(
                                title: game.hasExtraServiceOpportunity ? "Ek Servis Hazır" : (game.hasPendingExtraServiceOpportunity ? "Ek Servis Bekleniyor" : "Kapanış Kararı"),
                                systemImage: game.hasExtraServiceOpportunity ? "clock.badge.checkmark.fill" : (game.hasPendingExtraServiceOpportunity ? "hourglass" : "moon.stars.fill")
                            )
                            Text(game.extraServiceOpportunityText)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white.opacity(0.58))

                            HStack(spacing: 10) {
                                SecondaryReportButton(title: game.hasExtraServiceOpportunity || game.hasPendingExtraServiceOpportunity ? "Bugünü Kapat" : "Kapanışa Geç", systemImage: "lock.fill") {
                                    game.openDayClose()
                                }

                                if game.hasExtraServiceOpportunity {
                                    Button {
                                        game.startRush(mode: .extra)
                                    } label: {
                                        Label("Ek Servisi Aç", systemImage: "timer")
                                            .font(.subheadline.weight(.black))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 13)
                                            .background(Color.simitAmber, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                            .foregroundStyle(.black.opacity(0.82))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            if game.hasExtraServiceOpportunity {
                                Text("20 saniye sürer. Kira tekrar kesilmez; 120 TL açılış masrafı vardır. Oynamazsan ceza yoktur.")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(Color.simitAmber.opacity(0.78))
                                    .fixedSize(horizontal: false, vertical: true)
                            } else if game.hasPendingExtraServiceOpportunity {
                                Text("Ana servisten 6 saat sonra açılır. Beklemek zorunlu değildir; günü şimdi de kapatabilirsin.")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(Color.simitTeal.opacity(0.82))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                } else {
                    PrimaryGameButton(title: "Kapanışa Geç", systemImage: "lock.fill") {
                        game.openDayClose()
                    }
                    .frame(maxWidth: 520)
                }

                Button("Ana ekrana dön") {
                    game.backHome()
                }
                .font(.subheadline.weight(.black))
                .foregroundStyle(.white.opacity(0.68))
                .padding(.bottom, 18)
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
    }
}

private struct SecondaryReportButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.black))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Color.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .foregroundStyle(Color.simitCream)
        }
        .buttonStyle(.plain)
    }
}

private struct ReportHintCard: View {
    let report: DayReport

    private var title: String {
        if report.missed > report.served / 2 { return "Kuyruk zorladı" }
        if report.wrong > 0 { return "Siparişe dikkat" }
        if report.bestCombo >= 3 { return "Combo iyi çalıştı" }
        return "Kapanışa hazır"
    }

    private var text: String {
        if report.missed > report.served / 2 {
            return "Kaçan müşteri arttı. Sonraki gün stok ve hız kararını kapanışta kontrol et."
        }
        if report.wrong > 0 {
            return "\(report.wrong) yanlış servis var. Ürünleri sipariş balonundan seçmek daha hızlı olabilir."
        }
        if report.bestCombo >= 3 {
            return "Combo kasaya katkı verdi. Kapanışta gerçek neti görüp yeni güne hazırlan."
        }
        return "Servis bitti. Günün gerçek hesabı kapanış defterinde netleşir."
    }

    var body: some View {
        GameCard {
            HStack(spacing: 12) {
                Image(systemName: "lightbulb.fill")
                    .font(.headline.weight(.black))
                    .foregroundStyle(Color.simitAmber)
                    .frame(width: 38, height: 38)
                    .background(Color.simitAmber.opacity(0.15), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline.weight(.black))
                        .foregroundStyle(Color.simitCream)
                    Text(text)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.58))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

private struct ScoreCard: View {
    let report: DayReport

    var body: some View {
        StandPanel {
            HStack(spacing: 14) {
                Image(systemName: report.missed + report.wrong == 0 ? "checkmark.seal.fill" : "chart.bar.fill")
                    .font(.title2.weight(.black))
                    .foregroundStyle(Color.simitAmber)
                    .frame(width: 48, height: 48)
                    .background(Color.simitAmber.opacity(0.16), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("Servis Skoru")
                        .font(.caption.weight(.black))
                        .textCase(.uppercase)
                        .foregroundStyle(.white.opacity(0.55))
                    Text("\(report.score)")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(Color.simitCream)
                        .minimumScaleFactor(0.75)
                        .lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Label("+\(report.xpEarned) XP", systemImage: "sparkles")
                    Label("İtibar \(report.reputationDelta >= 0 ? "+" : "")\(report.reputationDelta)", systemImage: "heart.fill")
                }
                .font(.caption.weight(.black))
                .foregroundStyle(Color.simitTeal)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

private struct ReportPill: View {
    let title: String
    let value: String
    var tint: Color = .white

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.headline.weight(.black))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.68)
            Text(title)
                .font(.caption2.weight(.black))
                .textCase(.uppercase)
                .foregroundStyle(.white.opacity(0.46))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
