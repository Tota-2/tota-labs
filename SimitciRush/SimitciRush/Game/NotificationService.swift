import Foundation
import UserNotifications

@MainActor
final class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let center = UNUserNotificationCenter.current()
    private let mainServiceIdentifier = "simitci.main-service-reminder"
    private let extraServiceIdentifier = "simitci.extra-service-reminder"
    private let dailyRewardIdentifier = "simitci.daily-reward-reminder"

    private init() {
        refreshAuthorizationStatus()
    }

    func refreshAuthorizationStatus() {
        center.getNotificationSettings { [weak self] settings in
            Task { @MainActor in
                self?.authorizationStatus = settings.authorizationStatus
            }
        }
    }

    func requestAuthorizationIfNeeded() async -> Bool {
        refreshAuthorizationStatus()

        if authorizationStatus == .authorized || authorizationStatus == .provisional {
            return true
        }

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            refreshAuthorizationStatus()
            return granted
        } catch {
            refreshAuthorizationStatus()
            return false
        }
    }

    func cancelAllGameReminders() {
        center.removePendingNotificationRequests(withIdentifiers: [
            mainServiceIdentifier,
            extraServiceIdentifier,
            dailyRewardIdentifier
        ])
    }

    func scheduleGameReminders(
        enabled: Bool,
        hasPlayedMainService: Bool,
        hasExtraServiceAvailable: Bool,
        extraServiceUnlockDate: Date?,
        hasClaimableDailyReward: Bool
    ) {
        cancelAllGameReminders()
        guard enabled else { return }

        center.getNotificationSettings { [weak self] settings in
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }

            Task { @MainActor in
                guard let self else { return }

                if !hasPlayedMainService {
                    self.schedule(
                        identifier: self.mainServiceIdentifier,
                        title: "Tezgâh bekliyor",
                        body: "Bugünün servisi açılmadı. Simitler soğumadan tezgâha geç.",
                        minutesFromNow: 180
                    )
                }

                if hasExtraServiceAvailable {
                    if let extraServiceUnlockDate, extraServiceUnlockDate > Date() {
                        self.schedule(
                            identifier: self.extraServiceIdentifier,
                            title: "Ek servis açıldı",
                            body: "Kuyruk yeniden hareketlendi. İstersen kısa bir ek servis açabilirsin.",
                            date: extraServiceUnlockDate
                        )
                    }
                }

                if hasClaimableDailyReward {
                    self.schedule(
                        identifier: self.dailyRewardIdentifier,
                        title: "Ödül defterde kaldı",
                        body: "Günlük hedef ödülün hazır. Kasaya işlemeden günü kapatma.",
                        minutesFromNow: 45
                    )
                }
            }
        }
    }

    private func schedule(identifier: String, title: String, body: String, minutesFromNow: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: minutesFromNow * 60, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request)
    }

    private func schedule(identifier: String, title: String, body: String, date: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let interval = max(60, date.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request)
    }
}
