import SwiftUI
import SwiftData

struct SidebarView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Skill.name) private var allSkills: [Skill]
    @Query(sort: \RemoteServer.label) private var servers: [RemoteServer]
    @State private var sourceStore = SourceStore.shared
    @State private var skillsExpanded = true
    @State private var syncingServerIDs: Set<String> = []
    @State private var serverErrors: [String: String] = [:]
    @State private var showingErrorForServer: String?

    private var activeSources: [ToolSource] {
        ToolSource.allCases.filter { tool in
            guard tool.listable else { return false }
            return allSkills.contains { $0.toolSources.contains(tool) }
        }
    }

    private func toolCount(_ tool: ToolSource) -> Int {
        allSkills.filter { $0.toolSources.contains(tool) }.count
    }

    private var sourceSkills: [Skill] {
        allSkills.filter { $0.itemKind == .skill && sourceStore.isSourceSkill($0) }
    }

    private func sourceCount(_ source: Source) -> Int {
        sourceSkills.filter { sourceStore.match(for: $0)?.source.id == source.id }.count
    }

    var body: some View {
        @Bindable var appState = appState

        List(selection: $appState.sidebarFilter) {
            Section("Library") {
                if sourceStore.sources.isEmpty {
                    Label("Skills", systemImage: "doc.text")
                        .badge(sourceSkills.count)
                        .tag(SidebarFilter.allSkills)
                } else {
                    DisclosureGroup(isExpanded: $skillsExpanded) {
                        ForEach(sourceStore.sources) { source in
                            Label {
                                Text(source.displayName)
                            } icon: {
                                Image(systemName: source.kind.iconName)
                                    .foregroundStyle(.secondary)
                            }
                            .badge(sourceCount(source))
                            .help(source.displayPath)
                            .tag(SidebarFilter.source(source.id))
                        }
                    } label: {
                        Label("Skills", systemImage: "doc.text")
                            .badge(sourceSkills.count)
                    }
                    .tag(SidebarFilter.allSkills)
                }

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
}
