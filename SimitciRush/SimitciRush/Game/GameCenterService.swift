import Foundation
import GameKit
import UIKit

enum GameCenterStatus: Equatable {
    case unavailable
    case authenticating
    case authenticated(String)
    case failed

    var title: String {
        switch self {
        case .unavailable: "Kapalı"
        case .authenticating: "Bağlanıyor"
        case .authenticated(let name): name
        case .failed: "Bağlanamadı"
        }
    }

    var detail: String {
        switch self {
        case .unavailable: "Game Center oturumu yok."
        case .authenticating: "Game Center oturumu kontrol ediliyor."
        case .authenticated: "Skorlar sıralamalara gönderilir."
        case .failed: "Ayarlar'dan tekrar bağlanmayı deneyebilirsin."
        }
    }

    var systemImage: String {
        switch self {
        case .unavailable: "gamecontroller"
        case .authenticating: "arrow.triangle.2.circlepath"
        case .authenticated: "trophy.fill"
        case .failed: "exclamationmark.triangle.fill"
        }
    }

    var isAuthenticated: Bool {
        if case .authenticated = self { return true }
        return false
    }
}

enum GameCenterLeaderboardID: String, CaseIterable {
    case esnafScore = "com.totalabs.simitcirush.reputation"
    case cash = "com.totalabs.simitcirush.cash"
    case bestDay = "com.totalabs.simitcirush.bestday"
    case days = "com.totalabs.simitcirush.days"
}

enum GameCenterAchievementID: String {
    case debtFreeSevenDays = "com.totalabs.simitcirush.achievement.debtfree7"
    case hundredSimitSold = "com.totalabs.simitcirush.achievement.simit100"
    case firstComboFive = "com.totalabs.simitcirush.achievement.combo5"
    case istanbulSimitcisi = "com.totalabs.simitcirush.achievement.istanbulsimitcisi"
}

struct GameCenterScores {
    let esnafScore: Int
    let cash: Int
    let bestDay: Int
    let days: Int
}

struct GameCenterAchievementProgress {
    let id: GameCenterAchievementID
    let percent: Double
}

@MainActor
final class GameCenterService: NSObject, ObservableObject, GKGameCenterControllerDelegate {
    static let shared = GameCenterService()

    @Published private(set) var status: GameCenterStatus = .unavailable

    private override init() {
        super.init()
    }

    func authenticate() {
        status = .authenticating
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            Task { @MainActor in
                guard let self else { return }

                if let viewController {
                    self.present(viewController)
                    return
                }

                if GKLocalPlayer.local.isAuthenticated {
                    self.status = .authenticated(GKLocalPlayer.local.displayName)
                } else if error != nil {
                    self.status = .failed
                } else {
                    self.status = .unavailable
                }
            }
        }
    }

    func submit(_ scores: GameCenterScores) {
        guard GKLocalPlayer.local.isAuthenticated else { return }

        submit(max(0, scores.esnafScore), to: .esnafScore)
        submit(max(0, scores.cash), to: .cash)
        submit(max(0, scores.bestDay), to: .bestDay)
        submit(max(0, scores.days), to: .days)
    }

    func submitAchievements(_ progress: [GameCenterAchievementProgress]) {
        guard GKLocalPlayer.local.isAuthenticated else { return }

        let achievements = progress.map { item in
            let achievement = GKAchievement(identifier: item.id.rawValue)
            achievement.percentComplete = min(100, max(0, item.percent))
            achievement.showsCompletionBanner = item.percent >= 100
            return achievement
        }

        guard !achievements.isEmpty else { return }

        GKAchievement.report(achievements) { error in
            if error != nil {
                // Achievement failures should not interrupt gameplay.
            }
        }
    }

    func showLeaderboards() {
        guard GKLocalPlayer.local.isAuthenticated else {
            authenticate()
            return
        }

        let viewController = GKGameCenterViewController(
            leaderboardID: GameCenterLeaderboardID.esnafScore.rawValue,
            playerScope: .global,
            timeScope: .allTime
        )
        viewController.gameCenterDelegate = self
        present(viewController)
    }

    nonisolated func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        Task { @MainActor in
            gameCenterViewController.dismiss(animated: true)
        }
    }

    private func submit(_ score: Int, to leaderboard: GameCenterLeaderboardID) {
        GKLeaderboard.submitScore(
            score,
            context: 0,
            player: GKLocalPlayer.local,
            leaderboardIDs: [leaderboard.rawValue]
        ) { error in
            if error != nil {
                // Score submit failures should not interrupt gameplay.
            }
        }
    }

    private func present(_ viewController: UIViewController) {
        guard let presenter = UIApplication.shared.topViewController else { return }
        presenter.present(viewController, animated: true)
    }
}

private extension UIApplication {
    var topViewController: UIViewController? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController?
            .topMostViewController
    }
}

private extension UIViewController {
    var topMostViewController: UIViewController {
        if let presentedViewController {
            return presentedViewController.topMostViewController
        }

        if let navigationController = self as? UINavigationController {
            return navigationController.visibleViewController?.topMostViewController ?? navigationController
        }

        if let tabBarController = self as? UITabBarController {
            return tabBarController.selectedViewController?.topMostViewController ?? tabBarController
        }

        return self
    }
}
