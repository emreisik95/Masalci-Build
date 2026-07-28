import AVFoundation
import Foundation
import MasalciCore
import Observation

@MainActor
@Observable
final class StoryAudioPlayer {
    enum PlaybackState: Equatable {
        case idle
        case loading
        case playing
        case paused
        case failed(String)
    }

    private let player = AVPlayer()
    @ObservationIgnored nonisolated(unsafe) private var timeObserver: Any?
    @ObservationIgnored nonisolated(unsafe) private var endObserver: NSObjectProtocol?
    @ObservationIgnored nonisolated(unsafe) private var sleepTask: Task<Void, Never>?
    private(set) var currentStory: Story?
    private(set) var state: PlaybackState = .idle
    private(set) var currentTime: Double = 0
    private(set) var duration: Double = 0
    private(set) var sleepTimerEndsAt: Date?
    private var currentURL: URL?
    private var configuredSleepMinutes = 0

    init() {
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            Task { @MainActor in
                guard let self else { return }
                self.currentTime = time.seconds.isFinite ? max(0, time.seconds) : 0
                let itemDuration = self.player.currentItem?.duration.seconds ?? 0
                self.duration = itemDuration.isFinite ? max(0, itemDuration) : 0
            }
        }
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.state = .paused
                self?.currentTime = 0
                self?.player.seek(to: .zero)
                self?.cancelSleepTimer()
            }
        }
    }

    deinit {
        if let timeObserver {
            player.removeTimeObserver(timeObserver)
        }
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        sleepTask?.cancel()
    }

    func toggle(story: Story, baseURL: URL) {
        guard let audioURL = resolved(story.audioURL, relativeTo: baseURL) else {
            state = .failed("Bu masalın ses kaydı henüz hazır değil.")
            return
        }
        if currentURL != audioURL {
            load(story: story, url: audioURL)
            play()
        } else if state == .playing {
            pause()
        } else {
            play()
        }
    }

    func play() {
        guard currentURL != nil else { return }
        guard configureAudioSession() else { return }
        player.play()
        state = .playing
        scheduleSleepTimerIfNeeded()
    }

    func pause() {
        player.pause()
        state = .paused
    }

    func seek(by seconds: Double) {
        guard currentURL != nil else { return }
        let upperBound = duration > 0 ? duration : currentTime + max(0, seconds)
        let target = min(max(0, currentTime + seconds), upperBound)
        player.seek(to: CMTime(seconds: target, preferredTimescale: 600))
        currentTime = target
    }

    func stop() {
        player.pause()
        player.replaceCurrentItem(with: nil)
        currentURL = nil
        currentStory = nil
        currentTime = 0
        duration = 0
        state = .idle
        cancelSleepTimer()
    }

    func setSleepTimer(minutes: Int) {
        configuredSleepMinutes = max(0, minutes)
        cancelSleepTimer()
        if state == .playing {
            scheduleSleepTimerIfNeeded()
        }
    }

    private func load(story: Story, url: URL) {
        state = .loading
        currentStory = story
        currentURL = url
        currentTime = 0
        duration = 0
        player.replaceCurrentItem(with: AVPlayerItem(url: url))
    }

    private func configureAudioSession() -> Bool {
#if os(iOS)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio)
            try session.setActive(true)
            return true
        } catch {
            state = .failed("Ses başlatılamadı. Lütfen yeniden deneyin.")
            return false
        }
#else
        return true
#endif
    }

    private func scheduleSleepTimerIfNeeded() {
        guard configuredSleepMinutes > 0, sleepTask == nil else { return }
        let seconds = configuredSleepMinutes * 60
        sleepTimerEndsAt = Date().addingTimeInterval(TimeInterval(seconds))
        sleepTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled, let self else { return }
            self.player.pause()
            self.state = .paused
            self.sleepTask = nil
            self.sleepTimerEndsAt = nil
        }
    }

    private func cancelSleepTimer() {
        sleepTask?.cancel()
        sleepTask = nil
        sleepTimerEndsAt = nil
    }

    private func resolved(_ url: URL?, relativeTo baseURL: URL) -> URL? {
        guard let url else { return nil }
        return url.scheme == nil ? URL(string: url.relativeString, relativeTo: baseURL)?.absoluteURL : url
    }
}
