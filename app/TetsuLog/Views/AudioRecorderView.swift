import SwiftUI
import AVFoundation

/// 録音セッションのモデル。AVAudioRecorder をラップし、UIに状態を提供。
@MainActor
@Observable
final class AudioRecorderModel: NSObject, AVAudioRecorderDelegate {
    var isRecording = false
    var elapsed: TimeInterval = 0
    var meterLevel: Float = 0       // 0...1
    var savedFilename: String?
    var permissionDenied = false

    private var recorder: AVAudioRecorder?
    private var timer: Timer?

    func start() {
        // iOS 17+ のマイク許可API
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            Task { @MainActor in
                guard let self else { return }
                if granted {
                    self.beginRecording()
                } else {
                    self.permissionDenied = true
                }
            }
        }
    }

    private func beginRecording() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)

            let url = AudioStore.newRecordingURL()
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
            ]
            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.delegate = self
            recorder?.isMeteringEnabled = true
            recorder?.record()
            isRecording = true
            elapsed = 0
            startTimer()
            Haptics.tick()
        } catch {
            print("録音開始失敗: \(error)")
        }
    }

    func stop() {
        guard isRecording else { return }
        recorder?.stop()
        timer?.invalidate(); timer = nil
        isRecording = false
        if let url = recorder?.url {
            savedFilename = url.lastPathComponent
        }
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        Haptics.success()
    }

    func discard() {
        if isRecording { stop() }
        if let f = savedFilename { AudioStore.delete(f); savedFilename = nil }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let rec = self.recorder, self.isRecording else { return }
                self.elapsed = rec.currentTime
                rec.updateMeters()
                let avg = rec.averagePower(forChannel: 0)
                // -60dB..0dB を 0..1 に正規化
                self.meterLevel = max(0, min(1, (avg + 60) / 60))
            }
        }
    }
}

/// 録音シート。録音→保存ボタンで親View（AddSighting）にファイル名を返す。
struct AudioRecorderSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model = AudioRecorderModel()
    @State private var tag: String = AudioTag.default
    var onSave: (String, String) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer()

                // 録音の種別タグ
                Picker("種別", selection: $tag) {
                    ForEach(AudioTag.all, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                Text(timeString(model.elapsed))
                    .font(.system(size: 56, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundStyle(model.isRecording ? .red : .primary)

                // レベルメータ
                HStack(spacing: 4) {
                    ForEach(0..<24, id: \.self) { i in
                        let threshold = Float(i) / 24
                        let active = model.meterLevel >= threshold
                        Capsule()
                            .fill(active ? barColor(for: threshold) : Color(.tertiarySystemFill))
                            .frame(width: 6, height: 8 + CGFloat(i) * 2)
                    }
                }
                .frame(height: 70)
                .animation(.linear(duration: 0.1), value: model.meterLevel)

                Spacer()

                if model.permissionDenied {
                    Text("マイクへのアクセスが許可されていません。\n設定アプリで TetsuLog のマイク権限を有効にしてください。")
                        .font(.callout)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                } else {
                    // 録音/停止ボタン
                    Button {
                        if model.isRecording { model.stop() } else { model.start() }
                    } label: {
                        ZStack {
                            Circle()
                                .stroke(.red, lineWidth: 4)
                                .frame(width: 88, height: 88)
                            RoundedRectangle(cornerRadius: model.isRecording ? 8 : 36)
                                .fill(.red)
                                .frame(width: model.isRecording ? 36 : 72,
                                       height: model.isRecording ? 36 : 72)
                                .animation(.spring(response: 0.3), value: model.isRecording)
                        }
                    }
                    .buttonStyle(.plain)

                    Text(model.isRecording ? "タップで停止" : (model.savedFilename != nil ? "録り直すにはもう一度タップ" : "タップで録音開始"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("音を録る")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        model.discard()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        if let f = model.savedFilename {
                            onSave(f, tag)
                        }
                        dismiss()
                    }
                    .disabled(model.savedFilename == nil || model.isRecording)
                }
            }
        }
    }

    private func timeString(_ t: TimeInterval) -> String {
        let s = Int(t)
        return String(format: "%d:%02d", s / 60, s % 60)
    }
    private func barColor(for level: Float) -> Color {
        switch level {
        case ..<0.6: return .green
        case ..<0.85: return .orange
        default: return .red
        }
    }
}
