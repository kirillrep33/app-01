import Foundation
import AVFoundation
import AudioToolbox

final class SoundManager {
    static let shared = SoundManager()
    
    private var audioPlayer: AVAudioPlayer?
    
    private init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }
    
    func playButtonSound() {
        if let soundURL = Bundle.main.url(forResource: "button", withExtension: "mp3") {
            playSound(url: soundURL)
        } else if let soundURL = Bundle.main.url(forResource: "button", withExtension: "wav") {
            playSound(url: soundURL)
        } else if let soundURL = Bundle.main.url(forResource: "button", withExtension: "m4a") {
            playSound(url: soundURL)
        } else {
            AudioServicesPlaySystemSound(1104)
        }
    }
    
    private func playSound(url: URL) {
        if let player = try? AVAudioPlayer(contentsOf: url) {
            audioPlayer = player
            player.prepareToPlay()
            player.play()
        } else {
            AudioServicesPlaySystemSound(1104)
        }
    }
}
