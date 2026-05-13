import SwiftUI
import SwiftData

struct SidebarView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Skill.name) private var allSkills: [Skill]
    @Query(sort: \RemoteServer.label) private var servers: [RemoteServer]
    @Query(sort: \WatchedRepo.label) private var repos: [WatchedRepo]
    @State private var syncingServerIDs: Set<String> = []
    @State private var serverErrors: [String: String] = [:]
    @State private var showingErrorForServer: String?
    @State private var scanningRepoPaths: Set<String> = []
    @State private var repoErrors: [String: String] = [:]
    @State private var showingErrorForRepo: String?
    @State private var showingAddRepo = false

    private var activeSources: [ToolSource] {
        ToolSource.allCases.filter { tool in
            guard tool.listable else { return false }
            return allSkills.contains { $0.toolSources.contains(tool) }
        }
    }

    private func toolCount(_ tool: ToolSource) -> Int {
        allSkills.filter { $0.toolSources.contains(tool) }.count
    }

    private func repoSkillCount(_ repo: WatchedRepo) -> Int {
        allSkills.filter { !$0.isRemote && $0.filePath.hasPrefix(repo.path) }.count
    }

    var body: some View {
        @Bindable var appState = appState

        List(selection: $appState.sidebarFilter) {
            Section("Library") {
                Label("Skills", systemImage: "doc.text")
                    .badge(allSkills.filter { $0.itemKind == .skill }.count)
                    .tag(SidebarFilter.allSkills)

                Label("Agents", systemImage: "person.crop.rectangle")
                    .badge(allSkills.filter { $0.itemKind == .agent }.count)
                    .tag(SidebarFilter.allAgents)

                Label("Rules", systemImage: "list.bullet.rectangle")
                    .badge(allSkills.filter { $0.itemKind == .rule }.count)
                    .tag(SidebarFilter.allRules)

                Label("Favorites", systemImage: "star")
                    .badge(allSkills.filter(\.isFavorite).count)
                    .tag(SidebarFilter.favorites)
            }

            Section("Tools") {
                ForEach(activeSources) { tool in
                    Label {
                        Text(tool.displayName)
                    } icon: {
                        ToolIcon(tool: tool)
                    }
                    .badge(toolCount(tool))
                    .tag(SidebarFilter.tool(tool))
                }
            }

            Section("Repos") {
                ForEach(repos) { repo in
                    HStack {
                        Label {
                            Text(repo.label)
                        } icon: {
                            Image(systemName: "folder.badge.gearshape")
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if let error = repoErrors[repo.path] {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(.red)
                                .popover(isPresented: Binding(
                                    get: { showingErrorForRepo == repo.path },
                                    set: { if !$0 { showingErrorForRepo = nil } }
                                )) {
                                    Text(error)
                                        .font(.caption)
                                        .padding()
                                        .frame(maxWidth: 250)
                                }
                                .onTapGesture {
                                    showingErrorForRepo = repo.path
                                }
                        }

                        Button {
                            scanRepo(repo)
                        } label: {
                            if scanningRepoPaths.contains(repo.path) {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .help("Rescan repo for skills")
                        .disabled(scanningRepoPaths.contains(repo.path))
                    }
                    .badge(repoSkillCount(repo))
                    .tag(SidebarFilter.repo(repo.path))
                    .contextMenu {
                        Button("Remove Repo", role: .destructive) {
                            removeRepo(repo)
                        }
                    }
                }

                Button {
                    showingAddRepo = true
                } label: {
                    Label("Add Repo...", systemImage: "plus")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }

            if !servers.isEmpty {
                Section("Servers") {
                    ForEach(servers) { server in
                        HStack {
                            Label {
                                Text(server.label)
                            } icon: {
                                Image(systemName: "server.rack")
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if let error = serverErrors[server.id] {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                                    .popover(isPresented: Binding(
                                        get: { showingErrorForServer == server.id },
                                        set: { if !$0 { showingErrorForServer = nil } }
                                    )) {
                                        Text(error)
                                            .font(.caption)
                                            .padding()
                                            .frame(maxWidth: 250)
                                    }
                                    .onTapGesture {
                                        showingErrorForServer = server.id
                                    }
                            }

                            Button {
                                syncServer(server)
                            } label: {
                                if syncingServerIDs.contains(server.id) {
                                    ProgressView()
                                        .controlSize(.small)
                                } else {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                            .help("Sync skills from server")
                            .disabled(syncingServerIDs.contains(server.id))
                        }
                        .badge(server.skills.count)
                        .tag(SidebarFilter.server(server.id))
                    }
                }
            }

            Section("Collections") {
                CollectionListView()
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Chops")
        .sheet(isPresented: $showingAddRepo) {
            AddRepoSheet()
        }
    }

    private func syncServer(_ server: RemoteServer) {
        syncingServerIDs.insert(server.id)
        serverErrors.removeValue(forKey: server.id)
        let context = modelContext
        Task {
            let scanner = SkillScanner(modelContext: context)
            await scanner.scanRemoteServer(server)
            syncingServerIDs.remove(server.id)
            if let error = server.lastSyncError {
                serverErrors[server.id] = error
            }
        }
    }

    private func scanRepo(_ repo: WatchedRepo) {
        scanningRepoPaths.insert(repo.path)
        repoErrors.removeValue(forKey: repo.path)
        let context = modelContext
        Task {
            let scanner = SkillScanner(modelContext: context)
            await scanner.scanRepo(repo)
            scanningRepoPaths.remove(repo.path)
            if let error = repo.lastScanError {
                repoErrors[repo.path] = error
            }
        }
    }

    private func removeRepo(_ repo: WatchedRepo) {
        let path = repo.path
        if appState.sidebarFilter == .repo(path) {
            appState.sidebarFilter = .allSkills
        }
        if let skills = try? modelContext.fetch(FetchDescriptor<Skill>()) {
            for skill in skills where skill.filePath.hasPrefix(path) {
                modelContext.delete(skill)
            }
        }
        modelContext.delete(repo)
        try? modelContext.save()
    }
}

private struct AddRepoSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var path = ""
    @State private var label = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Add Repository")
                .font(.headline)

            Form {
                TextField("Label", text: $label, prompt: Text("my-project"))

                HStack {
                    TextField("Path", text: $path, prompt: Text("/Users/you/dev/my-project"))
                        .fontDesign(.monospaced)
                        .truncationMode(.middle)
                    Button("Choose...") {
                        pickDirectory()
                    }
                }
            }
            .formStyle(.grouped)

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Add Repo") {
                    addRepo()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(path.isEmpty || label.isEmpty)
            }
        }
        .padding()
        .frame(width: 440)
    }

    private func pickDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.showsHiddenFiles = false
        panel.prompt = "Select Repo"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        path = url.path
        if label.isEmpty {
            label = url.lastPathComponent
        }
    }

    private func addRepo() {
        let repo = WatchedRepo(path: path, label: label)
        modelContext.insert(repo)
        try? modelContext.save()
        Task {
            let scanner = SkillScanner(modelContext: modelContext)
            await scanner.scanRepo(repo)
        }
    }
}
