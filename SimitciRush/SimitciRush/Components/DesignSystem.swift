import SwiftUI
import UIKit

extension Color {
    static let simitBackground = Color(red: 0.13, green: 0.09, blue: 0.06)
    static let simitBackgroundDeep = Color(red: 0.05, green: 0.04, blue: 0.04)
    static let simitSky = Color(red: 0.23, green: 0.31, blue: 0.36)
    static let simitStand = Color(red: 0.49, green: 0.20, blue: 0.11)
    static let simitCounter = Color(red: 0.73, green: 0.38, blue: 0.17)
    static let simitCard = Color.white.opacity(0.09)
    static let simitCardStrong = Color.white.opacity(0.15)
    static let simitAmber = Color(red: 0.96, green: 0.64, blue: 0.22)
    static let simitCream = Color(red: 0.98, green: 0.89, blue: 0.70)
    static let simitTeal = Color(red: 0.27, green: 0.78, blue: 0.75)
    static let simitDanger = Color(red: 0.95, green: 0.32, blue: 0.28)
    static let simitSuccess = Color(red: 0.32, green: 0.78, blue: 0.45)
}

struct GameBackground: View {
    var theme: GameTheme = .morning

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                GameBackgroundArtwork()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                    .overlay(Color.black.opacity(0.14))
                    .overlay(
                        LinearGradient(
                            colors: [
                                .clear,
                                Color.simitBackground.opacity(0.38),
                                Color.simitBackgroundDeep.opacity(0.62)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                LinearGradient(
                    colors: themeOverlayColors,
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }

    private var themeOverlayColors: [Color] {
        switch theme {
        case .morning:
            [Color.simitSky.opacity(0.08), Color.simitBackground.opacity(0.26), Color.simitBackgroundDeep.opacity(0.54)]
        case .evening:
            [Color(red: 0.92, green: 0.45, blue: 0.18).opacity(0.16), Color.simitStand.opacity(0.30), Color.simitBackgroundDeep.opacity(0.58)]
        case .rainy:
            [Color.simitTeal.opacity(0.12), Color(red: 0.08, green: 0.11, blue: 0.13).opacity(0.38), Color.simitBackgroundDeep.opacity(0.68)]
        }
    }
}

struct GameBackgroundArtwork: View {
    var body: some View {
        if let image = GameArtwork.background {
            Image(uiImage: image)
                .resizable()
        } else {
            LinearGradient(
                colors: [
                    Color.simitSky,
                    Color.simitBackground,
                    Color.simitBackgroundDeep
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

private enum GameArtwork {
    static let background: UIImage? = {
        if let image = UIImage(named: "istanbul-waterfront-background") {
            return image
        }

        guard let path = Bundle.main.path(forResource: "istanbul-waterfront-background", ofType: "png") else {
            return nil
        }

        return UIImage(contentsOfFile: path)
    }()
}

struct GameCard<Content: View>: View {
    let content: Content

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(isPad ? 22 : 16)
            .background(
                RoundedRectangle(cornerRadius: isPad ? 26 : 20, style: .continuous)
                    .fill(Color.simitCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: isPad ? 26 : 20, style: .continuous)
                            .stroke(Color.white.opacity(isPad ? 0.14 : 0.10), lineWidth: 1)
                    )
            )
    }
}

struct StandPanel<Content: View>: View {
    let content: Content

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(isPad ? 22 : 14)
            .background(
                RoundedRectangle(cornerRadius: isPad ? 26 : 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.simitStand.opacity(0.94), Color.simitCounter.opacity(0.88)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: isPad ? 26 : 18, style: .continuous)
                            .stroke(Color.simitCream.opacity(isPad ? 0.24 : 0.18), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.24), radius: isPad ? 22 : 14, x: 0, y: isPad ? 13 : 9)
    }
}

struct CoachPanel<Content: View>: View {
    let content: Content
    @State private var isPulsing = false

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(isPad ? 22 : 16)
            .background(
                RoundedRectangle(cornerRadius: isPad ? 28 : 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.simitStand.opacity(0.94),
                                Color(red: 0.07, green: 0.24, blue: 0.23).opacity(0.96),
                                Color.black.opacity(0.92)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: isPad ? 28 : 22, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.simitCream.opacity(0.62), Color.simitTeal.opacity(0.34), Color.simitAmber.opacity(0.28)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: isPulsing ? 2.0 : 1.4
                            )
                    )
            )
            .scaleEffect(isPulsing ? 1.012 : 1)
            .shadow(color: Color.simitTeal.opacity(isPulsing ? 0.30 : 0.18), radius: isPad ? 24 : 16, y: isPad ? 13 : 9)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.25).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
    }
}

struct PrimaryGameButton: View {
    let title: String
    let systemImage: String
    var enabled: Bool = true
    let action: () -> Void

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(isPad ? .title3.weight(.black) : .headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, isPad ? 19 : 15)
                .background(
                    LinearGradient(
                        colors: [.simitAmber, Color(red: 0.98, green: 0.47, blue: 0.17)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .foregroundStyle(.black.opacity(0.82))
                .clipShape(RoundedRectangle(cornerRadius: isPad ? 20 : 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.48)
    }
}

struct FirstDayTipCard: View {
    let title: String
    let text: String
    let systemImage: String
    var actionTitle: String = "Anladım"
    let action: () -> Void

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        HStack(alignment: .center, spacing: isPad ? 16 : 12) {
            Image(systemName: systemImage)
                .font((isPad ? Font.title2 : Font.title3).weight(.black))
                .foregroundStyle(Color.black.opacity(0.82))
                .frame(width: isPad ? 50 : 42, height: isPad ? 50 : 42)
                .background(Color.simitAmber, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font((isPad ? Font.headline : Font.subheadline).weight(.black))
                    .foregroundStyle(Color.simitCream)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Text(text)
                    .font((isPad ? Font.subheadline : Font.caption).weight(.bold))
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Button(action: action) {
                Text(actionTitle)
                    .font(.caption.weight(.black))
                    .foregroundStyle(.black.opacity(0.82))
                    .padding(.horizontal, isPad ? 14 : 10)
                    .padding(.vertical, isPad ? 10 : 8)
                    .background(Color.simitCream, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(isPad ? 16 : 13)
        .background(
            RoundedRectangle(cornerRadius: isPad ? 22 : 18, style: .continuous)
                .fill(Color.black.opacity(0.28))
                .overlay(
                    RoundedRectangle(cornerRadius: isPad ? 22 : 18, style: .continuous)
                        .stroke(Color.simitAmber.opacity(0.32), lineWidth: 1)
                )
        )
    }
}

struct GameBackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.left")
                .font(.subheadline.weight(.black))
                .frame(width: 38, height: 38)
                .foregroundStyle(Color.simitCream)
                .background(Color.simitStand.opacity(0.84), in: Circle())
                .overlay(Circle().stroke(Color.simitAmber.opacity(0.52), lineWidth: 1.5))
                .shadow(color: .black.opacity(0.28), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Geri dön")
    }
}

struct ScreenTitle: View {
    let title: String
    let subtitle: String

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isPad ? 7 : 4) {
            Text(title)
                .font(.system(size: isPad ? 46 : 36, weight: .black, design: .rounded))
                .foregroundStyle(Color.simitCream)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
            Text(subtitle)
                .font((isPad ? Font.headline : Font.subheadline).weight(.semibold))
                .foregroundStyle(.white.opacity(0.68))
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SectionHeader: View {
    let title: String
    let systemImage: String

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        Label(title, systemImage: systemImage)
            .font((isPad ? Font.subheadline : Font.caption).weight(.black))
            .textCase(.uppercase)
            .foregroundStyle(Color.simitCream.opacity(0.78))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MetricTile: View {
    let title: String
    let value: String
    let systemImage: String
    var tint: Color = .simitAmber

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        HStack(spacing: isPad ? 13 : 10) {
            Image(systemName: systemImage)
                .font(isPad ? .title3.weight(.black) : .headline)
                .frame(width: isPad ? 42 : 30, height: isPad ? 42 : 30)
                .background(tint.opacity(0.18), in: RoundedRectangle(cornerRadius: isPad ? 12 : 8, style: .continuous))
                .foregroundStyle(tint)

            VStack(alignment: .leading, spacing: isPad ? 4 : 2) {
                Text(title.uppercased())
                    .font((isPad ? Font.caption : Font.caption2).weight(.bold))
                    .foregroundStyle(.white.opacity(0.45))
                Text(value)
                    .font((isPad ? Font.title3 : Font.headline).weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(isPad ? 15 : 11)
        .background(Color.black.opacity(0.14), in: RoundedRectangle(cornerRadius: isPad ? 18 : 14, style: .continuous))
    }
}

struct ProductMark: View {
    let product: ProductDefinition
    var size: CGFloat = 34

    var body: some View {
        ZStack {
            Circle()
                .fill(productColor.opacity(0.18))

            if let image = GameArtwork.productImage(for: product.id) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(Circle())
                    .padding(size * 0.06)
            } else {
                Image(systemName: product.symbol)
                    .font(.system(size: size * 0.42, weight: .black))
                    .foregroundStyle(productColor)
            }
        }
        .frame(width: size, height: size)
    }

    private var productColor: Color {
        switch product.id {
        case .simit: .simitAmber
        case .acma: Color(red: 0.94, green: 0.68, blue: 0.36)
        case .oliveAcma: Color(red: 0.42, green: 0.55, blue: 0.24)
        case .cheesePogaca: Color(red: 0.93, green: 0.76, blue: 0.45)
        case .tea: .simitTeal
        case .water: Color(red: 0.40, green: 0.74, blue: 0.96)
        case .ayran: Color(red: 0.73, green: 0.88, blue: 0.96)
        case .juiceBox: Color(red: 0.94, green: 0.46, blue: 0.28)
        case .cheese: .simitCream
        case .olivePaste: Color(red: 0.28, green: 0.34, blue: 0.16)
        case .chocolate: Color(red: 0.72, green: 0.43, blue: 0.28)
        case .bag: .white.opacity(0.78)
        }
    }
}

private extension GameArtwork {
    static func productImage(for product: ProductID) -> UIImage? {
        let name = "product-\(product.rawValue)"

        if let image = UIImage(named: name) {
            return image
        }

        guard let path = Bundle.main.path(forResource: name, ofType: "png") else {
            return nil
        }

        return UIImage(contentsOfFile: path)
    }
}
