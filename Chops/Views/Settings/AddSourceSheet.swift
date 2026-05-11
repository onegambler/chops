import SwiftUI

struct AddSourceSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var sourceStore = SourceStore.shared
    @State private var kind: SourceKind = .local
    @State private var localPath = ""
    @State private var repoURL = ""
    @State private var branch = ""
    @State private var isWorking = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            Text("Add Source")
                .font(.headline)

            Picker("Type", selection: $kind) {
                ForEach(SourceKind.allCases) { kind in
                    Label(kind.displayName, systemImage: kind.iconName).tag(kind)
                }
            }
            .pickerStyle(.segmented)

            Form {
                switch kind {
                case .local:
                    HStack {
                        TextField("Folder", text: $localPath, prompt: Text("~/Projects/skills"))
                        Button("Choose...") { chooseFolder() }
                    }
                case .git:
                    TextField("GitHub URL", text: $repoURL, prompt: Text("https://github.com/org/repo"))
                    TextField("Branch", text: $branch, prompt: Text("Optional"))
                }
            }
            .formStyle(.grouped)

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .textSelection(.enabled)
            }

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button {
                    addSource()
                } label: {
                    if isWorking {
                        ProgressView().controlSize(.small)
                    } else {
                        Text("Add")
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(isWorking || !canAdd)
            }
        }
        .padding(20)
        .frame(width: 460)
    }

    private var canAdd: Bool {
        switch kind {
        case .local:
            return !localPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .git:
            return !repoURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.showsHiddenFiles = true
        guard panel.runModal() == .OK, let url = panel.url else { return }
        localPath = url.path
    }

    private func addSource() {
        errorMessage = nil
        isWorking = true

        switch kind {
        case .local:
            do {
                try sourceStore.addLocalSource(path: localPath)
                NotificationCenter.default.post(name: .customScanPathsChanged, object: nil)
                isWorking = false
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isWorking = false
            }
        case .git:
            Task {
                do {
                    try await sourceStore.addGitSource(url: repoURL, branch: branch)
                    NotificationCenter.default.post(name: .customScanPathsChanged, object: nil)
                    await MainActor.run {
                        isWorking = false
                        dismiss()
                    }
                } catch {
                    await MainActor.run {
                        errorMessage = error.localizedDescription
                        isWorking = false
                    }
                }
            }
        }
    }
}
