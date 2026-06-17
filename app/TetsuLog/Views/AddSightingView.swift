import SwiftUI
import SwiftData
import PhotosUI
import UIKit

/// 遭遇記録の入力シート。新規追加と既存編集の両対応。
struct AddSightingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(PurchaseManager.self) private var store

    @Query(sort: \VehicleClass.name) private var classes: [VehicleClass]
    @Query private var allSightings: [Sighting]
    @AppStorage("tetsulog.warnDuplicates") private var warnDuplicates = true

    /// 編集対象。nilなら新規。
    var editing: Sighting?

    /// 同じ日・同じ編成の記録が既にあれば注意文を返す（ブロックはしない）。
    private var duplicateNote: String? {
        guard warnDuplicates, let f = selectedFormation else { return nil }
        let cal = Calendar.current
        let dups = allSightings.filter { s in
            if let e = editing, s.persistentModelID == e.persistentModelID { return false }
            guard let sf = s.formation else { return false }
            return sf.persistentModelID == f.persistentModelID && cal.isDate(s.date, inSameDayAs: date)
        }
        guard !dups.isEmpty else { return nil }
        return "同じ日に \(f.code) の記録が既に\(dups.count)件あります。意図的な複数記録ならこのまま保存できます。"
    }

    private var stationSuggestions: [String] {
        Array(Set(allSightings.map(\.stationName).filter { !$0.isEmpty })).sorted()
    }
    private var lineSuggestions: [String] {
        Array(Set(allSightings.map(\.lineName).filter { !$0.isEmpty })).sorted()
    }

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

    @State private var audioFilenames: [String] = []
    @State private var audioTags: [String: String] = [:]
    @State private var showingRecorder = false
    @State private var showingPurchase = false

    @State private var loaded = false
    @State private var saveError: String?

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
                        Picker(selectedClass!.unitType.unitLabel, selection: $selectedFormation) {
                            Text("選択").tag(Formation?.none)
                            ForEach(formations) { f in
                                Text(f.code).tag(Formation?.some(f))
                            }
                        }
                    }
                    TextField("車番（クハE235-1247 等）", text: $carNumber)
                        .font(.body.monospaced())
                    if let duplicateNote {
                        Label(duplicateNote, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }

                Section {
                    Button {
                        if store.isPro { showingScanner = true } else { showingPurchase = true }
                    } label: {
                        HStack {
                            Label("カメラで編成番号をスキャン", systemImage: "text.viewfinder")
                            Spacer()
                            if !store.isPro { ProBadge() }
                        }
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

                Section {
                    Button {
                        if store.isPro { showingRecorder = true } else { showingPurchase = true }
                    } label: {
                        HStack {
                            Label(audioFilenames.isEmpty ? "走行音を録音" : "もう1本録音する",
                                  systemImage: "mic.circle")
                            Spacer()
                            if !store.isPro { ProBadge() }
                        }
                    }
                    ForEach(audioFilenames, id: \.self) { file in
                        HStack {
                            AudioPlayerRow(filename: file, tag: audioTags[file])
                            Button {
                                AudioStore.delete(file)
                                audioFilenames.removeAll { $0 == file }
                                audioTags[file] = nil
                                Haptics.tick()
                            } label: {
                                Image(systemName: "trash").foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    Text("音鉄")
                } footer: {
                    Text("録音は端末内に保存されます。容量のためiCloud同期・JSON書き出しには含まれません。")
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
                    SuggestField(title: "路線名", text: $lineName, suggestions: lineSuggestions)
                    SuggestField(title: "駅名", text: $stationName, suggestions: stationSuggestions)
                    DatePicker("日時", selection: $date)
                }

                Section {
                    TextField("メモ", text: $note, axis: .vertical)
                }

                if editing != nil {
                    Section {
                        Button(role: .destructive) {
                            deleteRecord()
                        } label: {
                            Label("この記録を削除", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .tetsuFormStyle()
            .navigationTitle(editing == nil ? "記録を追加" : "記録を編集")
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
            .sheet(isPresented: $showingRecorder) {
                AudioRecorderSheet { filename, tag in
                    audioFilenames.append(filename)
                    audioTags[filename] = tag
                }
            }
            .sheet(isPresented: $showingPurchase) { PurchaseView() }
            .onChange(of: pickerItem) { _, newItem in
                guard let newItem else { return }
                Task { await loadPhotoMetadata(newItem) }
            }
            .onAppear { loadEditingIfNeeded() }
            .alert("保存できませんでした", isPresented: .constant(saveError != nil)) {
                Button("OK") { saveError = nil }
            } message: {
                Text(saveError ?? "")
            }
        }
    }

    private var formations: [Formation] {
        (selectedClass?.formations ?? []).sorted { $0.code < $1.code }
    }

    // MARK: - 編集ロード

    private func loadEditingIfNeeded() {
        guard !loaded, let s = editing else { loaded = true; return }
        selectedFormation = s.formation
        selectedClass = s.formation?.vehicleClass
        carNumber = s.carNumber
        stationName = s.stationName
        lineName = s.lineName
        date = s.date
        trainNumber = s.trainNumber
        kind = s.kind
        headmark = s.headmark
        livery = s.livery
        weather = s.weather
        isLastRun = s.isLastRun
        note = s.note
        latitude = s.latitude
        longitude = s.longitude
        if let file = s.photoFilenames.first {
            savedPhotoFilename = file
            previewImage = PhotoStore.load(file)
            photoAttached = previewImage != nil
        }
        audioFilenames = s.audioFilenames
        audioTags = s.audioTags
        loaded = true
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
            if let old = savedPhotoFilename { PhotoStore.delete(old) }
            savedPhotoFilename = filename
            previewImage = image
            photoAttached = filename != nil
            Haptics.tick()
        }
    }

    private func save() {
        let s = editing ?? Sighting()
        s.date = date
        s.stationName = stationName
        s.lineName = lineName
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
        s.audioFilenames = audioFilenames
        // 削除済みファイルのタグを掃除してから保存
        s.audioTags = audioTags.filter { audioFilenames.contains($0.key) }

        if editing == nil { context.insert(s) }
        do {
            try context.save()
        } catch {
            // 新規挿入が失敗したらロールバックしてユーザーに通知（静かな消失を防ぐ）
            if editing == nil { context.delete(s) }
            saveError = "記録を保存できませんでした。空き容量やiCloudの状態をご確認ください。(\(error.localizedDescription))"
            Haptics.tick()
            return
        }

        if editing == nil {
            if selectedClass?.isRetiring == true || isLastRun {
                Haptics.farewell()
            } else {
                Haptics.success()
            }
            if selectedClass?.isComplete == true { Haptics.celebrate() }
        } else {
            Haptics.success()
        }

        dismiss()
    }

    private func deleteRecord() {
        guard let s = editing else { return }
        for file in s.photoFilenames { PhotoStore.delete(file) }
        for file in s.audioFilenames { AudioStore.delete(file) }
        context.delete(s)
        try? context.save()
        Haptics.tick()
        dismiss()
    }
}

#Preview {
    AddSightingView()
        .modelContainer(PreviewData.container)
        .environment(PurchaseManager())
}
