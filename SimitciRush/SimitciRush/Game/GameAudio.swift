import AVFoundation
import Foundation

@MainActor
final class GameAudio {
    static let shared = GameAudio()

    enum Effect: String {
        case coin = "coin"
        case denied = "denied"
        case upgrade = "upgrade"
        case report = "report"
        case loan = "loan"
        case levelUp = "level-up"
        case countdown = "countdown"
        case rushEnd = "rush-end"
        case bankruptcy = "bankruptcy"
        case ferryHorn = "ferry-horn"
    }

    enum Ambience: String {
        case shop = "ambient-shop"
        case crowd = "ambient-crowd"

        var fileExtension: String {
            self == .shop ? "mp3" : "wav"
        }
    }

    private var effectPlayers: [Effect: AVAudioPlayer] = [:]
    private var ambiencePlayer: AVAudioPlayer?
    private var activeAmbience: Ambience?

    private init() {}

    func play(_ effect: Effect, volume: Float = 0.65) {
        let fileExtension = effect == .ferryHorn ? "mp3" : "wav"
        guard isEnabled, let url = Bundle.main.url(forResource: effect.rawValue, withExtension: fileExtension) else { return }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = volume
            player.prepareToPlay()
            player.play()
            effectPlayers[effect] = player

            if effect == .ferryHorn {
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(6800))
                    if effectPlayers[effect] === player {
                        player.stop()
                        effectPlayers[effect] = nil
                    }
                }
            }
        } catch {
            effectPlayers[effect] = nil
        }
    }

    func startAmbience(_ ambience: Ambience, volume: Float) {
        guard isEnabled else {
            stopAmbience()
            return
        }
        guard activeAmbience != ambience else { return }
        guard let url = Bundle.main.url(forResource: ambience.rawValue, withExtension: ambience.fileExtension) else { return }

        do {
            ambiencePlayer?.stop()
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = volume
            player.prepareToPlay()
            player.play()
            ambiencePlayer = player
            activeAmbience = ambience
        } catch {
            stopAmbience()
        }
    }

    func stopAmbience() {
        ambiencePlayer?.stop()
        ambiencePlayer = nil
        activeAmbience = nil
    }

    private var isEnabled: Bool {
        UserDefaults.standard.object(forKey: "simitci-rush-sound-enabled") as? Bool ?? true
    }
}
