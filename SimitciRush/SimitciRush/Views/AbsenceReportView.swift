import SwiftUI

struct AbsenceReportView: View {
    @ObservedObject var game: GameSession

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ScreenTitle(
                    title: "Tezgâh Kapalı Kaldı",
                    subtitle: "Uğramadığın günlerde tezgâhın masrafı işledi. Kısa bir hesap çıkardık."
                )
                .padding(.top, 18)

                if let report = game.lastAbsenceReport {
                    StandPanel {
                        VStack(spacing: 12) {
                            Image(systemName: "storefront.fill")
                                .font(.system(size: 44, weight: .black))
                                .foregroundStyle(Color.simitAmber)
                                .frame(width: 76, height: 76)
                                .background(Color.simitAmber.opacity(0.14), in: Circle())

                            Text("\(report.missedDays) gün tezgâha uğranmadı")
                                .font(.title2.weight(.black))
                                .foregroundStyle(Color.simitCream)
                                .multilineTextAlignment(.center)

                            Text(report.chargedDays < report.missedDays ? "Yer ücreti en fazla \(report.chargedDays) gün işlendi. Taze stoklar kontrol edildi." : "Yer ücreti ve taze stok kontrolü uygulandı.")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white.opacity(0.66))
                                .multilineTextAlignment(.center)

                            Text("Simit ve poşet dayanır; çay, ayran ve ek malzemeler kapalı günlerde azalabilir.")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(Color.simitCream.opacity(0.58))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                    }

                    GameCard {
                        VStack(spacing: 12) {
                            SectionHeader(title: "Kapalı Gün Hesabı", systemImage: "receipt.fill")
                            AbsenceRow(title: "Yer ücreti", value: "-\(report.rentCost) TL", tint: .simitDanger)
                            AbsenceRow(title: "İtibar", value: "-\(report.reputationLoss)", tint: .simitDanger)
                            AbsenceRow(title: "Kasa", value: "\(game.cash) TL", tint: game.cash >= 0 ? .simitAmber : .simitDanger)
                        }
                    }

                    if !report.spoiledStock.isEmpty {
                        GameCard {
                            VStack(spacing: 12) {
                                SectionHeader(title: "Taze Stok Azaldı", systemImage: "shippingbox.fill")
                                ForEach(report.spoiledStock.sorted(by: { Products.definition(for: $0.key).name < Products.definition(for: $1.key).name }), id: \.key) { product, quantity in
                                    AbsenceRow(title: Products.definition(for: product).name, value: "-\(quantity)", tint: .simitDanger)
                                }
                            }
                        }
                    }

                    PrimaryGameButton(title: "Dükkâna Dön", systemImage: "house.fill") {
                        game.dismissAbsenceReport()
                    }
                    .padding(.bottom, 18)
                } else {
                    GameCard {
                        VStack(spacing: 12) {
                            SectionHeader(title: "Rapor Yok", systemImage: "checkmark.seal.fill")
                            Text("Bugün tezgâh normal durumda.")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.62))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    PrimaryGameButton(title: "Dükkâna Dön", systemImage: "house.fill") {
                        game.dismissAbsenceReport()
                    }
                }
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
    }
}

private struct AbsenceRow: View {
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
