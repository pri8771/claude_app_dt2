import Foundation
import AVFoundation
import Combine

/// Drives a single prayer session: tracks elapsed time and progress, and plays
/// bundled audio in Listen mode. Audio is optional and local only — if the
/// asset is missing, Listen degrades gracefully to a timed text experience.
@MainActor
final class PlayerController: ObservableObject {
    @Published private(set) var progress: Double = 0   // 0...1
    @Published private(set) var isRunning = false
    @Published private(set) var isFinished = false
    /// True when Listen was requested but no audio could be loaded.
    @Published private(set) var audioUnavailable = false

    private let prayer: Prayer
    private var mode: PlayMode
    private var audioPlayer: AVAudioPlayer?
    private var timer: AnyCancellable?
    private var elapsed: TimeInterval = 0

    private var duration: TimeInterval { max(1, TimeInterval(prayer.durationSeconds)) }

    init(prayer: Prayer, mode: PlayMode) {
        self.prayer = prayer
        self.mode = mode
    }

    /// Change mode mid-session (resets progress).
    func setMode(_ newMode: PlayMode) {
        guard newMode != mode else { return }
        stop()
        mode = newMode
        reset()
    }

    func reset() {
        progress = 0
        elapsed = 0
        isFinished = false
        audioUnavailable = false
    }

    func start() {
        guard !isRunning else { return }
        if isFinished { reset() }
        isRunning = true

        if mode == .listen, prepareAudio() {
            audioPlayer?.play()
        }
        startTimer()
    }

    func pause() {
        isRunning = false
        audioPlayer?.pause()
        timer?.cancel()
        timer = nil
    }

    func stop() {
        pause()
        audioPlayer?.stop()
        audioPlayer = nil
    }

    private func startTimer() {
        timer = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    private func tick() {
        guard isRunning else { return }
        // Prefer real audio time when available; otherwise advance by wall time.
        if mode == .listen, let player = audioPlayer, player.duration > 0 {
            elapsed = player.currentTime
            progress = min(1, elapsed / player.duration)
            if !player.isPlaying && progress >= 0.99 { finish() }
        } else {
            elapsed += 0.1
            progress = min(1, elapsed / duration)
            if progress >= 1 { finish() }
        }
    }

    private func finish() {
        progress = 1
        isRunning = false
        isFinished = true
        timer?.cancel()
        timer = nil
        audioPlayer?.stop()
    }

    /// Attempt to load the prayer's bundled audio. Returns false (and flags
    /// `audioUnavailable`) when no asset exists, so the caller can fall back.
    private func prepareAudio() -> Bool {
        guard let name = prayer.audioAssetName, !name.isEmpty else {
            audioUnavailable = true
            return false
        }
        let candidates = ["m4a", "mp3", "caf", "wav"]
        let url = candidates
            .lazy
            .compactMap { Bundle.main.url(forResource: name, withExtension: $0) }
            .first

        guard let url else {
            audioUnavailable = true
            return false
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            audioPlayer = player
            audioUnavailable = false
            return true
        } catch {
            audioUnavailable = true
            return false
        }
    }
}
