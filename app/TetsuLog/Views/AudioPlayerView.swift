import SwiftUI
import AVFoundation

@MainActor
@Observable
final class AudioPlayerModel: NSObject, AVAudioPlayerDelegate {
    var isPlaying = false
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0
    private var player: AVAudioPlayer?
    private var timer: Timer?

    func load(filename: String) {
        let url = AudioStore.url(for: filename)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        player = try? AVAudioPlayer(contentsOf: url)
        player?.delegate = self
        duration = player?.duration ?? 0
    }

    func playOrPause() {
        guard let player else { return }
        if isPlaying {
            player.pause()
            isPlaying = false
            timer?.invalidate(); timer = nil
        } else {
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try? AVAudioSession.sharedInstance().setActive(true)
            player.play()
            isPlaying = true
            startTimer()
        }
    }

    func stop() {
        player?.stop()
        player?.currentTime = 0
        isPlaying = false
        currentTime = 0
        timer?.invalidate(); timer = nil
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
            self.currentTime = 0
            self.timer?.invalidate(); self.timer = nil
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let p = self.player else { return }
                self.currentTime = p.currentTime
            }
        }
    }
}

/// 遭遇記録に添付された録音を再生する小さなプレイヤー
struct AudioPlayerRow: View {
    let filename: String
    @State private var player = AudioPlayerModel()

    var body: some View {
        HStack(spacing: 12) {
            Button { player.playOrPause() } label: {
                Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                ProgressView(value: progress)
                    .tint(.green)
                HStack {
                    Text(timeString(player.currentTime))
                        .font(.caption2.monospaced())
                    Spacer()
                    Text(timeString(player.duration))
                        .font(.caption2.monospaced())
                }
                .foregroundStyle(.secondary)
            }
            Image(systemName: "waveform")
                .foregroundStyle(.green)
        }
        .padding(.vertical, 4)
        .onAppear { player.load(filename: filename) }
        .onDisappear { player.stop() }
    }

    private var progress: Double {
        guard player.duration > 0 else { return 0 }
        return player.currentTime / player.duration
    }

    private func timeString(_ t: TimeInterval) -> String {
        let s = Int(t)
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}
