import SwiftUI

struct MainMenuView: View {
    @ObservedObject var game: GameSession
    @State private var showsNewGameAlert = false
    @State private var isOpeningShop = false
    @State private var showsGameGuide = false
    @AppStorage("simitci-rush-sound-enabled") private var soundEnabled = true

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    private var versionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        return build.map { "v\(version) (\($0))" } ?? "v\(version)"
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Spacer(minLength: 42)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Simitçi")
                        .font(.system(size: isPad ? 64 : 48, weight: .black, design: .rounded))
                        .foregroundStyle(Color.simitCream)
                        .lineLimit(1)
                        .minimumScaleFactor(0.74)

                    Text("İstanbul sabahında tezgâhı aç, kuyruğu erit, günü kârda kapat.")
                        .font((isPad ? Font.title3 : Font.headline).weight(.bold))
                        .foregroundStyle(.white.opacity(0.72))
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(maxWidth: isPad ? 900 : .infinity, alignment: .leading)
                .padding(.horizontal, isPad ? 0 : 24)

                Spacer(minLength: 40)

                StandPanel {
                    VStack(spacing: 10) {
                        MainMenuButton(title: "Devam Et", subtitle: "Gün \(game.currentDay) · \(game.cash) TL", systemImage: "play.fill", tint: .simitAmber) {
                            openShopWithTransition()
                        }
                        .disabled(isOpeningShop)

                        MainMenuButton(title: "Yeni Oyun", subtitle: "Mevcut dükkânı sıfırlar", systemImage: "plus.circle.fill", tint: .simitCream) {
                            showsNewGameAlert = true
                        }
                        .disabled(isOpeningShop)

                        MainMenuButton(title: "Özel Dükkân", subtitle: "Tema ve esnaf destekleri", systemImage: "storefront.fill", tint: .simitTeal) {
                            game.openStore()
                        }
                        .disabled(isOpeningShop)

                        MainMenuButton(title: "Oyun Rehberi", subtitle: "İflas, depo, fiyat ve itibar", systemImage: "questionmark.circle.fill", tint: .simitCream) {
                            showsGameGuide = true
                        }
                        .disabled(isOpeningShop)
                        MainMenuButton(title: "Ayarlar", subtitle: "Ses, titreşim ve oyun tercihleri", systemImage: "gearshape.fill", tint: .simitSuccess) {
                            game.openSettings()
                        }
                        .disabled(isOpeningShop)
                    }
                }
                .frame(maxWidth: isPad ? 900 : .infinity)
                .padding(.horizontal, isPad ? 0 : 20)

                Spacer(minLength: 22)

                Text(versionText)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.white.opacity(0.46))
                    .padding(.bottom, 18)
            }

            if isOpeningShop {
                ShopOpeningTransitionView()
                    .transition(.opacity)
                    .zIndex(5)
            }
        }
        .alert("Yeni oyun başlatılsın mı?", isPresented: $showsNewGameAlert) {
            Button("Vazgeç", role: .cancel) {}
            Button("Yeni Oyun", role: .destructive) {
                game.resetGame()
            }
        } message: {
            Text("Mevcut ilerleme, kasa, stok, depo ve krediler sıfırlanacak.")
        }
        .sheet(isPresented: $showsGameGuide) {
            GameGuideSheet(game: game)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .preferredColorScheme(.dark)
        }
    }

    private func openShopWithTransition() {
        guard !isOpeningShop else { return }
        withAnimation(.easeOut(duration: 0.18)) {
            isOpeningShop = true
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(3000))
            game.backHome()
            if soundEnabled {
                GameAudio.shared.play(.ferryHorn, volume: 0.42)
            }
        }
    }
}

private struct GameGuideSheet: View {
    @ObservedObject var game: GameSession
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.simitBackgroundDeep.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.title2.weight(.black))
                            .foregroundStyle(Color.simitAmber)
                            .frame(width: 44, height: 44)
                            .background(Color.simitAmber.opacity(0.16), in: Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Oyun Rehberi")
                                .font(.system(size: 30, weight: .black, design: .rounded))
                                .foregroundStyle(Color.simitCream)
                            Text("Esnaflığı ayakta tutan kısa notlar.")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.62))
                        }

                        Spacer()

                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.caption.weight(.black))
                                .frame(width: 32, height: 32)
                                .foregroundStyle(Color.simitCream)
                                .background(Color.simitStand.opacity(0.84), in: Circle())
                                .overlay(Circle().stroke(Color.simitAmber.opacity(0.52), lineWidth: 1.5))
                        }
                        .buttonStyle(.plain)
                    }

                    VStack(spacing: 9) {
                        GuideRow(title: "Günün Döngüsü", detail: "Market, hazırlık, ana servis, rapor ve kapanış. Para asıl kapanış defterinde netleşir.", systemImage: "arrow.triangle.2.circlepath")
                        GuideRow(title: "Servis", detail: "Sipariş balonundaki ürünlere dokun, tepsiyi doğru doldur ve servis et. Stok yoksa eksik ürünü satmaya çalışma.", systemImage: "timer")
                        GuideRow(title: "Ek Servis", detail: "Ana servisten sonra iyi gün çıkardıysan kısa ek servis fırsatı doğabilir. Oynamazsan ceza yok; oynarsan risk ve kazanç artar.", systemImage: "clock.badge.checkmark")
                        GuideRow(title: "Gün Kapanışı", detail: "Kira, stok maliyeti, kredi ödemesi, depo bakımı ve bozulan stok burada düşer. Kâr-zararın gerçek yeri burası.", systemImage: "receipt.fill")
                        GuideRow(title: "Tedarik Kuponu", detail: "Özel Dükkân'dan alınır. Kasaya para eklemez; markette stok alırken önce kupon bakiyesi düşer.", systemImage: "ticket.fill")
                        GuideRow(title: "Fiyat ve Mutluluk", detail: "Zam ciroyu artırır ama fazla abartırsan mutluluk ve itibar düşer. İyi esnaf sadece pahalı satan değildir.", systemImage: "tag.fill")
                        GuideRow(title: "İtibar", detail: "İtibar düştükçe müşteri daha çabuk kaçar. Doğru servis, az hata ve makul fiyat uzun vadede daha değerlidir.", systemImage: "heart.fill")
                        GuideRow(title: "Depo", detail: "Depo Lv \(GameProgression.storageUnlockLevel)'te açılır. Stok depoda durur; servisten önce hazırlıkta tezgâha çıkarman gerekir.", systemImage: "shippingbox.fill")
                        GuideRow(title: "Kredi", detail: "Kredi otomatik alınmaz. Sen seçersen nakit gelir, sonra her gün taksit ve borç riski işletmeye yazılır.", systemImage: "creditcard.fill")
                        GuideRow(title: "Kapalı Günler", detail: "Oyuna uzun süre dönmezsen en fazla 3 günlük yer ücreti işler. Taze ürünlerin bir kısmı bozulabilir.", systemImage: "calendar.badge.exclamationmark")
                        GuideRow(title: "Günlük Hedefler", detail: "Hedefler oyun günüyle yenilenir. Tamamlanan ödülleri Esnaf ekranından kendin alırsın.", systemImage: "checklist.checked")
                        GuideRow(title: "Özel Dükkân", detail: "Temalar sadece görünüm değiştirir. Destekler oyun parasıyla, günlük limitli ve küçük destek olarak çalışır.", systemImage: "storefront.fill")
                        GuideRow(title: "Bildirimler", detail: "Ayarlar'dan açarsan ana servis, ek servis fırsatı ve alınmamış ödüller için iOS bildirimi gelir.", systemImage: "bell.badge.fill")
                        GuideRow(title: "Kayıt ve Sıralama", detail: "İlerleme cihazda saklanır, iCloud açıksa taşınır. Game Center Esnaf Skoru ve başarımları gönderir.", systemImage: "icloud.fill")
                        GuideRow(title: "İflas", detail: "Kasa \(game.bankruptcyLimit) TL altına düşerse işletme batar ve oyun yeni başlangıca döner.", systemImage: "exclamationmark.triangle.fill")
                    }
                }
                .padding(20)
            }
        }
    }
}

private struct GuideRow: View {
    let title: String
    let detail: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.black))
                .foregroundStyle(Color.simitTeal)
                .frame(width: 34, height: 34)
                .background(Color.simitTeal.opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(Color.simitCream)
                Text(detail)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.58))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct MainMenuButton: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    let action: () -> Void

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: isPad ? 18 : 13) {
                Image(systemName: systemImage)
                    .font((isPad ? Font.title2 : Font.title3).weight(.black))
                    .foregroundStyle(tint)
                    .frame(width: isPad ? 58 : 42, height: isPad ? 58 : 42)
                    .background(tint.opacity(0.16), in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font((isPad ? Font.title3 : Font.headline).weight(.black))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font((isPad ? Font.subheadline : Font.caption).weight(.bold))
                        .foregroundStyle(.white.opacity(0.54))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font((isPad ? Font.subheadline : Font.caption).weight(.black))
                    .foregroundStyle(tint)
            }
            .padding(isPad ? 18 : 12)
            .background(Color.black.opacity(0.18), in: RoundedRectangle(cornerRadius: isPad ? 19 : 15, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: isPad ? 19 : 15, style: .continuous)
                    .stroke(tint.opacity(0.16), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct ShopOpeningTransitionView: View {
    @State private var opens = false

    var body: some View {
        ZStack {
            Color.black.opacity(opens ? 0.08 : 0.30)
                .ignoresSafeArea()

            RadialGradient(
                colors: [Color.simitCream.opacity(opens ? 0.34 : 0.08), .clear],
                center: .center,
                startRadius: 20,
                endRadius: 260
            )
            .scaleEffect(opens ? 1.25 : 0.76)
            .opacity(opens ? 1 : 0.45)

            CloudPuff(width: 250, height: 82)
                .offset(x: opens ? -260 : -40, y: -130)
                .opacity(opens ? 0 : 0.92)

            CloudPuff(width: 320, height: 104)
                .offset(x: opens ? 290 : 36, y: -32)
                .opacity(opens ? 0 : 0.88)

            CloudPuff(width: 280, height: 88)
                .offset(x: opens ? -310 : -12, y: 92)
                .opacity(opens ? 0 : 0.78)

            VStack(spacing: 8) {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 38, weight: .black))
                    .foregroundStyle(Color.simitAmber)
                    .scaleEffect(opens ? 1.08 : 0.92)
                Text("Dükkan açılıyor")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(Color.simitCream)
            }
            .opacity(opens ? 1 : 0.72)
            .offset(y: opens ? -6 : 8)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.7)) {
                opens = true
            }
        }
    }
}

private struct CloudPuff: View {
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        ZStack {
            Capsule()
                .fill(Color.white.opacity(0.62))
                .frame(width: width, height: height * 0.52)
                .blur(radius: 10)
            Circle()
                .fill(Color.white.opacity(0.60))
                .frame(width: height, height: height)
                .offset(x: -width * 0.22, y: -height * 0.12)
                .blur(radius: 9)
            Circle()
                .fill(Color.simitCream.opacity(0.40))
                .frame(width: height * 0.76, height: height * 0.76)
                .offset(x: width * 0.12, y: -height * 0.18)
                .blur(radius: 9)
        }
        .frame(width: width, height: height)
    }
}
