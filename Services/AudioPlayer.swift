//
//  AudioPlayer.swift
//  AplicacionMusicaiOS
//

import Foundation
import AVFoundation
import Combine

@MainActor
class AudioPlayer: ObservableObject {
    static let shared = AudioPlayer()

    private var player: AVPlayer?
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()

    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var isShuffleOn: Bool = false
    @Published var repeatMode: RepeatMode = .none

    @Published var currentSong: Song?
    @Published var playQueue: [Song] = []
    @Published var currentIndex: Int = 0

    private var originalQueue: [Song] = []

    private init() {
        setupAudioSession()
        setupNotifications()
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Error setting up audio session: \(error)")
        }
    }

    private func setupNotifications() {
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.handleSongEnded()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Playback Control

    func play(song: Song, queue: [Song], index: Int) async {
        currentSong = song
        originalQueue = queue
        currentIndex = index

        if isShuffleOn {
            var shuffled = queue
            shuffled.remove(at: index)
            shuffled.shuffle()
            shuffled.insert(song, at: 0)
            playQueue = shuffled
            currentIndex = 0
        } else {
            playQueue = queue
        }

        await loadAndPlay(song)
    }

    private func loadAndPlay(_ song: Song) async {
        do {
            let url = try await OnlineRepository.shared.getAudioURL(for: song.audioPath)
            let playerItem = AVPlayerItem(url: url)

            if player == nil {
                player = AVPlayer(playerItem: playerItem)
            } else {
                player?.replaceCurrentItem(with: playerItem)
            }

            // Observe duration
            playerItem.publisher(for: \.status)
                .filter { $0 == .readyToPlay }
                .sink { [weak self] _ in
                    Task { @MainActor in
                        self?.duration = playerItem.duration.seconds.isNaN ? 0 : playerItem.duration.seconds
                    }
                }
                .store(in: &cancellables)

            setupTimeObserver()
            player?.play()
            isPlaying = true

        } catch {
            print("Error loading audio: \(error)")
        }
    }

    private func setupTimeObserver() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }

        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor in
                self?.currentTime = time.seconds.isNaN ? 0 : time.seconds
            }
        }
    }

    func togglePlayPause() {
        if isPlaying {
            player?.pause()
        } else {
            player?.play()
        }
        isPlaying.toggle()
    }

    func pause() {
        player?.pause()
        isPlaying = false
    }

    func resume() {
        player?.play()
        isPlaying = true
    }

    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime)
    }

    func next() {
        guard !playQueue.isEmpty else { return }

        if isShuffleOn {
            let randomIndex = Int.random(in: 0..<playQueue.count)
            currentIndex = randomIndex
        } else {
            currentIndex = (currentIndex + 1) % playQueue.count
        }

        currentSong = playQueue[currentIndex]
        if let song = currentSong {
            Task {
                await loadAndPlay(song)
            }
        }
    }

    func previous() {
        guard !playQueue.isEmpty else { return }

        // If more than 3 seconds played, restart song
        if currentTime > 3 {
            seek(to: 0)
            return
        }

        if isShuffleOn {
            let randomIndex = Int.random(in: 0..<playQueue.count)
            currentIndex = randomIndex
        } else {
            currentIndex = currentIndex > 0 ? currentIndex - 1 : playQueue.count - 1
        }

        currentSong = playQueue[currentIndex]
        if let song = currentSong {
            Task {
                await loadAndPlay(song)
            }
        }
    }

    func toggleShuffle() {
        isShuffleOn.toggle()

        if isShuffleOn {
            // Shuffle queue keeping current song at current position
            guard let current = currentSong else { return }
            var shuffled = originalQueue
            shuffled.removeAll { $0.id == current.id }
            shuffled.shuffle()
            shuffled.insert(current, at: 0)
            playQueue = shuffled
            currentIndex = 0
        } else {
            // Restore original order
            if let current = currentSong,
               let index = originalQueue.firstIndex(where: { $0.id == current.id }) {
                playQueue = originalQueue
                currentIndex = index
            }
        }
    }

    func toggleRepeat() {
        repeatMode = repeatMode.next()
    }

    private func handleSongEnded() {
        switch repeatMode {
        case .none:
            if currentIndex < playQueue.count - 1 {
                next()
            } else {
                isPlaying = false
            }
        case .one:
            seek(to: 0)
            player?.play()
        case .all:
            next()
        }
    }

    // MARK: - Utilities

    func formatTime(_ time: TimeInterval) -> String {
        guard !time.isNaN && time.isFinite else { return "0:00" }
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    func stop() {
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        isPlaying = false
        currentSong = nil
        currentTime = 0
        duration = 0
    }
}
