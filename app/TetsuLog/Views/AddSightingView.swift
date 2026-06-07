import SwiftUI
import SwiftData
import PhotosUI

/// 遭遇記録の入力シート。OCR・EXIF・ガチ鉄フィールドを統合。
struct AddSightingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Query(sort: \VehicleClass.name) private var classes: [VehicleClass]

    @State private var selectedClass: VehicleClass?
    @State private var selectedFormation: Formation?
    @State private var carNumber = ""
    @State private var stationName = ""
    @State private var lineName = ""
    @State private var date = Date.now
    @State private var trainNumber = ""
    @State private var kind: TrainKind = .scheduled
    @State private var headmark = ""
    @State private var livery = ""
    @State private var weather = ""
    @State private var isLastRun = false
    @State private var note = ""
    @State private var showingScanner = false
    @State private var scannedText: String?

    @State private var pickerItem: PhotosPickerItem?
    @State private var photoAttached = false
    @State private var savedPhotoFilename: String?
    @State private var previewImage: UIImage?
    @State private var latitude: Double = 0
    @State private var longitude: Double = 0

    var body: some View {
        NavigationStack {
            Form {
                Section("車両") {
                    Picker("形式", selection: $selectedClass) {
                        Text("選択").tag(VehicleClass?.none)
                        ForEach(classes) { vc in
                            Text(vc.name).tag(VehicleClass?.some(vc))
                        }
                    }
                    if selectedClass != nil {
                        Picker("編成", selection: $selectedFormation) {
                            Text("選択").tag(Formation?.none)
                            ForEach(formations) { f in
                                Text(f.code).tag(Formation?.some(f))
                            }
                        }
                    }
                    TextField("車番（クハE235-1247 等）", text: $carNumber)
                        .font(.body.monospaced())
                }

                Section {
                    Button {
                        showingScanner = true
                    } label: {
                        Label("カメラで編成番号をスキャン", systemImage: "text.viewfinder")
                    }
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        Label(photoAttached ? "写真を変更" : "写真を添付（EXIFから自動入力）",
                              systemImage: "photo.on.rectangle")
                    }
                    if let previewImage {
                        Image(uiImage: previewImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 160)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    if let scannedText {
                        LabeledContent("スキャン結果", value: scannedText)
                            .font(.callout.monospaced())
                    }
                } footer: {
                    if photoAttached {
                        Text("写真は端末内に保存されます（容量のためiCloud同期対象外）。")
                    }
                }

                Section("運転") {
                    TextField("列車番号（2024M 等）", text: $trainNumber)
                        .font(.body.monospaced())
                    Picker("種別", selection: $kind) {
                        ForEach(TrainKind.allCases, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                    }
                    Toggle("ラストラン", isOn: $isLastRun)
                }

                Section("装飾・条件") {
                    TextField("ヘッドマーク（○周年HM 等）", text: $headmark)
                    TextField("塗装・ラッピング（リバイバル 等）", text: $livery)
                    TextField("天候（晴/曇/雨/雪/夕焼け）", text: $weather)
                }

                Section("場所・日時") {
                    TextField("路線名", text: $lineName)
                    TextField("駅名", text: $stationName)
                    DatePicker("日時", selection: $date)
                }

                Section {
                    TextField("メモ", text: $note, axis: .vertical)
                }
            }
            .navigationTitle("記録を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(selectedFormation == nil)
                }
            }
            .sheet(isPresented: $showingScanner) {
                FormationScanSheet { candidate in
                    apply(candidate)
                }
            }
            .onChange(of: pickerItem) { _, newItem in
                guard let newItem else { return }
                Task { await loadPhotoMetadata(newItem) }
            }
        }
    }

    private var formations: [Formation] {
        (selectedClass?.formations ?? []).sorted { $0.code < $1.code }
    }

    /// スキャン候補を形式・編成へ照合してフォームに反映
    private func apply(_ candidate: FormationNumberParser.Candidate) {
        scannedText = candidate.raw
        Haptics.tick()

        switch candidate.kind {
        case .carNumber:
            carNumber = candidate.raw
            if let hint = candidate.classHint {
                if let match = classes.first(where: { $0.name.contains(hint) }) {
                    selectedClass = match
                }
            }
        case .formationCode:
            for vc in classes {
                if let f = vc.formations?.first(where: { $0.code == candidate.raw }) {
                    selectedClass = vc
                    selectedFormation = f
                    return
                }
            }
        }
    }

    /// 添付写真のEXIFから日時・位置を読み取り、画像を端末内に保存（すべて端末内処理）
    private func loadPhotoMetadata(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        let info = PhotoMetadata.read(from: data)
        let filename = PhotoStore.save(data)
        let image = UIImage(data: data)
        await MainActor.run {
            if let d = info.date { date = d }
            if let c = info.coordinate {
                latitude = c.latitude
                longitude = c.longitude
            }
            // 旧写真を差し替え時に掃除
            if let old = savedPhotoFilename { PhotoStore.delete(old) }
            savedPhotoFilename = filename
            previewImage = image
            photoAttached = filename != nil
            Haptics.tick()
        }
    }

    private func save() {
        let s = Sighting(date: date, stationName: stationName, lineName: lineName)
        s.formation = selectedFormation
        s.carNumber = carNumber
        s.trainNumber = trainNumber
        s.kind = isLastRun ? .lastRun : kind
        s.isLastRun = isLastRun
        s.headmark = headmark
        s.livery = livery
        s.weather = weather
        s.note = note
        s.latitude = latitude
        s.longitude = longitude
        if let savedPhotoFilename { s.photoFilenames = [savedPhotoFilename] }
        context.insert(s)
        try? context.save()

        // 廃車進行中の編成を記録した時は別ハプティクス（情緒設計）
        if selectedClass?.isRetiring == true || isLastRun {
            Haptics.farewell()
        } else {
            Haptics.success()
        }

        // 直後にコンプリート達成したか確認
        if selectedClass?.isComplete == true {
            Haptics.celebrate()
        }

        dismiss()
    }
}

#Preview {
    AddSightingView()
        .modelContainer(PreviewData.container)
}
