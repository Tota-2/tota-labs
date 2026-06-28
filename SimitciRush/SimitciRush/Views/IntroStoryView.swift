import SwiftUI

struct IntroStoryView: View {
    @ObservedObject var game: GameSession
    @State private var step = 0
    @State private var isAnimating = false
    @AppStorage("simitci-first-day-home-tip-dismissed") private var isFirstDayHomeTipDismissed = false
    @AppStorage("simitci-first-day-market-tip-dismissed") private var isFirstDayMarketTipDismissed = false
    @AppStorage("simitci-first-day-prep-tip-dismissed") private var isFirstDayPrepTipDismissed = false
    @AppStorage("simitci-rush-coach-seen") private var hasSeenRushCoach = false

    private let pages: [IntroStoryPage] = [
        .init(
            title: "Sabah hesabı",
            text: "Vapur iskelesi açılmadan tezgâhı kurmak lazım. İlk müşteriler acele eder; simit sıcaksa sıra çabuk uzar.",
            detail: "06:40 · Vapur İskelesi",
            systemImage: "ferry.fill",
            prop: .stand
        ),
        .init(
            title: "Cepteki para belli",
            text: "Kira, stok, çay, poşet... Hepsini baştan düşün. Fazla alırsan elde kalır, az alırsan müşteri başka tezgâha gider.",
            detail: "520 TL başlangıç kasası",
            systemImage: "banknote.fill",
            prop: .cash
        ),
        .init(
            title: "Müşteri beklemez",
            text: "Öğrenci hızlı ister, taksici oyalanmaz, mahalleli kaliteye bakar. Her doğru servis hem para hem itibar yazar.",
            detail: "Sıcak simit, hızlı servis",
            systemImage: "person.3.fill",
            prop: .customers
        ),
        .init(
            title: "Günü kârda kapat",
            text: "İyi stok tut, fiyatı abartma, kaçan müşteriyi azalt. Bu tabla dönerse yarın daha büyük iş kurarsın.",
            detail: "Küçük Seyyar Tabla",
            systemImage: "storefront.fill",
            prop: .growth
        )
    ]

    var body: some View {
        GeometryReader { proxy in
            let isPad = proxy.size.width >= 760

            ZStack {
                VStack(spacing: 0) {
                    header(isPad: isPad)

                    Spacer(minLength: isPad ? 34 : 24)

                    StandPanel {
                        VStack(spacing: isPad ? 22 : 18) {
                            TabView(selection: $step) {
                                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                                    IntroStoryCard(page: page, isAnimating: isAnimating, isPad: isPad)
                                        .tag(index)
                                        .padding(.horizontal, 2)
                                }
                            }
                            .tabViewStyle(.page(indexDisplayMode: .never))
                            .frame(minHeight: isPad ? 330 : 286)
                            .onChange(of: step) { _, _ in
                                startSceneAnimation()
                            }

                            progressDots

                            HStack(spacing: 10) {
                                Button("Geç") {
                                    finishIntro()
                                }
                                .font(.subheadline.weight(.black))
                                .foregroundStyle(.white.opacity(0.70))
                                .frame(width: isPad ? 120 : 86)
                                .padding(.vertical, isPad ? 18 : 14)
                                .background(Color.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                                PrimaryGameButton(
                                    title: step == pages.count - 1 ? "İşe Başla" : "Devam",
                                    systemImage: step == pages.count - 1 ? "storefront.fill" : "arrow.right"
                                ) {
                                    advance(manual: true)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, isPad ? 40 : 20)
                    .frame(maxWidth: isPad ? 760 : 620)

                    Button("Ana menüye dön") {
                        game.openMainMenu()
                    }
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(.white.opacity(0.62))
                    .padding(.top, isPad ? 22 : 18)

                    Spacer(minLength: isPad ? 30 : 22)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .onAppear {
            resetFirstDayTips()
            startSceneAnimation()
            GameAudio.shared.play(.ferryHorn, volume: 0.22)
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.82), value: step)
        .animation(.easeInOut(duration: 1.8), value: isAnimating)
    }

    private func header(isPad: Bool) -> some View {
        VStack(alignment: .leading, spacing: isPad ? 9 : 6) {
            Text("İlk Gün")
                .font(.system(size: isPad ? 52 : 40, weight: .black, design: .rounded))
                .foregroundStyle(Color.simitCream)
                .lineLimit(1)
                .minimumScaleFactor(0.78)

            Text("Bir tabla, birkaç simit, sıcak çay... Bugünün hesabı buradan çıkacak.")
                .font((isPad ? Font.title3 : Font.subheadline).weight(.bold))
                .foregroundStyle(.white.opacity(0.72))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, isPad ? 48 : 24)
        .padding(.top, isPad ? 72 : 44)
    }

    private var progressDots: some View {
        HStack(spacing: 7) {
            ForEach(0..<pages.count, id: \.self) { index in
                Capsule()
                    .fill(index == step ? Color.simitAmber : Color.white.opacity(0.20))
                    .frame(width: index == step ? 30 : 8, height: 8)
            }
        }
    }

    private func startSceneAnimation() {
        isAnimating = false
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(120))
            isAnimating = true
        }
    }

    private func advance(manual: Bool) {
        if step < pages.count - 1 {
            step += 1
            if manual {
                GameAudio.shared.play(.coin, volume: 0.22)
            }
        } else {
            finishIntro()
        }
    }

    private func finishIntro() {
        GameAudio.shared.play(.upgrade, volume: 0.34)
        game.backHome()
    }

    private func resetFirstDayTips() {
        isFirstDayHomeTipDismissed = false
        isFirstDayMarketTipDismissed = false
        isFirstDayPrepTipDismissed = false
        hasSeenRushCoach = false
    }
}

private struct IntroStoryPage {
    let title: String
    let text: String
    let detail: String
    let systemImage: String
    let prop: IntroStoryProp
}

private enum IntroStoryProp {
    case stand
    case cash
    case customers
    case growth
}

private struct IntroStoryCard: View {
    let page: IntroStoryPage
    let isAnimating: Bool
    let isPad: Bool

    var body: some View {
        VStack(spacing: isPad ? 22 : 18) {
            ZStack {
                RoundedRectangle(cornerRadius: isPad ? 30 : 24, style: .continuous)
                    .fill(Color.black.opacity(0.16))
                    .overlay(
                        RoundedRectangle(cornerRadius: isPad ? 30 : 24, style: .continuous)
                            .stroke(Color.simitCream.opacity(0.14), lineWidth: 1)
                    )

                IntroStoryPropView(prop: page.prop, isAnimating: isAnimating, isPad: isPad)
                    .padding(isPad ? 20 : 14)
            }
            .frame(height: isPad ? 170 : 132)

            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: page.systemImage)
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(Color.simitAmber)

                    Text(page.detail)
                        .font(.caption.weight(.black))
                        .foregroundStyle(Color.simitAmber)
                        .textCase(.uppercase)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }

                Text(page.title)
                    .font(.system(size: isPad ? 34 : 27, weight: .black, design: .rounded))
                    .foregroundStyle(Color.simitCream)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)

                Text(page.text)
                    .font((isPad ? Font.body : Font.subheadline).weight(.semibold))
                    .foregroundStyle(.white.opacity(0.68))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, isPad ? 18 : 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, isPad ? 8 : 4)
    }
}

private struct IntroStoryPropView: View {
    let prop: IntroStoryProp
    let isAnimating: Bool
    let isPad: Bool

    var body: some View {
        switch prop {
        case .stand:
            standScene
        case .cash:
            cashScene
        case .customers:
            customerScene
        case .growth:
            growthScene
        }
    }

    private var standScene: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.simitStand.opacity(0.86))
                .frame(width: isPad ? 280 : 220, height: isPad ? 72 : 56)
                .overlay(
                    Text("SİMİTÇİ")
                        .font(.headline.weight(.black))
                        .foregroundStyle(Color.simitCream)
                        .offset(y: isPad ? 4 : 2)
                )
                .offset(y: isAnimating ? 0 : 18)

            HStack(spacing: isPad ? 10 : 7) {
                ForEach(0..<5, id: \.self) { index in
                    SimitIcon()
                        .frame(width: isPad ? 36 : 28, height: isPad ? 36 : 28)
                        .scaleEffect(isAnimating ? 1 : 0.35)
                        .opacity(isAnimating ? 1 : 0)
                        .animation(.spring(response: 0.42, dampingFraction: 0.72).delay(Double(index) * 0.11), value: isAnimating)
                }
            }
            .offset(y: isPad ? -58 : -44)
        }
    }

    private var cashScene: some View {
        HStack(spacing: isPad ? 18 : 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("KASA")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white.opacity(0.55))
                Text("520 TL")
                    .font(.system(size: isPad ? 36 : 28, weight: .black, design: .rounded))
                    .foregroundStyle(Color.simitCream)
                Text("İlk stok dikkat ister")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.52))
            }

            Spacer(minLength: 0)

            VStack(spacing: 8) {
                CashLine(title: "Kira", amount: "120")
                CashLine(title: "Stok", amount: "300")
                CashLine(title: "Pay", amount: "100")
            }
            .offset(x: isAnimating ? 0 : 24)
            .opacity(isAnimating ? 1 : 0)
        }
        .padding(.horizontal, isPad ? 28 : 16)
    }

    private var customerScene: some View {
        HStack(spacing: isPad ? 22 : 14) {
            ForEach(Array([CustomerType.student, .taxiDriver, .elder].enumerated()), id: \.offset) { index, type in
                VStack(spacing: 7) {
                    CustomerAvatar(type: type, size: isPad ? 64 : 52)
                    Text(type.displayName)
                        .font(.caption.weight(.black))
                        .foregroundStyle(Color.simitCream)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
                .offset(x: isAnimating ? 0 : 80, y: index == 1 ? (isAnimating ? -8 : 8) : 0)
                .opacity(isAnimating ? 1 : 0)
                .animation(.spring(response: 0.44, dampingFraction: 0.76).delay(Double(index) * 0.16), value: isAnimating)
            }
        }
    }

    private var growthScene: some View {
        HStack(spacing: isPad ? 18 : 12) {
            StageBadge(title: "Tabla", icon: "cart.fill", active: true)
            Image(systemName: "chevron.right")
                .font(.headline.weight(.black))
                .foregroundStyle(Color.simitAmber.opacity(0.8))
                .opacity(isAnimating ? 1 : 0.25)
            StageBadge(title: "Büyük Tabla", icon: "shippingbox.fill", active: isAnimating)
            Image(systemName: "chevron.right")
                .font(.headline.weight(.black))
                .foregroundStyle(Color.simitAmber.opacity(0.8))
                .opacity(isAnimating ? 1 : 0.25)
            StageBadge(title: "Dükkân", icon: "storefront.fill", active: isAnimating)
        }
        .scaleEffect(isAnimating ? 1 : 0.94)
    }
}

private struct SimitIcon: View {
    var body: some View {
        Circle()
            .trim(from: 0.12, to: 0.92)
            .stroke(Color.simitAmber, style: StrokeStyle(lineWidth: 8, lineCap: .round))
            .rotationEffect(.degrees(18))
            .overlay(
                Circle()
                    .stroke(Color.simitCream.opacity(0.34), lineWidth: 2)
                    .padding(8)
            )
    }
}

private struct CashLine: View {
    let title: String
    let amount: String

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.caption.weight(.black))
                .foregroundStyle(Color.simitCream)
                .frame(width: 42, alignment: .leading)
            Text("-\(amount) TL")
                .font(.caption.weight(.black))
                .foregroundStyle(Color.simitDanger.opacity(0.9))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.black.opacity(0.18), in: Capsule())
    }
}

private struct StageBadge: View {
    let title: String
    let icon: String
    let active: Bool

    var body: some View {
        VStack(spacing: 6) {
            StageBusinessIcon(title: title, active: active)
                .frame(width: 56, height: 48)
            Text(title)
                .font(.caption2.weight(.black))
                .foregroundStyle(active ? Color.simitCream : .white.opacity(0.46))
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
    }
}

private struct StageBusinessIcon: View {
    let title: String
    let active: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(active ? Color.simitAmber.opacity(0.92) : Color.white.opacity(0.10))
                .frame(width: 54, height: 44)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.simitCream.opacity(active ? 0.34 : 0.12), lineWidth: 1)
                )

            if title == "Dükkân" {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color.simitStand.opacity(active ? 0.86 : 0.44))
                    .frame(width: 34, height: 28)
                    .overlay(alignment: .top) {
                        HStack(spacing: 2) {
                            ForEach(0..<4, id: \.self) { index in
                                RoundedRectangle(cornerRadius: 1.5)
                                    .fill(index.isMultiple(of: 2) ? Color.simitCream.opacity(0.88) : Color.simitDanger.opacity(0.82))
                                    .frame(width: 7, height: 8)
                            }
                        }
                        .offset(y: -5)
                    }
            } else {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.simitStand.opacity(active ? 0.92 : 0.42))
                    .frame(width: title == "Büyük Tabla" ? 40 : 31, height: title == "Büyük Tabla" ? 20 : 16)
                    .overlay(alignment: .top) {
                        HStack(spacing: 3) {
                            ForEach(0..<(title == "Büyük Tabla" ? 4 : 3), id: \.self) { _ in
                                SimitIcon()
                                    .frame(width: 9, height: 9)
                            }
                        }
                        .offset(y: -12)
                    }
                    .overlay(alignment: .bottom) {
                        Capsule()
                            .fill(Color.black.opacity(0.36))
                            .frame(width: title == "Büyük Tabla" ? 44 : 34, height: 4)
                            .offset(y: 7)
                    }
            }
        }
        .opacity(active ? 1 : 0.62)
    }
}
