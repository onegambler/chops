import SwiftUI
import SwiftData

struct SkillListView: View {
    private enum ActiveAlert: Identifiable {
        case confirmDelete(Skill)
        case confirmMakeGlobal(Skill)
        case deleteError(String)
        case makeGlobalError(String)
        case sourceActionSummary(String)

        var id: String {
            switch self {
            case .confirmDelete(let skill):
                return "confirm-delete-\(skill.filePath)"
            case .confirmMakeGlobal(let skill):
                return "confirm-make-global-\(skill.filePath)"
            case .deleteError(let message):
                return "delete-error-\(message)"
            case .makeGlobalError(let message):
                return "make-global-error-\(message)"
            case .sourceActionSummary(let message):
                return "source-action-summary-\(message)"
            }
        }
    }

    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query(sort: \Skill.name) private var allSkills: [Skill]
    @Query(sort: \SkillCollection.name) private var allCollections: [SkillCollection]
    @State private var sourceStore = SourceStore.shared
    @State private var activeAlert: ActiveAlert?
    @State private var installSheetSkills: [Skill] = []
    @State private var showingInstallSheet = false

    private var filteredSkills: [Skill] {
        var result = allSkills

        switch appState.sidebarFilter {
        case .allSkills:
            result = result.filter { $0.itemKind == .skill && sourceStore.isSourceSkill($0) }
        case .allAgents:
            result = result.filter { $0.itemKind == .agent }
        case .allRules:
            result = result.filter { $0.itemKind == .rule }
        case .favorites:
            result = result.filter { $0.isFavorite }
        case .source(let sourceID):
            result = result.filter {
                $0.itemKind == .skill && sourceStore.match(for: $0)?.source.id == sourceID
            }
        case .tool(let tool):
            result = result.filter { $0.toolSources.contains(tool) }
            if let kind = appState.toolKindFilter {
                result = result.filter { $0.itemKind == kind }
            }
        case .collection(let collName):
            result = result.filter { skill in
                skill.collections.contains { $0.name == collName }
            }
        case .server(let serverID):
            result = result.filter { $0.remoteServer?.id == serverID }
        }

        if !appState.searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(appState.searchText) ||
                $0.skillDescription.localizedCaseInsensitiveContains(appState.searchText) ||
                $0.content.localizedCaseInsensitiveContains(appState.searchText)
            }
        }

        return result
    }

    private var title: String {
        switch appState.sidebarFilter {
        case .allSkills: "Skills"
        case .allAgents: "Agents"
        case .allRules: "Rules"
        case .favorites: "Favorites"
        case .source(let sourceID):
            sourceStore.sources.first(where: { $0.id == sourceID })?.displayName ?? "Skills"
        case .tool(let tool): tool.displayName
        case .collection(let name): name
        case .server(let id):
            allSkills.first(where: { $0.remoteServer?.id == id })?.remoteServer?.label ?? "Remote"
        }
    }

    /// Whether the current filter shows mixed item types (skills and agents together)
    private var showsTypeBadge: Bool {
        switch appState.sidebarFilter {
        case .allSkills, .allAgents, .allRules, .source: false
        case .tool: appState.toolKindFilter == nil
        default: true
        }
    }

    private var availableKinds: [ItemKind] {
        guard case .tool(let tool) = appState.sidebarFilter else { return [] }
        let kinds = Set(allSkills.filter { $0.toolSources.contains(tool) }.map(\.itemKind))
        return ItemKind.allCases.filter { kinds.contains($0) }
    }

    private var visibleSourceSkills: [Skill] {
        filteredSkills.filter { sourceStore.isSourceSkill($0) }
    }

    private var selectedSourceSkills: [Skill] {
        visibleSourceSkills.filter { appState.selectedSkillIDs.contains(selectionID(for: $0)) }
    }

    private var showsSourceActions: Bool {
        !visibleSourceSkills.isEmpty
    }

    private func selectionID(for skill: Skill) -> String {
        skill.resolvedPath
    }

    @ViewBuilder
    private var emptyStateView: some View {
        if let kind = appState.toolKindFilter {
            ContentUnavailableView(
                "No \(kind.displayName)",
                systemImage: kind.icon,
                description: Text("No \(kind.displayName.lowercased()) match the current filter.")
            )
        } else {
            switch appState.sidebarFilter {
            case .allAgents:
                ContentUnavailableView("No Agents", systemImage: "person.crop.rectangle",
                    description: Text("No agents match the current filter."))
            case .allRules:
                ContentUnavailableView("No Rules", systemImage: "list.bullet.rectangle",
                    description: Text("No rules match the current filter."))
            default:
                ContentUnavailableView("No Skills", systemImage: "doc.text",
                    description: Text("No skills match the current filter."))
            }
        }
    }

    @ViewBuilder
    private func contextMenu(for skill: Skill) -> some View {
        let selectedSkills = filteredSkills.filter { appState.selectedSkillIDs.contains(selectionID(for: $0)) }
        let contextSkills = selectedSkills.count > 1 ? selectedSkills : [skill]
        let isMultiSelection = contextSkills.count > 1

        if contextSkills.count == 1 {
            Button(skill.isFavorite ? "Unfavorite" : "Favorite") {
                skill.isFavorite.toggle()
                try? modelContext.save()
            }
        }

        let allSourceSkills = contextSkills.allSatisfy { sourceStore.isSourceSkill($0) }
        if allSourceSkills {
            Button(isMultiSelection ? "Install \(contextSkills.count) Skills..." : "Install...") {
                installSheetSkills = contextSkills
                showingInstallSheet = true
            }
            let anyInstalled = contextSkills.contains { !SourceInstallService.installedTargetIDs(for: $0).isEmpty }
            if anyInstalled {
                Button(isMultiSelection ? "Uninstall \(contextSkills.count) Skills" : "Uninstall Managed Installs") {
                    let summary = SourceInstallService.uninstall(skills: contextSkills)
                    activeAlert = .sourceActionSummary(summary.displayText)
                }
            }
            Divider()
        }
        if contextSkills.count == 1 {
            if skill.canMakeGlobal {
                Button("Make Global") {
                    activeAlert = .confirmMakeGlobal(skill)
                }
            }
            if !allCollections.isEmpty {
                Menu("Collections") {
                    ForEach(allCollections) { collection in
                        let isAssigned = skill.collections.contains(where: { $0.name == collection.name })
                        Button {
                            if isAssigned {
                                skill.collections.removeAll { $0.name == collection.name }
                            } else {
                                skill.collections.append(collection)
                            }
                            try? modelContext.save()
                        } label: {
                            Toggle(isOn: .constant(isAssigned)) {
                                Label(collection.name, systemImage: collection.icon)
                            }
                        }
                    }
                }
            }
            if !skill.isRemote {
                Divider()
                Button("Show in Finder") {
                    NSWorkspace.shared.selectFile(skill.filePath, inFileViewerRootedAtPath: "")
                }
            }
            if !skill.isReadOnly {
                Divider()
                Button("Delete", role: .destructive) {
                    activeAlert = .confirmDelete(skill)
                }
            }
        }
    }

    private func makeSkillGlobal(_ skill: Skill) {
        do {
            try skill.makeGlobal()
            try? modelContext.save()
        } catch {
            activeAlert = .makeGlobalError(error.localizedDescription)
        }
    }

    private func deleteSkill(_ skill: Skill) {
        guard !skill.isReadOnly else { return }
        do {
            try skill.deleteFromDisk()
            if appState.selectedSkill == skill {
                appState.selectedSkill = nil
            }
            appState.selectedSkillIDs.remove(selectionID(for: skill))
            modelContext.delete(skill)
            try modelContext.save()
        } catch {
            activeAlert = .deleteError(error.localizedDescription)
        }
    }

    private func install(_ skills: [Skill]) {
        installSheetSkills = skills
        showingInstallSheet = true
    }

    private func uninstall(_ skills: [Skill]) {
        let summary = SourceInstallService.uninstall(skills: skills)
        activeAlert = .sourceActionSummary(summary.displayText)
    }

    private func syncPrimarySelection() {
        guard !appState.selectedSkillIDs.isEmpty else {
            appState.selectedSkill = nil
            return
        }

        if let selected = appState.selectedSkill,
           filteredSkills.contains(selected),
           appState.selectedSkillIDs.contains(selectionID(for: selected)) {
            return
        }

        appState.selectedSkill = filteredSkills.first {
            appState.selectedSkillIDs.contains(selectionID(for: $0))
        }
    }

    var body: some View {
        @Bindable var appState = appState

        List(selection: $appState.selectedSkillIDs) {
            ForEach(filteredSkills) { skill in
                SkillRow(skill: skill, showTypeBadge: showsTypeBadge)
                    .tag(selectionID(for: skill))
                    .draggable(skill.resolvedPath)
                    .contextMenu { contextMenu(for: skill) }
            }
        }
        .navigationTitle(title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 4) {
                    if case .tool = appState.sidebarFilter, availableKinds.count > 1 {
                        Menu {
                            Button {
                                appState.toolKindFilter = nil
                            } label: {
                                if appState.toolKindFilter == nil {
                                    Label("All", systemImage: "checkmark")
                                } else {
                                    Text("All")
                                }
                            }
                            Divider()
                            ForEach(availableKinds, id: \.self) { kind in
                                Button {
                                    appState.toolKindFilter = kind
                                } label: {
                                    if appState.toolKindFilter == kind {
                                        Label(kind.displayName, systemImage: "checkmark")
                                    } else {
                                        Text(kind.displayName)
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: appState.toolKindFilter != nil ? "ellipsis.circle.fill" : "ellipsis.circle")
                        }
                    }
                    if showsSourceActions {
                        Menu {
                            Button {
                                install(selectedSourceSkills)
                            } label: {
                                Label("Install Selected", systemImage: "square.and.arrow.down")
                            }
                            .disabled(selectedSourceSkills.isEmpty)

                            Button {
                                uninstall(selectedSourceSkills)
                            } label: {
                                Label("Uninstall Selected", systemImage: "trash")
                            }
                            .disabled(selectedSourceSkills.isEmpty)

                            Divider()

                            Button {
                                install(visibleSourceSkills)
                            } label: {
                                Label("Install All", systemImage: "square.and.arrow.down")
                            }

                            Button {
                                uninstall(visibleSourceSkills)
                            } label: {
                                Label("Uninstall All", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                    Menu {
                        Button {
                            appState.newItemKind = .skill
                            appState.showingNewSkillSheet = true
                        } label: {
                            Label("New Skill", systemImage: "doc.text")
                        }
                        Button {
                            appState.newItemKind = .agent
                            appState.showingNewSkillSheet = true
                        } label: {
                            Label("New Agent", systemImage: "person.crop.rectangle")
                        }
                        Button {
                            appState.newItemKind = .rule
                            appState.showingNewSkillSheet = true
                        } label: {
                            Label("New Rule", systemImage: "list.bullet.rectangle")
                        }
                        Divider()
                        Button {
                            appState.showingRegistrySheet = true
                        } label: {
                            Label("Browse Registry", systemImage: "globe")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .menuIndicator(.hidden)
                }
            }
        }
        .alert(item: $activeAlert) { alert in
            switch alert {
            case .confirmMakeGlobal(let skill):
                return Alert(
                    title: Text("Make \"\(skill.name)\" Global?"),
                    message: Text("This will move the skill to ~/.agents/skills/ and symlink it to all installed agents."),
                    primaryButton: .default(Text("Make Global")) {
                        makeSkillGlobal(skill)
                    },
                    secondaryButton: .cancel()
                )
            case .confirmDelete(let skill):
                return Alert(
                    title: Text("Delete \(skill.displayTypeName)?"),
                    message: Text("This will permanently delete \"\(skill.name)\" from disk."),
                    primaryButton: .destructive(Text("Delete")) {
                        deleteSkill(skill)
                    },
                    secondaryButton: .cancel()
                )
            case .deleteError(let message):
                return Alert(
                    title: Text("Delete Failed"),
                    message: Text(message),
                    dismissButton: .default(Text("OK"))
                )
            case .makeGlobalError(let message):
                return Alert(
                    title: Text("Make Global Failed"),
                    message: Text(message),
                    dismissButton: .default(Text("OK"))
                )
            case .sourceActionSummary(let message):
                return Alert(
                    title: Text("Source Action"),
                    message: Text(message.isEmpty ? "No changes." : message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .sheet(isPresented: $showingInstallSheet) {
            InstallTargetsSheet(skills: installSheetSkills) { summary in
                activeAlert = .sourceActionSummary(summary.displayText)
            }
        }
        .overlay {
            if filteredSkills.isEmpty { emptyStateView }
        }
        .onChange(of: appState.sidebarFilter) {
            if let selected = appState.selectedSkill, filteredSkills.contains(selected) {
                appState.selectedSkillIDs = [selectionID(for: selected)]
            } else {
                appState.selectedSkill = filteredSkills.first
                if let selected = appState.selectedSkill {
                    appState.selectedSkillIDs = [selectionID(for: selected)]
                } else {
                    appState.selectedSkillIDs = []
                }
            }
        }
        .onChange(of: appState.selectedSkillIDs) {
            syncPrimarySelection()
        }
        .onAppear {
            if let selected = appState.selectedSkill {
                appState.selectedSkillIDs = [selectionID(for: selected)]
            } else if let first = filteredSkills.first {
                appState.selectedSkill = first
                appState.selectedSkillIDs = [selectionID(for: first)]
            }
        }
    }
}

struct SkillRow: View {
    let skill: Skill
    var showTypeBadge: Bool = false
    @State private var sourceStore = SourceStore.shared

    var body: some View {
        HStack(spacing: 6) {
            if showTypeBadge {
                let kindIcon: String = switch skill.itemKind {
                case .agent: "person.crop.rectangle"
                case .rule: "list.bullet.rectangle"
                case .skill: "doc.text"
                }
                Image(systemName: kindIcon)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Text(skill.name)
                .lineLimit(1)

            if skill.isFavorite {
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundStyle(.yellow)
            }

            Spacer()

            if skill.isRemote, let serverLabel = skill.remoteServer?.label {
                Text(serverLabel)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            } else if let project = skill.projectName {
                Text(project)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }

            HStack(spacing: 3) {
                ForEach(skill.toolSources, id: \.self) { tool in
                    ToolIcon(tool: tool, size: 14)
                        .help(tool.displayName)
                        .opacity(0.6)
                }
            }

            if let match = sourceStore.match(for: skill) {
                Text(match.source.displayName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .help("Source: \(match.source.displayName)")
            }

            let installedTargetIDs = SourceInstallService.installedTargetIDs(for: skill)
            if !installedTargetIDs.isEmpty {
                Text("\(installedTargetIDs.count)")
                    .font(.caption2)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(Color.accentColor)
                    .clipShape(Capsule())
                    .help("Installed to \(installedTargetIDs.count) target\(installedTargetIDs.count == 1 ? "" : "s")")
            }
        }
        .padding(.vertical, 4)
    }
}
