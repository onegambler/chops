import SwiftUI

struct SourcesSettingsView: View {
    @State private var sourceStore = SourceStore.shared
    @State private var showingAddSheet = false
    @State private var rowRefreshID = UUID()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sources")
                .font(.headline)

            Text("Add local folders or GitHub repositories. Chops scans Sources for SKILL.md files and makes them available in Library > Skills.")
                .font(.caption)
                .foregroundStyle(.secondary)

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(sourceStore.sources) { source in
                        SourceRow(source: source, refreshID: rowRefreshID)
                        if source.id != sourceStore.sources.last?.id {
                            Divider()
                        }
                    }
                }
            }
            .frame(minHeight: 160)

            if sourceStore.sources.isEmpty {
                Text("No sources added.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack {
                Spacer()
                Button("Add Source...") {
                    showingAddSheet = true
                }
            }
        }
        .padding()
        .sheet(isPresented: $showingAddSheet) {
            AddSourceSheet()
        }
        .onReceive(NotificationCenter.default.publisher(for: .customScanPathsChanged)) { _ in
            sourceStore.reload()
            rowRefreshID = UUID()
        }
    }
}

private struct SourceRow: View {
    let source: Source
    let refreshID: UUID
    @State private var sourceStore = SourceStore.shared
    @State private var skillCount = 0
    @State private var isSyncing = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Image(systemName: source.kind.iconName)
                    .foregroundStyle(.secondary)
                    .frame(width: 18)

                VStack(alignment: .leading, spacing: 3) {
                    Text(source.displayName)
                        .font(.body.weight(.medium))
                    Text(source.displayPath)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fontDesign(.monospaced)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    HStack(spacing: 8) {
                        Text(source.kind.displayName)
                        Text("\(skillCount) skill\(skillCount == 1 ? "" : "s")")
                        if let lastScanned = source.lastScannedAt {
                            Text("Scanned \(lastScanned.formatted(.relative(presentation: .named)))")
                        }
                        if let lastSynced = source.lastSyncedAt {
                            Text("Synced \(lastSynced.formatted(.relative(presentation: .named)))")
                        }
                    }
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                }

                Spacer()

                HStack(spacing: 6) {
                    Button("Rescan") {
                        rescan()
                    }
                    if source.kind == .git {
                        Button {
                            sync()
                        } label: {
                            if isSyncing {
                                ProgressView().controlSize(.small)
                            } else {
                                Text("Sync")
                            }
                        }
                        .disabled(isSyncing)
                    }
                    Button("Reveal") {
                        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: source.scanRootPath)
                    }
                    Button(role: .destructive) {
                        remove()
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }
            }

            if let message = errorMessage ?? source.lastError {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .textSelection(.enabled)
            }
        }
        .padding(.vertical, 6)
        .task(id: source.id + refreshID.uuidString) {
            skillCount = SourceSkillScanner.skillCount(in: source)
        }
    }

    private func rescan() {
        skillCount = SourceSkillScanner.skillCount(in: source)
        sourceStore.markScanned(source.id)
        NotificationCenter.default.post(name: .customScanPathsChanged, object: nil)
    }

    private func sync() {
        isSyncing = true
        errorMessage = nil
        Task {
            await sourceStore.sync(source)
            await MainActor.run {
                skillCount = SourceSkillScanner.skillCount(in: source)
                isSyncing = false
                NotificationCenter.default.post(name: .customScanPathsChanged, object: nil)
            }
        }
    }

    private func remove() {
        do {
            try sourceStore.remove(source)
            NotificationCenter.default.post(name: .customScanPathsChanged, object: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
