import SwiftUI

struct RushView: View {
    @ObservedObject var game: GameSession

    var body: some View {
        if let rush = game.rush {
            RushContentView(game: game, rush: rush)
        } else {
            ProgressView()
        }
    }
}

private struct RushContentView: View {
    @ObservedObject var game: GameSession
    @ObservedObject var rush: RushEngine
    @State private var lastCountdownSecond: Int?
    @State private var coachStep = 0
    @State private var showsCoach = false
    @State private var hasPlayedComboHotSound = false
    @State private var comboIgnition = 0
    @AppStorage("simitci-rush-coach-seen") private var hasSeenRushCoach = false
    @AppStorage("simitci-rush-haptics-enabled") private var hapticsEnabled = true

    var body: some View {
        GeometryReader { proxy in
            let isPad = proxy.size.width > 700
            let stageHeight = isPad ? min(640, max(500, proxy.size.height * 0.52)) : max(326, min(354, proxy.size.height * 0.41))

            ZStack {
                VStack(spacing: isPad ? 18 : 8) {
                    CompactRushHUDView(rush: rush, comboIgnition: comboIgnition)
                        .frame(maxWidth: isPad ? 940 : .infinity)

                    CustomerStageView(rush: rush) { response in
                        rush.chooseDialogue(response)
                    }
                    .frame(height: stageHeight)
                    .frame(maxWidth: isPad ? 1040 : .infinity)

                    if isPad {
                        Spacer(minLength: 10)
                    }

                    RushCounterPanel(rush: rush)
                        .frame(maxWidth: isPad ? 1040 : .infinity)
                }
                .padding(.horizontal, isPad ? 64 : 10)
                .padding(.top, isPad ? 54 : 8)
                .padding(.bottom, isPad ? 34 : 8)
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)

                if showsCoach {
                    RushCoachOverlay(step: coachStep, isPad: isPad) {
                        advanceCoach()
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    .zIndex(5)
                }

                if let event = rush.serviceEvent {
                    ServiceEventOverlay(event: event, isPad: isPad)
                        .id(event.id)
                        .allowsHitTesting(false)
                        .transition(.opacity)
                        .zIndex(4)
                }
            }
        }
        .onAppear {
            if !hasSeenRushCoach {
                rush.pause()
                coachStep = 0
                showsCoach = true
            }
        }
        .onChange(of: rush.timeRemaining) { _, value in
            let second = Int(ceil(value))
            if second != lastCountdownSecond {
                lastCountdownSecond = second
                if (1...3).contains(second) {
                    GameAudio.shared.play(.countdown, volume: 0.58)
                } else if second == 0 {
                    GameAudio.shared.play(.rushEnd, volume: 0.72)
                }
            }

            if value <= 0 {
                game.finishRush()
            }
        }
        .onChange(of: rush.combo) { oldValue, newValue in
            if newValue >= 5, oldValue < 5, !hasPlayedComboHotSound {
                hasPlayedComboHotSound = true
                comboIgnition += 1
                GameAudio.shared.play(.upgrade, volume: 0.20)
            }
        }
        .sensoryFeedback(.success, trigger: comboIgnition) { _, _ in
            hapticsEnabled
        }
        .sensoryFeedback(.success, trigger: rush.servedCount) { _, _ in
            hapticsEnabled
        }
        .sensoryFeedback(.warning, trigger: rush.missedCount) { _, _ in
            hapticsEnabled
        }
        .sensoryFeedback(.error, trigger: rush.wrongCount) { _, _ in
            hapticsEnabled
        }
        .animation(.snappy(duration: 0.22), value: rush.activeCustomer.id)
    }

    private func advanceCoach() {
        if coachStep < RushCoachOverlay.steps.count - 1 {
            coachStep += 1
            GameAudio.shared.play(.coin, volume: 0.18)
        } else {
            hasSeenRushCoach = true
            showsCoach = false
            rush.resume()
            GameAudio.shared.play(.upgrade, volume: 0.24)
        }
    }
}

private struct RushCoachOverlay: View {
    let step: Int
    let isPad: Bool
    let next: () -> Void

    static let steps: [(String, String, String)] = [
        ("Siparişi oku", "Müşterinin istediği ürünler kartta görünür. Önce siparişi kontrol et.", "bubble.left.and.text.bubble.right.fill"),
        ("Ürüne dokun", "İstenen ürünler altta başa gelir. Listeyi kaydır, doğru ürüne dokun.", "hand.tap.fill"),
        ("Servisi bitir", "Seçim doğruysa Servis Et. Ürün bittiyse Stok Yok De.", "checkmark.seal.fill")
    ]

    private var current: (String, String, String) {
        Self.steps[min(step, Self.steps.count - 1)]
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.54)
                .ignoresSafeArea()

            VStack {
                Spacer()

                CoachPanel {
                    VStack(alignment: .leading, spacing: isPad ? 16 : 12) {
                        HStack(spacing: 12) {
                            Image(systemName: current.2)
                                .font((isPad ? Font.title2 : Font.headline).weight(.black))
                                .foregroundStyle(.black.opacity(0.82))
                                .frame(width: isPad ? 52 : 44, height: isPad ? 52 : 44)
                                .background(Color.simitAmber, in: Circle())

                            VStack(alignment: .leading, spacing: 3) {
                                Text(current.0)
                                    .font((isPad ? Font.title2 : Font.headline).weight(.black))
                                    .foregroundStyle(Color.simitAmber)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.78)
                                Text(current.1)
                                    .font((isPad ? Font.subheadline : Font.caption2).weight(.bold))
                                    .foregroundStyle(Color.simitCream.opacity(0.86))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        HStack(spacing: 7) {
                            ForEach(0..<Self.steps.count, id: \.self) { index in
                                Capsule()
                                    .fill(index == step ? Color.simitAmber : Color.white.opacity(0.18))
                                    .frame(width: index == step ? 26 : 8, height: 7)
                            }
                        }

                        Button(action: next) {
                            Label(step == Self.steps.count - 1 ? "Başla" : "Devam", systemImage: "arrow.right")
                                .font(.subheadline.weight(.black))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(Color.simitAmber, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .foregroundStyle(.black.opacity(0.82))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: isPad ? 560 : .infinity)
                .padding(.horizontal, isPad ? 42 : 24)
                .padding(.bottom, isPad ? 210 : 138)
            }
        }
    }
}

private struct CompactRushHUDView: View {
    @ObservedObject var rush: RushEngine
    let comboIgnition: Int

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        HStack(spacing: isPad ? 12 : 6) {
            CompactHUDItem(title: "Süre", value: "\(Int(ceil(rush.timeRemaining)))", systemImage: "timer", tint: rush.timeRemaining <= 10 ? .simitDanger : .simitAmber, isUrgent: rush.timeRemaining <= 10)
            CompactHUDItem(title: "Kasa", value: "\(rush.earnedCash)", systemImage: "banknote.fill", tint: .simitSuccess)
            CompactHUDItem(title: "Mutlu", value: "\(rush.happiness)", systemImage: "heart.fill", tint: .simitDanger)
            CompactHUDItem(title: "Combo", value: "x\(rush.combo)", systemImage: "bolt.fill", tint: rush.combo >= 5 ? .simitAmber : .simitTeal, isComboHot: rush.combo >= 5, burstTrigger: comboIgnition)
        }
        .padding(isPad ? 11 : 6)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.66), Color.simitBackgroundDeep.opacity(0.62), Color.black.opacity(0.42)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: isPad ? 26 : 21, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: isPad ? 26 : 21, style: .continuous)
                .stroke(Color.simitCream.opacity(0.20), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.34), radius: 18, y: 8)
    }
}

private struct CompactHUDItem: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color
    var isComboHot = false
    var isUrgent = false
    var burstTrigger = 0
    @State private var showsBurst = false

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    private var shortTitle: String {
        switch title {
        case "Mutlu": "Mut."
        case "Combo": "Com."
        default: title
        }
    }

    var body: some View {
        VStack(spacing: isPad ? 3 : 2) {
            HStack(spacing: isPad ? 8 : 5) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(isComboHot || isUrgent ? 0.28 : 0.16))
                    Image(systemName: systemImage)
                        .font((isPad ? Font.headline : Font.caption).weight(.black))
                        .foregroundStyle(tint)
                        .scaleEffect(isComboHot ? 1.18 : 1)
                        .shadow(color: tint.opacity(isComboHot || isUrgent ? 0.78 : 0), radius: isComboHot || isUrgent ? 10 : 0)
                }
                .frame(width: isPad ? 38 : 24, height: isPad ? 38 : 24)

                Text(value)
                    .font((isPad ? Font.title2 : Font.headline).weight(.black))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)
                    .contentTransition(.numericText())
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(shortTitle)
                .font(.system(size: isPad ? 10 : 7, weight: .black))
                .foregroundStyle(.white.opacity(0.54))
                .lineLimit(1)
                .minimumScaleFactor(0.68)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, isPad ? 13 : 7)
        .padding(.vertical, isPad ? 12 : 7)
        .background(
            LinearGradient(
                colors: [tint.opacity(isComboHot || isUrgent ? 0.26 : 0.13), Color.white.opacity(0.055), Color.black.opacity(0.18)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: isPad ? 18 : 15, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: isPad ? 18 : 15, style: .continuous)
                .stroke(tint.opacity(isComboHot || isUrgent ? 0.58 : 0.16), lineWidth: isComboHot || isUrgent ? 1.3 : 1)
        )
        .scaleEffect(isComboHot || isUrgent ? 1.025 : 1)
        .overlay(alignment: .topTrailing) {
            if showsBurst {
                ComboIgnitionBurst()
                    .offset(x: isPad ? 10 : 6, y: isPad ? -17 : -13)
                    .transition(.scale(scale: 0.72).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.42).repeatCount(isComboHot ? 2 : 1, autoreverses: true), value: isComboHot)
        .onChange(of: burstTrigger) { _, value in
            guard value > 0 else { return }
            showsBurst = true
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(620))
                showsBurst = false
            }
        }
    }
}

private struct ComboIgnitionBurst: View {
    @State private var expanded = false

    var body: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { index in
                Image(systemName: index.isMultiple(of: 2) ? "flame.fill" : "sparkle")
                    .font(.system(size: index.isMultiple(of: 2) ? 15 : 11, weight: .black))
                    .foregroundStyle(index.isMultiple(of: 2) ? Color.simitAmber : Color.simitCream)
                    .offset(
                        x: expanded ? CGFloat(index - 2) * 8 : 0,
                        y: expanded ? CGFloat(index.isMultiple(of: 2) ? -18 : -9) : 0
                    )
                    .opacity(expanded ? 0 : 1)
            }

            Image(systemName: "flame.fill")
                .font(.system(size: 20, weight: .black))
                .foregroundStyle(Color.simitAmber)
                .shadow(color: Color.simitAmber.opacity(0.65), radius: 10)
                .scaleEffect(expanded ? 1.24 : 0.78)
        }
        .onAppear {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.58)) {
                expanded = true
            }
        }
    }
}

private struct ServiceEventOverlay: View {
    let event: RushServiceEvent
    let isPad: Bool
    @State private var animate = false
    @State private var rewardVisible = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if event.kind == .success {
                    ForEach(Array(event.products.prefix(4).enumerated()), id: \.offset) { index, productID in
                        let product = Products.definition(for: productID)
                        ProductMark(product: product, size: isPad ? 58 : 42)
                            .padding(isPad ? 12 : 8)
                            .background(
                                Circle()
                                    .fill(Color.simitCream.opacity(0.94))
                                    .shadow(color: Color.simitAmber.opacity(0.45), radius: 12, y: 6)
                            )
                            .scaleEffect(animate ? 0.56 : 1)
                            .opacity(animate ? 0 : 1)
                            .position(
                                x: animate ? proxy.size.width * 0.42 + CGFloat(index) * 18 : proxy.size.width * 0.28 + CGFloat(index) * (isPad ? 76 : 54),
                                y: animate ? proxy.size.height * 0.40 : proxy.size.height * (isPad ? 0.77 : 0.80)
                            )
                            .animation(.spring(response: 0.52, dampingFraction: 0.74).delay(Double(index) * 0.035), value: animate)
                    }

                    FloatingRewardPill(total: event.total, combo: event.combo, isPad: isPad)
                        .position(x: proxy.size.width * 0.50, y: proxy.size.height * (isPad ? 0.34 : 0.37))
                        .scaleEffect(rewardVisible ? 1 : 0.72)
                        .opacity(rewardVisible ? 1 : 0)
                        .offset(y: rewardVisible ? -16 : 8)
                        .animation(.spring(response: 0.28, dampingFraction: 0.62).delay(0.08), value: rewardVisible)
                } else {
                    ServiceReactionPill(kind: event.kind, isPad: isPad)
                        .position(x: proxy.size.width * 0.50, y: proxy.size.height * 0.42)
                        .scaleEffect(animate ? 1 : 0.86)
                        .opacity(animate ? 1 : 0)
                        .animation(.spring(response: 0.24, dampingFraction: 0.68), value: animate)
                }
            }
        }
        .onAppear {
            animate = true
            rewardVisible = event.kind == .success
            if event.kind == .success {
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(620))
                    rewardVisible = false
                }
            }
        }
    }
}

private struct FloatingRewardPill: View {
    let total: Int
    let combo: Int
    let isPad: Bool

    var body: some View {
        HStack(spacing: isPad ? 10 : 7) {
            ZStack {
                Circle()
                    .fill(Color.simitAmber)
                Image(systemName: "turkishlirasign")
                    .font(.system(size: isPad ? 15 : 12, weight: .black))
                    .foregroundStyle(.black.opacity(0.82))
            }
            .frame(width: isPad ? 34 : 28, height: isPad ? 34 : 28)

            VStack(alignment: .leading, spacing: 0) {
                Text("+\(total) TL")
                    .font(.system(size: isPad ? 22 : 18, weight: .black, design: .rounded))
                    .foregroundStyle(Color.simitCream)
                    .contentTransition(.numericText())
                if combo >= 3 {
                    Text("Combo x\(combo)")
                        .font(.system(size: isPad ? 11 : 9, weight: .black))
                        .foregroundStyle(Color.simitAmber)
                }
            }
        }
        .padding(.horizontal, isPad ? 15 : 12)
        .padding(.vertical, isPad ? 10 : 8)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.70), Color.simitStand.opacity(0.78)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: Capsule()
        )
        .overlay(Capsule().stroke(Color.simitAmber.opacity(0.42), lineWidth: 1))
        .shadow(color: Color.simitAmber.opacity(0.30), radius: 16, y: 8)
    }
}

private struct ServiceReactionPill: View {
    let kind: RushServiceEventKind
    let isPad: Bool

    private var text: String {
        switch kind {
        case .success: "Servis tamam"
        case .wrong: "Yanlış sipariş"
        case .missed: "Müşteri gitti"
        }
    }

    private var icon: String {
        switch kind {
        case .success: "checkmark.seal.fill"
        case .wrong: "xmark.octagon.fill"
        case .missed: "figure.walk.departure"
        }
    }

    private var tint: Color {
        switch kind {
        case .success: .simitSuccess
        case .wrong: .simitDanger
        case .missed: .simitAmber
        }
    }

    var body: some View {
        Label(text, systemImage: icon)
            .font(.system(size: isPad ? 17 : 14, weight: .black))
            .foregroundStyle(Color.simitCream)
            .padding(.horizontal, isPad ? 16 : 13)
            .padding(.vertical, isPad ? 11 : 9)
            .background(tint.opacity(0.84), in: Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.22), lineWidth: 1))
            .shadow(color: tint.opacity(0.35), radius: 12, y: 6)
    }
}

private struct CustomerStageView: View {
    @ObservedObject var rush: RushEngine
    let onDialogue: (DialogueResponse) -> Void
    @State private var stageImpact: CustomerStageImpact = .neutral

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: isPad ? 34 : 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.black.opacity(0.18), avatarColor(for: rush.activeCustomer.type).opacity(0.16), Color.black.opacity(0.42)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: isPad ? 34 : 28, style: .continuous)
                        .stroke(avatarColor(for: rush.activeCustomer.type).opacity(0.34), lineWidth: 1.2)
                )
                .shadow(color: avatarColor(for: rush.activeCustomer.type).opacity(0.20), radius: isPad ? 24 : 16, y: isPad ? 14 : 8)

            ActiveCustomerStageCard(
                customer: rush.activeCustomer,
                patience: rush.customerPatience,
                maxPatience: rush.activeCustomerMaxPatience,
                impact: stageImpact,
                onDialogue: onDialogue
            )
            .id(rush.activeCustomer.id)
            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
            .padding(isPad ? 18 : 12)
        }
        .clipShape(RoundedRectangle(cornerRadius: isPad ? 34 : 28, style: .continuous))
        .animation(.spring(response: 0.28, dampingFraction: 0.62), value: rush.payoutPop?.id)
        .onChange(of: rush.activeCustomer.id) { _, _ in
            stageImpact = .neutral
        }
        .onChange(of: rush.servedCount) { _, _ in flash(.success) }
        .onChange(of: rush.wrongCount) { _, _ in flash(.danger) }
        .onChange(of: rush.missedCount) { _, _ in flash(.warning) }
    }

    private func flash(_ impact: CustomerStageImpact) {
        stageImpact = impact
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(420))
            if stageImpact == impact {
                stageImpact = .neutral
            }
        }
    }
}

private enum CustomerStageImpact {
    case neutral
    case success
    case warning
    case danger

    var tint: Color {
        switch self {
        case .neutral: .clear
        case .success: .simitSuccess
        case .warning: .simitAmber
        case .danger: .simitDanger
        }
    }
}

private struct CustomerArrivalBadge: View {
    let customer: Customer

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        HStack(spacing: isPad ? 10 : 8) {
            CustomerAvatar(type: customer.type, size: isPad ? 38 : 30)
            VStack(alignment: .leading, spacing: 1) {
                Text("Müşteri geldi")
                    .font(.caption.weight(.black))
                    .foregroundStyle(Color.simitCream)
                Text(customer.type.displayName)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.58))
            }
        }
        .padding(.horizontal, isPad ? 14 : 11)
        .padding(.vertical, isPad ? 10 : 8)
        .background(Color.black.opacity(0.44), in: Capsule())
        .overlay(Capsule().stroke(avatarColor(for: customer.type).opacity(0.44), lineWidth: 1))
        .shadow(color: .black.opacity(0.28), radius: 10, y: 6)
    }
}

private struct ComboBonusPopView: View {
    let pop: PayoutPop
    @State private var isVisible = false

    var body: some View {
        ZStack {
            if pop.bonus > 0 {
                CoinBurstView()
                    .offset(y: isVisible ? -26 : 4)
                    .opacity(isVisible ? 1 : 0)
            }

            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: pop.bonus > 0 ? "bolt.fill" : "banknote.fill")
                        .font(.headline.weight(.black))
                    Text("+\(pop.total) TL")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .contentTransition(.numericText())
                }

                Text(pop.bonus > 0 ? "COMBO x\(pop.combo) · +\(pop.bonus) TL bonus" : "SERVİS TAMAM")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(.black.opacity(0.62))

                if pop.bonus > 0 {
                    Text("\(pop.base) + \(pop.bonus) = \(pop.total)")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(.black.opacity(0.48))
                }
            }
            .foregroundStyle(.black.opacity(0.82))
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [Color.simitAmber, Color.simitCream],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.45), lineWidth: 1)
            )
            .shadow(color: Color.simitAmber.opacity(0.34), radius: 16, x: 0, y: 8)
            .scaleEffect(isVisible ? 1 : 0.82)
            .offset(y: isVisible ? -8 : 6)
        }
        .onAppear {
            withAnimation(.spring(response: 0.30, dampingFraction: 0.58)) {
                isVisible = true
            }
        }
    }
}

private struct CoinBurstView: View {
    var body: some View {
        HStack(spacing: 18) {
            ForEach(0..<4, id: \.self) { index in
                Image(systemName: index.isMultiple(of: 2) ? "turkishlirasign.circle.fill" : "sparkle")
                    .font(.system(size: index.isMultiple(of: 2) ? 18 : 13, weight: .black))
                    .foregroundStyle(index.isMultiple(of: 2) ? Color.simitAmber : Color.simitCream)
                    .offset(x: CGFloat(index - 2) * 5, y: index.isMultiple(of: 2) ? -8 : 6)
            }
        }
        .shadow(color: Color.simitAmber.opacity(0.45), radius: 10, y: 4)
    }
}

private struct StageComboPill: View {
    let combo: Int

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "bolt.fill")
                .foregroundStyle(combo > 0 ? Color.simitAmber : .white.opacity(0.36))
            Text("x\(combo)")
                .contentTransition(.numericText())

            HStack(spacing: 3) {
                ForEach(0..<5, id: \.self) { index in
                    Capsule()
                        .fill(index < min(5, combo) ? Color.simitAmber : Color.white.opacity(0.14))
                        .frame(width: 18, height: 6)
                }
            }
        }
        .font(.caption.weight(.black))
        .foregroundStyle(Color.simitCream)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.black.opacity(0.34), in: Capsule())
    }
}

private struct StageQueueView: View {
    let queue: [Customer]

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: isPad ? 12 : 8) {
            ForEach(Array(queue.prefix(3).enumerated()), id: \.element.id) { index, customer in
                VStack(spacing: isPad ? 8 : 6) {
                    CustomerAvatar(type: customer.type, size: isPad ? (index == 0 ? 72 : 62) : (index == 0 ? 56 : 48))
                        .opacity(index == 0 ? 1 : 0.72)

                    VStack(spacing: 1) {
                        Text(index == 0 ? "Sıradaki" : "#\(index + 1)")
                            .font(.system(size: isPad ? 11 : 9, weight: .black))
                            .foregroundStyle(.white.opacity(index == 0 ? 0.70 : 0.44))
                        Text(customer.type.displayName)
                            .font(.system(size: isPad ? 11 : 9, weight: .black))
                            .foregroundStyle(Color.simitCream.opacity(index == 0 ? 0.86 : 0.52))
                            .lineLimit(1)
                            .minimumScaleFactor(0.70)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, isPad ? 12 : 8)
                .background(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(index == 0 ? 0.28 : 0.18),
                            avatarColor(for: customer.type).opacity(index == 0 ? 0.18 : 0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: isPad ? 22 : 18, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: isPad ? 22 : 18, style: .continuous)
                        .stroke(index == 0 ? Color.simitAmber.opacity(0.30) : Color.white.opacity(0.08), lineWidth: 1)
                )
                .offset(y: CGFloat(index) * (isPad ? 8 : 6))
            }
        }
    }
}

private struct ActiveCustomerStageCard: View {
    let customer: Customer
    let patience: Double
    let maxPatience: Double
    let impact: CustomerStageImpact
    let onDialogue: (DialogueResponse) -> Void
    @State private var hasArrived = false

    private var isPatienceCritical: Bool {
        patience <= min(2, maxPatience * 0.35)
    }

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        VStack(spacing: isPad ? 16 : 10) {
            HStack(alignment: .center, spacing: isPad ? 20 : 14) {
                ZStack(alignment: .bottomTrailing) {
                    CustomerAvatar(type: customer.type, size: isPad ? 126 : 96)
                        .scaleEffect(isPatienceCritical ? 1.05 : 1)
                        .shadow(color: avatarColor(for: customer.type).opacity(0.42), radius: isPad ? 22 : 15, y: 9)

                    Image(systemName: customer.type.smallSymbol)
                        .font(.system(size: isPad ? 18 : 14, weight: .black))
                        .foregroundStyle(.black.opacity(0.78))
                        .frame(width: isPad ? 38 : 30, height: isPad ? 38 : 30)
                        .background(Color.simitCream, in: Circle())
                        .overlay(Circle().stroke(Color.black.opacity(0.16), lineWidth: 1))
                }

                VStack(alignment: .leading, spacing: isPad ? 8 : 6) {
                    HStack(alignment: .firstTextBaseline, spacing: isPad ? 10 : 7) {
                        Text(customer.type.displayName)
                            .font(.system(size: isPad ? 34 : 25, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)

                        if isPatienceCritical {
                            Label("Acele", systemImage: "exclamationmark.triangle.fill")
                                .font(.system(size: isPad ? 12 : 9, weight: .black))
                                .foregroundStyle(Color.simitCream)
                                .padding(.horizontal, isPad ? 10 : 8)
                                .padding(.vertical, isPad ? 6 : 4)
                                .background(Color.simitDanger.opacity(0.88), in: Capsule())
                        }
                    }

                    Text(patienceText)
                        .font(.system(size: isPad ? 15 : 10, weight: .black))
                        .foregroundStyle(Color.simitCream.opacity(0.62))
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Image(systemName: "bag.fill")
                            .font(.system(size: isPad ? 13 : 10, weight: .black))
                            .foregroundStyle(Color.simitAmber)
                        Text(orderTitle)
                            .font(.system(size: isPad ? 13 : 10, weight: .black))
                            .textCase(.uppercase)
                            .foregroundStyle(Color.simitAmber.opacity(0.90))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            OrderBubble(order: customer.order)

            CustomerPatienceRail(
                text: isPatienceCritical ? "Sabır azalıyor" : patienceText,
                patience: patience,
                maxPatience: maxPatience,
                isCritical: isPatienceCritical,
                isPad: isPad
            )

            if let dialogue = customer.dialogue {
                DialoguePanel(dialogue: dialogue, onDialogue: onDialogue)
                    .frame(maxWidth: isPad ? 520 : .infinity)
                    .padding(.top, isPad ? 2 : 0)
                    .transition(.scale(scale: 0.96, anchor: .bottom).combined(with: .opacity))
            } else {
                Spacer(minLength: 0)
            }
        }
        .padding(isPad ? 20 : 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            ZStack {
                RadialGradient(
                    colors: [avatarColor(for: customer.type).opacity(0.34), .clear],
                    center: .topLeading,
                    startRadius: 10,
                    endRadius: isPad ? 360 : 240
                )
                LinearGradient(
                    colors: [Color.white.opacity(0.08), Color.black.opacity(0.08), Color.black.opacity(0.34)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: isPad ? 30 : 24, style: .continuous))
        }
        .overlay(
            RoundedRectangle(cornerRadius: isPad ? 30 : 24, style: .continuous)
                .stroke(isPatienceCritical ? Color.simitDanger.opacity(0.70) : Color.simitCream.opacity(0.14), lineWidth: isPatienceCritical ? 1.8 : 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: isPad ? 30 : 24, style: .continuous)
                .stroke(impact.tint.opacity(impact == .neutral ? 0 : 0.82), lineWidth: impact == .neutral ? 0 : 2)
                .shadow(color: impact.tint.opacity(impact == .neutral ? 0 : 0.42), radius: 14, y: 4)
        )
        .shadow(color: avatarColor(for: customer.type).opacity(0.20), radius: 20, x: 0, y: 10)
        .shadow(color: .black.opacity(0.34), radius: 18, x: 0, y: 11)
        .scaleEffect(hasArrived ? (impact == .success ? 1.018 : 1) : 0.94)
        .offset(x: impact == .danger ? -7 : (impact == .warning ? 5 : 0), y: hasArrived ? 0 : 18)
        .opacity(hasArrived ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) {
                hasArrived = true
            }
        }
        .animation(.easeInOut(duration: 0.10).repeatCount(3, autoreverses: true), value: impact)
    }

    private var orderTitle: String {
        customer.order.count == 1 ? "İstediği ürün" : "İstediği ürünler"
    }

    private var patienceText: String {
        switch customer.type {
        case .rushed: "Aceleci müşteri"
        case .elder: "Sakin bekliyor"
        case .tourist: "Siparişi inceliyor"
        case .student: "Hesap yapıyor"
        case .taxiDriver: "Yola çıkacak"
        case .officeWorker: "Servis bekliyor"
        }
    }
}

private struct CustomerPatienceRail: View {
    let text: String
    let patience: Double
    let maxPatience: Double
    let isCritical: Bool
    let isPad: Bool

    private var progress: Double {
        guard maxPatience > 0 else { return 0 }
        return max(0, min(1, patience / maxPatience))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isPad ? 8 : 6) {
            HStack(spacing: 8) {
                Image(systemName: isCritical ? "exclamationmark.triangle.fill" : "clock.fill")
                    .font(.system(size: isPad ? 12 : 10, weight: .black))
                    .foregroundStyle(statusColor)

                Text(text)
                    .font((isPad ? Font.caption : Font.caption2).weight(.black))
                    .foregroundStyle(isCritical ? Color.simitDanger : Color.simitCream.opacity(0.70))

                Spacer(minLength: 0)

                Text(isCritical ? "ACELE" : "BEKLİYOR")
                    .font(.system(size: isPad ? 10 : 8, weight: .black))
                    .foregroundStyle(isCritical ? Color.simitDanger : Color.simitTeal)
                    .padding(.horizontal, isPad ? 9 : 7)
                    .padding(.vertical, isPad ? 5 : 4)
                    .background(statusColor.opacity(0.14), in: Capsule())
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.11))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [statusColor, isCritical ? Color.simitDanger : Color.simitTeal.opacity(0.78)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: proxy.size.width * progress)
                }
            }
            .frame(height: isPad ? 8 : 6)
        }
        .padding(.horizontal, isPad ? 14 : 11)
        .padding(.vertical, isPad ? 11 : 9)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.24), statusColor.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: isPad ? 18 : 15, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: isPad ? 18 : 15, style: .continuous)
                .stroke(statusColor.opacity(isCritical ? 0.42 : 0.18), lineWidth: 1)
        )
    }

    private var statusColor: Color {
        isCritical ? Color.simitDanger : Color.simitTeal
    }
}

private struct RushCounterPanel: View {
    @ObservedObject var rush: RushEngine

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: isPad ? 13 : 9) {
                ServiceStatusStrip(rush: rush)
                ProductShelfView(rush: rush)
                ServiceActionBar(rush: rush)
                FeedbackBanner(message: rush.feedback, kind: rush.feedbackKind)
            }

        }
        .animation(.snappy(duration: 0.22), value: rush.combo)
        .animation(.spring(response: 0.28, dampingFraction: 0.62), value: rush.payoutPop?.id)
        .padding(isPad ? 18 : 10)
        .background(
            LinearGradient(
                colors: [
                    Color.black.opacity(0.54),
                    Color.simitStand.opacity(0.34),
                    Color.simitBackgroundDeep.opacity(0.92)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: isPad ? 28 : 22, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: isPad ? 28 : 22, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.simitCream.opacity(0.20), Color.simitAmber.opacity(0.16), Color.white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.30), radius: isPad ? 24 : 16, y: isPad ? 14 : 9)
    }
}

private struct RushRhythmStrip: View {
    @ObservedObject var rush: RushEngine

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    private var progress: Double {
        min(1, Double(min(6, rush.combo)) / 6)
    }

    var body: some View {
        HStack(spacing: isPad ? 14 : 10) {
            ZStack {
                Circle()
                    .fill(Color.simitAmber.opacity(0.18))
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.simitAmber, style: StrokeStyle(lineWidth: isPad ? 5 : 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: "bolt.fill")
                    .font((isPad ? Font.title3 : Font.subheadline).weight(.black))
                    .foregroundStyle(Color.simitAmber)
            }
            .frame(width: isPad ? 54 : 42, height: isPad ? 54 : 42)

            VStack(alignment: .leading, spacing: isPad ? 6 : 4) {
                HStack(spacing: 8) {
                    Text(rush.combo > 0 ? "Tempo x\(rush.combo)" : "Servis temposu")
                        .font((isPad ? Font.headline : Font.subheadline).weight(.black))
                        .foregroundStyle(Color.simitCream)
                        .contentTransition(.numericText())
                    if rush.combo >= 3 {
                        Text(rush.combo >= 6 ? "+%20" : "+%10")
                            .font(.system(size: isPad ? 12 : 10, weight: .black))
                            .foregroundStyle(.black.opacity(0.82))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.simitAmber, in: Capsule())
                    }
                }

                Text(rush.combo >= 3 ? "Seri servis bonus kazandırır." : "Doğru servisleri art arda yap, bonus açılır.")
                    .font((isPad ? Font.caption : Font.caption2).weight(.bold))
                    .foregroundStyle(.white.opacity(0.52))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            Spacer(minLength: 0)

            HStack(spacing: 4) {
                ForEach(0..<6, id: \.self) { index in
                    Capsule()
                        .fill(index < min(6, rush.combo) ? Color.simitAmber : Color.white.opacity(0.13))
                        .frame(width: isPad ? 20 : 14, height: isPad ? 8 : 6)
                }
            }
        }
        .padding(isPad ? 14 : 11)
        .background(Color.black.opacity(0.18), in: RoundedRectangle(cornerRadius: isPad ? 18 : 15, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: isPad ? 18 : 15, style: .continuous)
                .stroke(Color.simitAmber.opacity(rush.combo > 0 ? 0.34 : 0.13), lineWidth: 1)
        )
    }
}

private struct ComboMeterView: View {
    let combo: Int

    private var filledSegments: Int {
        min(5, combo)
    }

    var body: some View {
        HStack(spacing: 8) {
            Label("Combo x\(combo)", systemImage: "bolt.fill")
                .font(.caption.weight(.black))
                .foregroundStyle(combo > 0 ? Color.simitAmber : .white.opacity(0.42))

            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { index in
                    Capsule()
                        .fill(index < filledSegments ? Color.simitAmber : Color.white.opacity(0.12))
                        .frame(height: 8)
                }
            }
            .frame(maxWidth: .infinity)

            Text(combo >= 6 ? "+20%" : (combo >= 3 ? "+10%" : ""))
                .font(.caption2.weight(.black))
                .foregroundStyle(Color.simitSuccess)
                .frame(width: 42, alignment: .trailing)
        }
        .padding(10)
        .background(Color.black.opacity(0.20), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct RushSceneStrip: View {
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            GameBackgroundArtwork()
                .scaledToFill()
                .frame(height: 92)
                .clipped()
                .overlay(
                    LinearGradient(
                        colors: [
                            .black.opacity(0.05),
                            .black.opacity(0.42)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .frame(height: 92)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.simitCream.opacity(0.18), lineWidth: 1)
        )
    }
}

private struct TopHUDView: View {
    @ObservedObject var rush: RushEngine

    var body: some View {
        HStack(spacing: 10) {
            HUDPill(title: "Süre", value: "\(Int(ceil(rush.timeRemaining)))", systemImage: "timer", tint: rush.timeRemaining <= 10 ? .simitDanger : .simitAmber, isPulsing: rush.timeRemaining <= 10)
            HUDPill(title: "Kasa", value: "\(rush.earnedCash)", systemImage: "banknote.fill", tint: .simitSuccess)
            HUDPill(title: "Mutlu", value: "\(rush.happiness)", systemImage: "heart.fill", tint: .simitDanger)
            HUDPill(title: "Combo", value: "x\(rush.combo)", systemImage: "bolt.fill", tint: .simitTeal)
        }
    }
}

private struct HUDPill: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color
    var isPulsing: Bool = false

    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: systemImage)
                .font(.caption.weight(.black))
                .foregroundStyle(tint)
            Text(value)
                .font(.headline.weight(.black))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.65)
                .lineLimit(1)
            Text(title.uppercased())
                .font(.system(size: 8, weight: .black))
                .foregroundStyle(.white.opacity(0.42))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .background(Color.black.opacity(isPulsing ? 0.34 : 0.20), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(tint.opacity(isPulsing ? 0.62 : 0.20), lineWidth: isPulsing ? 1.5 : 1)
        )
        .scaleEffect(isPulsing ? 1.03 : 1)
        .animation(.easeInOut(duration: 0.32).repeatCount(isPulsing ? 2 : 1, autoreverses: true), value: isPulsing)
    }
}

private struct CustomerQueueView: View {
    @ObservedObject var rush: RushEngine

    var body: some View {
        GameCard {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Kuyruk", systemImage: "person.3.fill")

                HStack(spacing: 8) {
                    ForEach(Array(rush.queue.enumerated()), id: \.element.id) { index, customer in
                        QueueCustomerView(index: index, customer: customer)
                    }
                }
            }
        }
    }
}

private struct QueueCustomerView: View {
    let index: Int
    let customer: Customer

    var body: some View {
        VStack(spacing: 6) {
            CustomerAvatar(type: customer.type, size: 40)
            Text(index == 0 ? "Sıradaki" : "#\(index + 1)")
                .font(.caption2.weight(.black))
                .foregroundStyle(.white.opacity(0.38))
            Text(customer.type.displayName)
                .font(.caption2.weight(.black))
                .foregroundStyle(.white.opacity(0.72))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.13), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct CustomerCardView: View {
    let customer: Customer
    let patience: Double
    let maxPatience: Double
    let onDialogue: (DialogueResponse) -> Void

    private var isPatienceCritical: Bool {
        patience <= min(2, maxPatience * 0.35)
    }

    var body: some View {
        GameCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 14) {
                    CustomerAvatar(type: customer.type, size: 66)

                    VStack(alignment: .leading, spacing: 7) {
                        HStack(spacing: 6) {
                            Text(customer.type.displayName)
                                .font(.headline.weight(.black))
                                .foregroundStyle(.white)

                            if isPatienceCritical {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption.weight(.black))
                                    .foregroundStyle(Color.simitDanger)
                            }
                        }

                        OrderBubble(order: customer.order)
                    }

                    Spacer(minLength: 0)
                }

                VStack(alignment: .leading, spacing: 5) {
                    ProgressView(value: patience, total: maxPatience)
                        .tint(isPatienceCritical ? Color.simitDanger : Color.simitTeal)
                        .scaleEffect(x: 1, y: isPatienceCritical ? 1.25 : 1, anchor: .center)

                    Text(isPatienceCritical ? "Sabrı azaldı" : "Müşteri bekliyor")
                        .font(.caption2.weight(.black))
                        .foregroundStyle(isPatienceCritical ? Color.simitDanger : .white.opacity(0.44))
                }

                if let dialogue = customer.dialogue {
                    DialoguePanel(dialogue: dialogue, onDialogue: onDialogue)
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(isPatienceCritical ? Color.simitDanger.opacity(0.55) : Color.clear, lineWidth: 1.5)
        )
    }
}

private struct OrderBubble: View {
    let order: [ProductID]

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        Group {
            if order.count <= 3 {
                HStack(spacing: isPad ? 10 : 7) {
                    ForEach(order) { item in
                        let product = Products.definition(for: item)
                        OrderProductChip(product: product, isPad: isPad, isSingle: order.count == 1, isCompact: order.count == 3)
                            .frame(maxWidth: .infinity)
                    }
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: isPad ? 10 : 8) {
                        ForEach(order) { item in
                            let product = Products.definition(for: item)
                            OrderProductChip(product: product, isPad: isPad, isSingle: false)
                                .frame(width: isPad ? 160 : 116)
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(isPad ? 13 : 8)
        .background(
            LinearGradient(
                colors: [
                    Color.black.opacity(0.34),
                    Color.simitCream.opacity(0.08),
                    Color.simitAmber.opacity(0.06)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: isPad ? 22 : 18, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: isPad ? 22 : 18, style: .continuous)
                .stroke(Color.simitCream.opacity(0.16), lineWidth: 1)
        )
    }
}

private struct OrderProductChip: View {
    let product: ProductDefinition
    let isPad: Bool
    let isSingle: Bool
    var isCompact: Bool = false

    var body: some View {
        HStack(spacing: isPad ? 9 : (isCompact ? 4 : 7)) {
            ProductMark(product: product, size: markSize)
                .layoutPriority(1)
            Text(product.name)
                .font(labelFont.weight(.black))
                .lineLimit(1)
                .minimumScaleFactor(isCompact ? 0.50 : 0.68)
                .allowsTightening(true)
                .foregroundStyle(Color.simitCream)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, isPad ? 13 : (isCompact ? 6 : 9))
        .padding(.vertical, isPad ? 12 : 10)
        .frame(minHeight: chipHeight)
        .background(
            LinearGradient(
                colors: [Color.simitCream.opacity(isSingle ? 0.28 : 0.20), productTint.opacity(0.14), Color.black.opacity(0.20)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: isSingle ? 999 : (isPad ? 18 : 15), style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: isSingle ? 999 : (isPad ? 18 : 15), style: .continuous)
                .stroke(Color.simitCream.opacity(0.20), lineWidth: 1)
        )
    }

    private var markSize: CGFloat {
        if isSingle { return isPad ? 68 : 54 }
        if isCompact { return isPad ? 46 : 36 }
        return isPad ? 54 : 42
    }

    private var chipHeight: CGFloat {
        if isSingle { return isPad ? 84 : 68 }
        if isCompact { return isPad ? 78 : 60 }
        return isPad ? 76 : 62
    }

    private var labelFont: Font {
        if isSingle { return isPad ? .title2 : .title3 }
        if isCompact { return isPad ? .headline : .caption }
        return isPad ? .headline : .subheadline
    }

    private var productTint: Color {
        switch product.id {
        case .tea, .water, .ayran, .juiceBox: .simitTeal
        case .bag: .simitCream
        case .cheese, .olivePaste, .chocolate: .simitAmber
        case .simit, .acma, .oliveAcma, .cheesePogaca: Color(red: 0.92, green: 0.45, blue: 0.18)
        }
    }
}

private struct DialoguePanel: View {
    let dialogue: DialoguePrompt
    let onDialogue: (DialogueResponse) -> Void
    @State private var selectedResponseID: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 7) {
                Image(systemName: "quote.bubble.fill")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(Color.simitAmber)

                Text(dialogue.line)
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(.black.opacity(0.84))
                    .lineLimit(1)
                    .minimumScaleFactor(0.70)
            }

            HStack(spacing: 7) {
                ForEach(Array(dialogue.responses.enumerated()), id: \.element.id) { index, response in
                    Button {
                        selectedResponseID = response.id
                        onDialogue(response)
                    } label: {
                        let isSelected = selectedResponseID == response.id
                        let isDimmed = selectedResponseID != nil && !isSelected

                        Text(response.text)
                            .font(.system(size: 9, weight: .black))
                            .lineLimit(2)
                            .minimumScaleFactor(0.68)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, minHeight: 32)
                            .padding(.horizontal, 7)
                        .background(isSelected ? Color.simitSuccess.opacity(0.94) : choiceColor(index).opacity(isDimmed ? 0.30 : 1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(isSelected ? Color.white.opacity(0.58) : Color.black.opacity(0.06), lineWidth: isSelected ? 2 : 1)
                        )
                        .overlay(alignment: .topTrailing) {
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 13, weight: .black))
                                    .foregroundStyle(Color.black.opacity(0.62))
                                    .offset(x: 4, y: -5)
                            }
                        }
                        .foregroundStyle(.black.opacity(0.84))
                        .scaleEffect(isSelected ? 1.04 : 1)
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedResponseID != nil)
                }
            }

            if let selectedResponseID, let response = dialogue.responses.first(where: { $0.id == selectedResponseID }) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 9, weight: .black))
                    Text(dialogueResultText(for: response.effect))
                        .font(.system(size: 9, weight: .black))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
                .foregroundStyle(Color.simitSuccess)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.08), in: Capsule())
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 7)
        .padding(.bottom, 9)
        .background {
            SpeechBubble()
                .fill(
                    LinearGradient(
                        colors: [Color.simitCream.opacity(0.98), Color.white.opacity(0.90)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.24), radius: 12, y: 7)
        }
        .overlay {
            SpeechBubble()
                .stroke(Color.simitAmber.opacity(0.36), lineWidth: 1)
        }
        .onChange(of: dialogue.id) { _, _ in
            selectedResponseID = nil
        }
    }

    private func dialogueResultText(for effect: DialogueEffect) -> String {
        switch effect {
        case .trust: "Güven kazandın"
        case .neutral: "Cevap verildi"
        case .combo: "Ritim tuttu"
        case .upsell: "Müşteri memnun"
        case .risky: "Sabır azaldı"
        }
    }

    private func choiceColor(_ index: Int) -> Color {
        switch index {
        case 0: Color.simitCream
        case 1: Color(red: 0.75, green: 0.93, blue: 0.58)
        default: Color(red: 0.62, green: 0.88, blue: 0.96)
        }
    }
}

private struct SpeechBubble: Shape {
    func path(in rect: CGRect) -> Path {
        let tailHeight: CGFloat = 9
        let bubbleRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height - tailHeight)
        let rounded = Path(
            roundedRect: bubbleRect,
            cornerSize: CGSize(width: 15, height: 15)
        )

        var path = rounded
        path.move(to: CGPoint(x: rect.midX - 9, y: bubbleRect.maxY - 1))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX + 9, y: bubbleRect.maxY - 1))
        path.closeSubpath()
        return path
    }
}

private struct SelectedTrayView: View {
    let items: [ProductID]
    let expectedOrder: [ProductID]

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        HStack(spacing: isPad ? 12 : 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Tepsi")
                    .font((isPad ? Font.subheadline : Font.caption).weight(.black))
                    .foregroundStyle(.white.opacity(0.55))
                Text(items.isEmpty ? "Boş" : "\(items.count) ürün")
                    .font((isPad ? Font.caption : Font.caption2).weight(.bold))
                    .foregroundStyle(.white.opacity(0.36))
            }
            .frame(width: isPad ? 78 : 50, alignment: .leading)

            if items.isEmpty {
                Text("Siparişteki ürünleri aşağıdan seç")
                    .font((isPad ? Font.subheadline : Font.caption2).weight(.bold))
                    .foregroundStyle(.white.opacity(0.38))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, isPad ? 14 : 10)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: isPad ? 10 : 7) {
                        ForEach(items) { item in
                            let product = Products.definition(for: item)
                            Label(product.name, systemImage: product.symbol)
                                .font((isPad ? Font.subheadline : Font.caption).weight(.black))
                                .padding(.horizontal, isPad ? 12 : 9)
                                .padding(.vertical, isPad ? 9 : 7)
                                .background(trayColor(for: item).opacity(0.18), in: Capsule())
                                .foregroundStyle(trayColor(for: item))
                        }
                    }
                }
            }
        }
        .padding(isPad ? 14 : 8)
        .background(Color.black.opacity(0.18), in: RoundedRectangle(cornerRadius: isPad ? 18 : 14, style: .continuous))
    }

    private func trayColor(for item: ProductID) -> Color {
        expectedOrder.contains(item) ? Color.simitCream : Color.simitDanger
    }
}

private struct ServiceStatusStrip: View {
    @ObservedObject var rush: RushEngine

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    private var requiredCount: Int {
        max(1, rush.activeCustomer.order.count)
    }

    private var readyCount: Int {
        rush.selectedItems.filter { rush.activeCustomer.order.contains($0) }.count
    }

    private var progress: Double {
        min(1, Double(readyCount) / Double(requiredCount))
    }

    var body: some View {
        VStack(spacing: isPad ? 8 : 6) {
            HStack(spacing: isPad ? 12 : 9) {
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.18))
                    Circle()
                        .stroke(statusColor.opacity(0.48), lineWidth: 1)
                    Image(systemName: readyCount == requiredCount ? "checkmark.seal.fill" : "tray.full.fill")
                        .font(.system(size: isPad ? 16 : 13, weight: .black))
                        .foregroundStyle(statusColor)
                }
                .frame(width: isPad ? 40 : 32, height: isPad ? 40 : 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(readyCount == requiredCount ? "Sipariş hazır" : "Siparişi hazırla")
                        .font(.system(size: isPad ? 17 : 14, weight: .black))
                        .foregroundStyle(Color.simitCream)
                    Text("\(readyCount)/\(requiredCount) ürün tamam")
                        .font(.system(size: isPad ? 12 : 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.46))
                        .contentTransition(.numericText())
                }

                Spacer(minLength: 0)
                MissingOrderChips(rush: rush)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.10))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [statusColor, Color.simitTeal],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: proxy.size.width * progress)
                }
            }
            .frame(height: isPad ? 7 : 5)
        }
        .padding(.horizontal, isPad ? 13 : 10)
        .padding(.vertical, isPad ? 11 : 8)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.34), Color.simitTeal.opacity(0.10), Color.white.opacity(0.055)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: isPad ? 18 : 15, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: isPad ? 18 : 15, style: .continuous)
                .stroke(statusColor.opacity(readyCount == 0 ? 0.16 : 0.32), lineWidth: 1)
        )
    }

    private var statusColor: Color {
        readyCount == requiredCount ? Color.simitSuccess : Color.simitAmber
    }
}

private struct ProductShelfView: View {
    @ObservedObject var rush: RushEngine

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    private var sortedProducts: [ProductID] {
        let requested = rush.activeCustomer.order.filter { rush.availableProducts.contains($0) }
        let rest = rush.availableProducts.filter { !requested.contains($0) }
        return requested + rest
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isPad ? 10 : 8) {
            HStack(spacing: 8) {
                Text(rush.activeOrderCanBeFulfilled ? "Ürünler" : missingText)
                    .font(.system(size: isPad ? 16 : 12, weight: .black))
                    .foregroundStyle(rush.activeOrderCanBeFulfilled ? Color.simitCream : Color.simitDanger.opacity(0.98))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Spacer(minLength: 0)

                if sortedProducts.count > 3 {
                    Label("Kaydır", systemImage: "chevron.left.chevron.right")
                        .font(.system(size: isPad ? 12 : 10, weight: .black))
                        .foregroundStyle(Color.simitCream.opacity(0.48))
                        .labelStyle(.titleAndIcon)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: isPad ? 11 : 8) {
                    ForEach(sortedProducts, id: \.self) { productID in
                        let product = Products.definition(for: productID)
                        ProductShelfCard(
                            product: product,
                            stock: rush.stock.quantity(for: productID),
                            isSelected: rush.selectedItems.contains(productID),
                            isRequested: rush.activeCustomer.order.contains(productID),
                            isPad: isPad
                        ) {
                            rush.select(productID)
                        }
                    }
                }
                .padding(.horizontal, isPad ? 7 : 5)
                .padding(.vertical, 3)
            }
        }
        .padding(isPad ? 14 : 8)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.42), Color.simitTeal.opacity(0.10), Color.simitAmber.opacity(0.07)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: isPad ? 20 : 17, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: isPad ? 20 : 17, style: .continuous)
                .stroke(Color.simitCream.opacity(0.12), lineWidth: 1)
        )
    }

    private var missingText: String {
        let names = rush.missingOrderItems.map { Products.definition(for: $0).name }
        guard !names.isEmpty else { return "Stok eksik" }
        return "Eksik: \(names.joined(separator: ", "))"
    }
}

private struct ProductShelfCard: View {
    let product: ProductDefinition
    let stock: Int
    let isSelected: Bool
    let isRequested: Bool
    let isPad: Bool
    let action: () -> Void
    @State private var glow = false

    private var isAvailable: Bool { stock > 0 && !isSelected && isRequested }

    var body: some View {
        Button(action: action) {
            VStack(spacing: isPad ? 8 : 6) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [productTint.opacity(isRequested ? 0.48 : 0.13), Color.black.opacity(isRequested ? 0.16 : 0.28)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: isPad ? 86 : 64, height: isPad ? 86 : 64)
                        .overlay(
                            Circle()
                                .stroke(Color.simitCream.opacity(isRequested ? 0.24 : 0.08), lineWidth: 1)
                        )

                    ProductMark(product: product, size: isPad ? 68 : 50)
                        .opacity(stock == 0 ? 0.34 : (isRequested ? 1 : 0.58))
                        .shadow(color: productTint.opacity(isRequested ? 0.30 : 0.12), radius: isRequested ? 10 : 5, y: 4)

                    if isRequested {
                        Image(systemName: isSelected ? "checkmark" : "star.fill")
                            .font(.system(size: isPad ? 10 : 8, weight: .black))
                            .foregroundStyle(.black.opacity(0.78))
                            .frame(width: isPad ? 22 : 18, height: isPad ? 22 : 18)
                            .background(isSelected ? Color.simitSuccess : Color.simitAmber, in: Circle())
                            .offset(x: isPad ? 30 : 24, y: isPad ? -27 : -22)
                    }
                }

                Text(product.name)
                    .font(.system(size: isPad ? 15 : 10, weight: .black))
                    .foregroundStyle(stock == 0 ? Color.simitCream.opacity(0.46) : Color.simitCream.opacity(isRequested ? 1 : 0.58))
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)
                    .frame(width: isPad ? 100 : 70)

                HStack(spacing: 4) {
                    Image(systemName: stock == 0 ? "xmark.circle.fill" : (isSelected ? "checkmark.circle.fill" : "shippingbox.fill"))
                    Text(stock == 0 ? "Yok" : (isSelected ? "Hazır" : "x\(stock)"))
                }
                .font(.system(size: isPad ? 11 : 9, weight: .black))
                .foregroundStyle(stock == 0 ? Color.simitDanger : (isSelected ? Color.simitSuccess : .white.opacity(isRequested ? 0.60 : 0.34)))
            }
            .padding(.horizontal, isPad ? 12 : 8)
            .padding(.vertical, isPad ? 12 : 8)
            .frame(width: isPad ? 132 : 96, height: isPad ? 154 : 116)
            .background(cardBackground, in: RoundedRectangle(cornerRadius: isPad ? 23 : 19, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: isPad ? 23 : 19, style: .continuous)
                    .stroke(borderTint, lineWidth: isSelected || isRequested ? 1.6 : 1)
            )
            .shadow(color: (isRequested ? productTint : Color.black).opacity(isRequested ? (glow ? 0.32 : 0.18) : 0.12), radius: isRequested ? (glow ? 16 : 9) : 7, y: isRequested ? 7 : 4)
            .scaleEffect(isSelected ? 0.96 : (isRequested ? (glow ? 1.025 : 1.01) : 1))
        }
        .buttonStyle(.plain)
        .disabled(!isAvailable)
        .opacity(stock == 0 ? 0.58 : (isRequested ? 1 : 0.42))
        .onAppear {
            guard isRequested else { return }
            withAnimation(.easeInOut(duration: 0.82).repeatForever(autoreverses: true)) {
                glow = true
            }
        }
        .animation(.snappy(duration: 0.18), value: isSelected)
        .animation(.snappy(duration: 0.18), value: stock)
    }

    private var cardBackground: LinearGradient {
        LinearGradient(
            colors: [
                productTint.opacity(isAvailable ? 0.30 : 0.10),
                Color.simitCream.opacity(isRequested && isAvailable ? 0.10 : 0.03),
                Color.black.opacity(0.28)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var borderTint: Color {
        if stock == 0 { return Color.simitDanger.opacity(0.28) }
        if isSelected { return Color.simitSuccess.opacity(0.74) }
        if isRequested { return Color.simitAmber.opacity(0.62) }
        return Color.white.opacity(0.08)
    }

    private var productTint: Color {
        switch product.id {
        case .tea, .water, .ayran, .juiceBox: .simitTeal
        case .bag: .simitCream
        case .cheese, .olivePaste, .chocolate: .simitAmber
        case .simit, .acma, .oliveAcma, .cheesePogaca: Color(red: 0.92, green: 0.45, blue: 0.18)
        }
    }
}

private struct ServiceActionBar: View {
    @ObservedObject var rush: RushEngine
    @State private var servePulse = false

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    private var canServe: Bool {
        rush.activeOrderCanBeFulfilled && !rush.selectedItems.isEmpty
    }

    var body: some View {
        HStack(spacing: isPad ? 12 : 9) {
            if !rush.activeOrderCanBeFulfilled {
                Button {
                    rush.declineUnavailableOrder()
                } label: {
                    Label("Stok Yok De", systemImage: "hand.raised.fill")
                        .font((isPad ? Font.headline : Font.subheadline).weight(.black))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, isPad ? 17 : 13)
                        .background(Color.simitDanger.opacity(0.86), in: RoundedRectangle(cornerRadius: isPad ? 18 : 15, style: .continuous))
                        .foregroundStyle(Color.simitCream)
                }
                .buttonStyle(.plain)
            }

            Button {
                rush.clearTray()
            } label: {
                Image(systemName: "xmark")
                    .font((isPad ? Font.title3 : Font.headline).weight(.black))
                    .frame(width: isPad ? 64 : 50)
                    .padding(.vertical, isPad ? 16 : 12)
                    .background(Color.black.opacity(0.22), in: RoundedRectangle(cornerRadius: isPad ? 18 : 15, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: isPad ? 18 : 15, style: .continuous)
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white.opacity(0.74))

            Button {
                rush.serve()
            } label: {
                Label(canServe ? "Servis Et" : "Ürünleri Seç", systemImage: canServe ? "checkmark" : "hand.tap.fill")
                    .font((isPad ? Font.title2 : Font.headline).weight(.black))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, isPad ? 18 : 13)
                    .background(
                        LinearGradient(
                            colors: canServe ? [Color.simitSuccess, Color.simitTeal] : [Color.black.opacity(0.22), Color.white.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: isPad ? 20 : 16, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: isPad ? 20 : 16, style: .continuous)
                            .stroke(canServe ? Color.white.opacity(0.22) : Color.simitCream.opacity(0.06), lineWidth: 1)
                    )
                    .shadow(color: canServe ? Color.simitTeal.opacity(servePulse ? 0.36 : 0.20) : .clear, radius: servePulse ? 16 : 10, y: 6)
                    .foregroundStyle(canServe ? .white : Color.simitCream.opacity(0.30))
                    .scaleEffect(canServe && servePulse ? 1.015 : 1)
            }
            .buttonStyle(.plain)
            .disabled(!canServe)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.88).repeatForever(autoreverses: true)) {
                servePulse = true
            }
        }
    }
}

private struct ProductActionTray: View {
    @ObservedObject var rush: RushEngine

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    private var canServe: Bool {
        rush.activeOrderCanBeFulfilled && !rush.selectedItems.isEmpty
    }

    var body: some View {
        VStack(spacing: isPad ? 16 : 9) {
            SwipeProductSelectionView(rush: rush)

            if !rush.activeOrderCanBeFulfilled {
                Button {
                    rush.declineUnavailableOrder()
                } label: {
                    Label("Stok Yok De", systemImage: "hand.raised.fill")
                        .font((isPad ? Font.headline : Font.subheadline).weight(.black))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, isPad ? 15 : 12)
                        .background(
                            LinearGradient(
                                colors: [Color.simitDanger.opacity(0.36), Color.simitStand.opacity(0.42)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: RoundedRectangle(cornerRadius: 13, style: .continuous)
                        )
                        .foregroundStyle(Color.simitCream)
                        .overlay(
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .stroke(Color.simitDanger.opacity(0.42), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: isPad ? 16 : 10) {
                Button {
                    rush.clearTray()
                } label: {
                    Image(systemName: "xmark")
                        .font((isPad ? Font.title3 : Font.headline).weight(.black))
                        .frame(width: isPad ? 70 : 50, height: isPad ? 62 : 48)
                        .background(Color.black.opacity(0.18), in: RoundedRectangle(cornerRadius: isPad ? 18 : 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white.opacity(0.76))

                Button {
                    rush.serve()
                } label: {
                    Label(canServe ? "Servis Et" : (rush.activeOrderCanBeFulfilled ? "Ürünleri Seç" : "Stok Eksik"), systemImage: canServe ? "checkmark" : "lock.fill")
                        .font((isPad ? Font.title2 : Font.headline).weight(.black))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, isPad ? 20 : 14)
                        .background(canServe ? Color.simitSuccess.opacity(0.88) : Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: isPad ? 18 : 14, style: .continuous))
                        .foregroundStyle(canServe ? .white : .white.opacity(0.35))
                }
                .buttonStyle(.plain)
                .disabled(!canServe)
            }
        }
    }
}

private struct SwipeProductSelectionView: View {
    @ObservedObject var rush: RushEngine
    @State private var selectedProduct: ProductID?

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    private var products: [ProductID] {
        rush.availableProducts
    }

    private var currentProductID: ProductID? {
        selectedProduct ?? products.first
    }

    private var currentProduct: ProductDefinition? {
        currentProductID.map { Products.definition(for: $0) }
    }

    private var canAddCurrentProduct: Bool {
        guard let currentProductID else { return false }
        return rush.stock.quantity(for: currentProductID) > 0 && !rush.selectedItems.contains(currentProductID)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isPad ? 14 : 9) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("ÜRÜN SEÇ")
                        .font(.system(size: isPad ? 13 : 10, weight: .black))
                        .foregroundStyle(Color.simitCream.opacity(0.72))
                    Text(helperText)
                        .font(.system(size: isPad ? 12 : 10, weight: .black))
                        .foregroundStyle(helperTint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }

                Spacer(minLength: 8)

                MissingOrderChips(rush: rush)
            }

            TabView(selection: selectedProductBinding) {
                ForEach(products, id: \.self) { productID in
                    let product = Products.definition(for: productID)
                    SwipeProductCard(
                        product: product,
                        stock: rush.stock.quantity(for: productID),
                        isSelected: rush.selectedItems.contains(productID),
                        isRequested: rush.activeCustomer.order.contains(productID),
                        isPad: isPad
                    )
                    .tag(productID)
                    .padding(.horizontal, isPad ? 8 : 5)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: isPad ? 156 : 108)
            .animation(.snappy(duration: 0.22), value: selectedProduct)

            HStack(spacing: isPad ? 12 : 9) {
                ProductPageDots(products: products, selectedProduct: currentProductID)

                Spacer(minLength: 8)

                AddToTrayButton(
                    title: addButtonTitle,
                    productID: currentProductID,
                    enabled: canAddCurrentProduct,
                    isPad: isPad,
                    rush: rush
                )
            }
        }
        .padding(isPad ? 16 : 11)
        .background(Color.black.opacity(0.18), in: RoundedRectangle(cornerRadius: isPad ? 20 : 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: isPad ? 20 : 16, style: .continuous)
                .stroke(Color.simitCream.opacity(0.10), lineWidth: 1)
        )
        .onAppear { syncSelection() }
        .onChange(of: rush.activeCustomer.id) { _, _ in
            syncSelection(preferOrder: true)
        }
        .onChange(of: rush.availableProducts) { _, _ in
            syncSelection()
        }
    }

    private var selectedProductBinding: Binding<ProductID> {
        Binding(
            get: { currentProductID ?? .simit },
            set: { selectedProduct = $0 }
        )
    }

    private var helperText: String {
        if !rush.activeOrderCanBeFulfilled { return missingText }
        return "Kaydır, doğru ürünü tepsiye ekle"
    }

    private var helperTint: Color {
        rush.activeOrderCanBeFulfilled ? .white.opacity(0.42) : Color.simitDanger.opacity(0.88)
    }

    private var missingText: String {
        let names = rush.missingOrderItems.map { Products.definition(for: $0).name }
        guard !names.isEmpty else { return "Stok eksik" }
        return "Eksik: \(names.joined(separator: ", "))"
    }

    private var addButtonTitle: String {
        guard let currentProductID else { return "Ürün Yok" }
        if rush.selectedItems.contains(currentProductID) { return "Tepside" }
        if rush.stock.quantity(for: currentProductID) <= 0 { return "Stok Yok" }
        return "Tepsiye Ekle"
    }

    private func syncSelection(preferOrder: Bool = false) {
        guard !products.isEmpty else {
            selectedProduct = nil
            return
        }

        if preferOrder,
           let requested = rush.activeCustomer.order.first(where: { products.contains($0) }) {
            selectedProduct = requested
            return
        }

        if let selectedProduct, products.contains(selectedProduct) {
            return
        }

        selectedProduct = rush.activeCustomer.order.first(where: { products.contains($0) }) ?? products.first
    }
}

private struct AddToTrayButton: View {
    let title: String
    let productID: ProductID?
    let enabled: Bool
    let isPad: Bool
    @ObservedObject var rush: RushEngine

    var body: some View {
        Button {
            guard let productID else { return }
            rush.select(productID)
        } label: {
            AddToTrayButtonLabel(title: title, enabled: enabled, isPad: isPad)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

private struct AddToTrayButtonLabel: View {
    let title: String
    let enabled: Bool
    let isPad: Bool

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: enabled ? "plus" : "lock.fill")
            Text(title)
        }
        .font((isPad ? Font.headline : Font.caption).weight(.black))
        .lineLimit(1)
        .minimumScaleFactor(0.72)
        .padding(.horizontal, isPad ? 18 : 12)
        .padding(.vertical, isPad ? 12 : 8)
        .background(enabled ? Color.simitAmber : Color.white.opacity(0.10), in: Capsule())
        .foregroundStyle(enabled ? .black.opacity(0.84) : .white.opacity(0.36))
    }
}

private struct SwipeProductCard: View {
    let product: ProductDefinition
    let stock: Int
    let isSelected: Bool
    let isRequested: Bool
    let isPad: Bool

    var body: some View {
        HStack(spacing: isPad ? 18 : 12) {
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [productTint.opacity(0.34), Color.black.opacity(0.16)],
                            center: .topLeading,
                            startRadius: 8,
                            endRadius: isPad ? 76 : 58
                        )
                    )
                    .frame(width: isPad ? 112 : 68, height: isPad ? 112 : 68)

                ProductMark(product: product, size: isPad ? 82 : 52)
                    .opacity(stock == 0 ? 0.35 : 1)
                    .scaleEffect(isSelected ? 0.92 : 1)

                if stock == 0 {
                    Text("YOK")
                        .font(.system(size: isPad ? 11 : 9, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(Color.simitDanger, in: Capsule())
                        .offset(x: 8, y: -2)
                }
            }

            VStack(alignment: .leading, spacing: isPad ? 9 : 5) {
                HStack(spacing: 7) {
                    Text(product.name)
                        .font((isPad ? Font.title2 : Font.subheadline).weight(.black))
                        .foregroundStyle(Color.simitCream)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    if isRequested {
                        Text("İSTENİYOR")
                            .font(.system(size: isPad ? 10 : 7, weight: .black))
                            .foregroundStyle(.black.opacity(0.78))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(Color.simitAmber, in: Capsule())
                    }
                }

                Text(subtitle)
                    .font((isPad ? Font.subheadline : Font.caption2).weight(.bold))
                    .foregroundStyle(.white.opacity(0.52))
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)

                HStack(spacing: isPad ? 10 : 7) {
                    Label("x\(stock)", systemImage: "shippingbox.fill")
                    Label(isSelected ? "Tepside" : "Hazır", systemImage: isSelected ? "checkmark.circle.fill" : "hand.tap.fill")
                }
                .font((isPad ? Font.caption : Font.caption2).weight(.black))
                .foregroundStyle(isSelected ? Color.simitSuccess : Color.simitCream.opacity(0.64))
            }

            Spacer(minLength: 0)
        }
        .padding(isPad ? 16 : 11)
        .frame(maxWidth: .infinity, minHeight: isPad ? 132 : 96)
        .background(
            LinearGradient(
                colors: [productTint.opacity(stock == 0 ? 0.11 : 0.30), Color.simitStand.opacity(0.20)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: isPad ? 26 : 21, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: isPad ? 26 : 21, style: .continuous)
                .stroke(borderTint, lineWidth: isSelected ? 2 : 1)
        )
        .opacity(stock == 0 ? 0.72 : 1)
    }

    private var subtitle: String {
        if product.id.isAddOn { return "Simit arası ek malzeme" }
        switch product.id {
        case .simit, .acma, .oliveAcma, .cheesePogaca:
            return "Fırından sıcak servis"
        case .tea:
            return "Termostan ince belli çay"
        case .water, .ayran, .juiceBox:
            return "Soğuk içecek"
        case .bag:
            return "Paket servis için"
        case .cheese, .olivePaste, .chocolate:
            return "Simit arası ek malzeme"
        }
    }

    private var productTint: Color {
        switch product.id {
        case .tea, .water, .ayran, .juiceBox: .simitTeal
        case .bag: .simitCream
        case .cheese, .olivePaste, .chocolate: .simitAmber
        case .simit, .acma, .oliveAcma, .cheesePogaca: Color(red: 0.92, green: 0.45, blue: 0.18)
        }
    }

    private var borderTint: Color {
        if stock == 0 { return Color.simitDanger.opacity(0.30) }
        if isSelected { return Color.simitSuccess.opacity(0.80) }
        if isRequested { return Color.simitAmber.opacity(0.48) }
        return Color.simitCream.opacity(0.12)
    }
}

private struct MissingOrderChips: View {
    @ObservedObject var rush: RushEngine

    var body: some View {
        HStack(spacing: 5) {
            ForEach(rush.activeCustomer.order) { productID in
                let product = Products.definition(for: productID)
                let isDone = rush.selectedItems.contains(productID)
                let hasStock = rush.stock.quantity(for: productID) > 0
                Image(systemName: isDone ? "checkmark" : product.symbol)
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(isDone ? .black.opacity(0.78) : (hasStock ? Color.simitCream : Color.simitDanger))
                    .frame(width: 24, height: 24)
                    .background(isDone ? Color.simitSuccess : Color.black.opacity(0.24), in: Circle())
                    .overlay(Circle().stroke(hasStock ? Color.simitCream.opacity(0.14) : Color.simitDanger.opacity(0.40), lineWidth: 1))
            }
        }
    }
}

private struct ProductPageDots: View {
    let products: [ProductID]
    let selectedProduct: ProductID?

    var body: some View {
        HStack(spacing: 5) {
            ForEach(products, id: \.self) { product in
                Capsule()
                    .fill(product == selectedProduct ? Color.simitAmber : Color.white.opacity(0.18))
                    .frame(width: product == selectedProduct ? 18 : 6, height: 6)
            }
        }
        .animation(.snappy(duration: 0.18), value: selectedProduct)
    }
}

private enum RushProductCategory: String, CaseIterable, Identifiable {
    case bakery = "Fırın"
    case drinks = "İçecek"
    case addOns = "Ek"
    case packing = "Paket"

    var id: String { rawValue }

    func contains(_ product: ProductID) -> Bool {
        switch self {
        case .bakery:
            [.simit, .acma, .oliveAcma, .cheesePogaca].contains(product)
        case .drinks:
            [.tea, .water, .ayran, .juiceBox].contains(product)
        case .addOns:
            product.isAddOn
        case .packing:
            product == .bag
        }
    }
}

private struct RushProductCategoryTabs: View {
    @Binding var selection: RushProductCategory
    let availableProducts: [ProductID]

    private var visibleCategories: [RushProductCategory] {
        RushProductCategory.allCases.filter { category in
            availableProducts.contains { category.contains($0) }
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(visibleCategories) { category in
                Button {
                    selection = category
                } label: {
                    Text(category.rawValue.uppercased())
                        .font(.system(size: 10, weight: .black))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(selection == category ? Color.simitCream : Color.black.opacity(0.16), in: Capsule())
                        .foregroundStyle(selection == category ? .black.opacity(0.82) : Color.simitCream.opacity(0.68))
                }
                .buttonStyle(.plain)
            }
        }
        .onChange(of: availableProducts) { _, products in
            guard products.contains(where: { selection.contains($0) }) else {
                selection = visibleCategories.first ?? .bakery
                return
            }
        }
    }
}

private struct ProductGrid: View {
    @ObservedObject var rush: RushEngine
    let category: RushProductCategory

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    private var products: [ProductID] {
        rush.availableProducts.filter { category.contains($0) }
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(products, id: \.self) { productID in
                let product = Products.definition(for: productID)
                ProductButton(product: product, stock: rush.stock.quantity(for: product.id), isSelected: rush.selectedItems.contains(product.id)) {
                    rush.select(product.id)
                }
            }
        }
    }
}

private struct ProductButton: View {
    let product: ProductDefinition
    let stock: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                ProductMark(product: product, size: 36)
                    .opacity(stock == 0 ? 0.35 : 1)
                Text(product.name)
                    .font(.system(size: 10, weight: .black))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text("x\(stock)")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(stock == 0 ? Color.simitDanger : .white.opacity(0.52))
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 88)
            .padding(.vertical, 7)
            .background(buttonBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(alignment: .topTrailing) {
                if stock == 0 {
                    Text("YOK")
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(Color.simitDanger)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 3)
                        .background(Color.black.opacity(0.34), in: Capsule())
                        .padding(5)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? Color.simitAmber.opacity(0.88) : Color.clear, lineWidth: 1.5)
            )
            .clipped()
        }
        .buttonStyle(.plain)
        .disabled(stock == 0)
        .foregroundStyle(stock == 0 ? .white.opacity(0.26) : .white)
        .scaleEffect(isSelected ? 1.015 : 1)
        .animation(.snappy(duration: 0.18), value: isSelected)
    }

    private var buttonBackground: Color {
        if stock == 0 { return Color.black.opacity(0.14) }
        return isSelected ? Color.simitAmber.opacity(0.22) : Color.white.opacity(0.10)
    }
}

private struct FeedbackBanner: View {
    let message: String
    let kind: RushFeedbackKind

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        Label(message, systemImage: iconName)
            .font(.system(size: isPad ? 13 : 10, weight: .black))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .padding(.horizontal, isPad ? 16 : 12)
            .padding(.vertical, isPad ? 7 : 5)
            .frame(maxWidth: isPad ? 360 : 260)
            .frame(maxWidth: .infinity, alignment: .center)
            .background(color.opacity(kind == .neutral ? 0.08 : 0.11), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(color.opacity(kind == .neutral ? 0.07 : 0.24), lineWidth: 1)
            )
            .scaleEffect(kind == .neutral ? 1 : (isPad ? 1.01 : 1.02))
            .contentTransition(.numericText())
            .animation(.snappy(duration: 0.18), value: message)
            .animation(.snappy(duration: 0.18), value: kind)
    }

    private var color: Color {
        switch kind {
        case .neutral: Color.simitTeal
        case .success: Color.simitSuccess
        case .warning: Color.simitAmber
        case .danger: Color.simitDanger
        }
    }

    private var iconName: String {
        switch kind {
        case .neutral: "info.circle.fill"
        case .success: "checkmark.circle.fill"
        case .warning: "exclamationmark.circle.fill"
        case .danger: "xmark.circle.fill"
        }
    }
}

struct CustomerAvatar: View {
    let type: CustomerType
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [avatarColor(for: type).opacity(0.98), avatarColor(for: type).opacity(0.46)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(0.30), .clear],
                        center: .topLeading,
                        startRadius: 2,
                        endRadius: size * 0.72
                    )
                )
            Circle()
                .stroke(Color.white.opacity(0.20), lineWidth: 1.5)
            Circle()
                .stroke(avatarColor(for: type).opacity(0.36), lineWidth: size * 0.035)
                .padding(size * 0.045)

            VStack(spacing: -size * 0.04) {
                ZStack {
                    Circle()
                        .fill(skinColor)
                    customerHair
                    customerAccessory

                    HStack(spacing: size * 0.12) {
                        Circle()
                            .fill(Color.black.opacity(0.82))
                            .frame(width: size * 0.045, height: size * 0.045)
                        Circle()
                            .fill(Color.black.opacity(0.82))
                            .frame(width: size * 0.045, height: size * 0.045)
                    }
                    .offset(y: size * 0.03)

                    Capsule()
                        .fill(Color.black.opacity(0.34))
                        .frame(width: size * 0.16, height: size * 0.025)
                        .offset(y: size * 0.16)

                    HStack(spacing: size * 0.20) {
                        Circle()
                            .fill(Color.white.opacity(0.22))
                            .frame(width: size * 0.045, height: size * 0.025)
                        Circle()
                            .fill(Color.white.opacity(0.22))
                            .frame(width: size * 0.045, height: size * 0.025)
                    }
                    .offset(y: size * 0.095)
                }
                .frame(width: size * 0.45, height: size * 0.45)

                RoundedRectangle(cornerRadius: size * 0.08, style: .continuous)
                    .fill(clothingColor)
                    .frame(width: size * 0.50, height: size * 0.24)
                    .overlay(alignment: .top) {
                        Capsule()
                            .fill(Color.white.opacity(0.16))
                            .frame(width: size * 0.28, height: size * 0.035)
                            .offset(y: size * 0.035)
                    }
                    .overlay(alignment: .bottom) {
                        clothingDetail
                    }
            }
            .offset(y: size * 0.07)

            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.52))
                Circle()
                    .stroke(Color.white.opacity(0.20), lineWidth: 1)
                Image(systemName: type.smallSymbol)
                    .font(.system(size: size * 0.115, weight: .black))
                    .foregroundStyle(Color.simitCream)
            }
            .frame(width: size * 0.27, height: size * 0.27)
            .offset(x: size * 0.28, y: size * 0.26)
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.18), radius: 7, x: 0, y: 4)
    }

    private var skinColor: Color {
        switch type {
        case .tourist, .student: Color(red: 0.94, green: 0.66, blue: 0.40)
        case .elder: Color(red: 0.86, green: 0.58, blue: 0.38)
        case .officeWorker, .taxiDriver, .rushed: Color(red: 0.78, green: 0.45, blue: 0.27)
        }
    }

    private var clothingColor: Color {
        switch type {
        case .student: .simitTeal
        case .officeWorker: .simitStand
        case .tourist: .purple
        case .taxiDriver: .orange
        case .elder: .mint
        case .rushed: .simitDanger
        }
    }

    @ViewBuilder
    private var clothingDetail: some View {
        switch type {
        case .student:
            HStack(spacing: size * 0.025) {
                RoundedRectangle(cornerRadius: size * 0.012)
                    .fill(Color.white.opacity(0.70))
                    .frame(width: size * 0.07, height: size * 0.09)
                RoundedRectangle(cornerRadius: size * 0.012)
                    .fill(Color.white.opacity(0.70))
                    .frame(width: size * 0.07, height: size * 0.09)
            }
            .offset(y: -size * 0.04)
        case .taxiDriver:
            Capsule()
                .fill(Color.simitAmber.opacity(0.92))
                .frame(width: size * 0.25, height: size * 0.045)
                .offset(y: -size * 0.055)
        case .tourist:
            Capsule()
                .fill(Color.simitCream.opacity(0.72))
                .frame(width: size * 0.22, height: size * 0.04)
                .offset(y: -size * 0.055)
        case .elder:
            Capsule()
                .fill(Color.white.opacity(0.52))
                .frame(width: size * 0.20, height: size * 0.04)
                .offset(y: -size * 0.055)
        case .officeWorker:
            VStack(spacing: size * 0.01) {
                Capsule()
                    .fill(Color.white.opacity(0.58))
                    .frame(width: size * 0.24, height: size * 0.032)
                Capsule()
                    .fill(Color.simitAmber.opacity(0.70))
                    .frame(width: size * 0.08, height: size * 0.05)
            }
            .offset(y: -size * 0.055)
        case .rushed:
            Capsule()
                .fill(Color.white.opacity(0.62))
                .frame(width: size * 0.26, height: size * 0.035)
                .rotationEffect(.degrees(-8))
                .offset(y: -size * 0.055)
        }
    }

    @ViewBuilder
    private var customerHair: some View {
        switch type {
        case .elder:
            Capsule()
                .fill(Color.white.opacity(0.84))
                .frame(width: size * 0.34, height: size * 0.16)
                .offset(y: -size * 0.16)
        case .tourist:
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: size * 0.04, style: .continuous)
                    .fill(Color.simitCream)
                    .frame(width: size * 0.44, height: size * 0.12)
                Capsule()
                    .fill(Color.simitAmber.opacity(0.86))
                    .frame(width: size * 0.30, height: size * 0.045)
            }
            .offset(y: -size * 0.20)
        case .student:
            Capsule()
                .fill(Color(red: 0.20, green: 0.11, blue: 0.08))
                .frame(width: size * 0.32, height: size * 0.18)
                .rotationEffect(.degrees(-12))
                .offset(y: -size * 0.18)
        case .officeWorker:
            RoundedRectangle(cornerRadius: size * 0.05, style: .continuous)
                .fill(Color(red: 0.13, green: 0.08, blue: 0.05))
                .frame(width: size * 0.34, height: size * 0.15)
                .offset(y: -size * 0.18)
        case .taxiDriver:
            Capsule()
                .fill(Color(red: 0.08, green: 0.06, blue: 0.04))
                .frame(width: size * 0.38, height: size * 0.15)
                .offset(y: -size * 0.18)
        case .rushed:
            Capsule()
                .fill(Color(red: 0.12, green: 0.07, blue: 0.05))
                .frame(width: size * 0.38, height: size * 0.15)
                .rotationEffect(.degrees(-8))
                .offset(y: -size * 0.19)
        }
    }

    @ViewBuilder
    private var customerAccessory: some View {
        switch type {
        case .student:
            RoundedRectangle(cornerRadius: size * 0.025, style: .continuous)
                .fill(Color.white.opacity(0.82))
                .frame(width: size * 0.20, height: size * 0.11)
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.02, style: .continuous)
                        .stroke(Color.simitTeal.opacity(0.55), lineWidth: 1)
                )
                .offset(y: size * 0.20)
        case .officeWorker:
            Capsule()
                .fill(Color.black.opacity(0.74))
                .frame(width: size * 0.25, height: size * 0.035)
                .offset(y: size * 0.11)
        case .taxiDriver:
            VStack(spacing: size * 0.015) {
                Capsule()
                    .fill(Color.black.opacity(0.84))
                    .frame(width: size * 0.30, height: size * 0.035)
                Capsule()
                    .fill(Color.simitAmber.opacity(0.90))
                    .frame(width: size * 0.24, height: size * 0.035)
            }
            .offset(y: size * 0.10)
        case .tourist:
            Image(systemName: "camera.fill")
                .font(.system(size: size * 0.12, weight: .black))
                .foregroundStyle(Color.black.opacity(0.42))
                .offset(x: size * 0.20, y: size * 0.18)
        case .elder:
            Image(systemName: "mustache.fill")
                .font(.system(size: size * 0.15, weight: .black))
                .foregroundStyle(Color.black.opacity(0.36))
                .offset(y: size * 0.11)
        case .rushed:
            Image(systemName: "bolt.fill")
                .font(.system(size: size * 0.13, weight: .black))
                .foregroundStyle(Color.simitAmber)
                .offset(x: size * 0.18, y: -size * 0.16)
        }
    }
}

private extension CustomerType {
    var smallSymbol: String {
        switch self {
        case .student: "book.fill"
        case .officeWorker: "briefcase.fill"
        case .tourist: "camera.fill"
        case .taxiDriver: "car.fill"
        case .elder: "house.fill"
        case .rushed: "bolt.fill"
        }
    }
}

private func avatarColor(for type: CustomerType) -> Color {
    switch type {
    case .student: .simitTeal
    case .officeWorker: .simitAmber
    case .tourist: .purple
    case .taxiDriver: .orange
    case .elder: .mint
    case .rushed: .simitDanger
    }
}
