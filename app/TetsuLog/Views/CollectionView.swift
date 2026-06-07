import SwiftUI
import SwiftData

/// 図鑑タブ: 形式ごとの編成コレクション率を表示
struct CollectionView: View {
    @Query(sort: \VehicleClass.name) private var classes: [VehicleClass]

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 14)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(classes) { vc in
                        NavigationLink(value: vc) {
                            ClassCard(vehicleClass: vc)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("図鑑")
            .navigationDestination(for: VehicleClass.self) { vc in
                ClassDetailView(vehicleClass: vc)
            }
        }
    }
}

private struct ClassCard: View {
    let vehicleClass: VehicleClass

    private var total: Int { vehicleClass.formations?.count ?? 0 }
    private var collected: Int {
        vehicleClass.formations?.filter { $0.isCollected }.count ?? 0
    }
    private var ratio: Double { total == 0 ? 0 : Double(collected) / Double(total) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(vehicleClass.name)
                    .font(.headline)
                Spacer()
                if vehicleClass.isRetiring {
                    Text("廃車進行")
                        .font(.caption2.bold())
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(.red.opacity(0.2), in: Capsule())
                        .foregroundStyle(.red)
                }
            }
            Text(vehicleClass.operatorName)
                .font(.caption)
                .foregroundStyle(.secondary)

            ProgressView(value: ratio)
                .tint(.orange)

            Text("\(collected) / \(total) 編成")
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

/// 形式詳細: 編成一覧
struct ClassDetailView: View {
    let vehicleClass: VehicleClass

    private var formations: [Formation] {
        (vehicleClass.formations ?? []).sorted { $0.code < $1.code }
    }

    var body: some View {
        List {
            Section {
                ForEach(formations) { f in
                    HStack {
                        Image(systemName: f.isCollected ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(f.isCollected ? .green : .secondary)
                        Text(f.code)
                        Spacer()
                        if let count = f.sightings?.count, count > 0 {
                            Text("\(count)回")
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                        if !f.isActive {
                            Image(systemName: "xmark.bin")
                                .foregroundStyle(.red)
                        }
                    }
                }
            } header: {
                Text("\(formations.count) 編成")
            }
        }
        .navigationTitle(vehicleClass.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    CollectionView()
        .modelContainer(PreviewData.container)
}
