import SwiftUI
import SwiftData

enum SkillDestination: Hashable, Identifiable {
    case tool(ToolSource)
    case source(Source)

    var id: String {
        switch self {
        case .tool(let tool): "tool-\(tool.rawValue)"
        case .source(let source): "source-\(source.id)"
        }
    }

    var displayName: String {
        switch self {
        case .tool(let tool): tool.displayName
        case .source(let source): source.displayName
        }
    }

    var iconName: String {
        switch self {
        case .tool(let tool): tool.iconName
        case .source: "folder"
        }
    }
}

struct NewSkillSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @State private var skillName = ""
    @State private var selectedDestination: SkillDestination = .tool(.agents)
    @State private var errorMessage: String?
    @State private var showingInstallSheet = false
    @State private var createdSkill: Skill?

    private var itemKind: ItemKind { appState.newItemKind }

    private var creatableTools: [ToolSource] {
        switch itemKind {
        case .skill:
            return [.agents, .amp, .antigravity, .claude, .codex, .cursor, .opencode, .pi]
        case .agent:
            return ToolSource.allCases.filter { !$0.globalAgentPaths.isEmpty }
        case .rule:
            return ToolSource.allCases.filter { !$0.globalRulePaths.isEmpty }
        }
    }

    private var writableSources: [Source] {
        SourceStore.writableSourcesSnapshot()
    }

    private var hasWritableSources: Bool {
        !writableSources.isEmpty && itemKind == .skill
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("New \(itemKind.singularName)")
                .font(.title2)
                .fontWeight(.bold)

            Form {
                TextField("\(itemKind.singularName) name", text: $skillName)
                    .textFieldStyle(.roundedBorder)

                Picker("Destination", selection: $selectedDestination) {
                    Section("Tools") {
                        ForEach(creatableTools) { tool in
                            Label(tool.displayName, systemImage: tool.iconName)
                                .tag(SkillDestination.tool(tool))
                        }
                    }
                    if hasWritableSources {
                        Section("Sources") {
                            ForEach(writableSources) { source in
                                Label(source.displayName, systemImage: "folder")
                                    .tag(SkillDestination.source(source))
                            }
                        }
                    }
                }
            }
            .formStyle(.grouped)

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Create") {
                    createItem()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(skillName.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 400)
        .onAppear {
            if !creatableTools.isEmpty {
                selectedDestination = .tool(creatableTools.first ?? .claude)
            }
        }
        .sheet(isPresented: $showingInstallSheet) {
            if let skill = createdSkill {
                InstallTargetsSheet(skills: [skill]) { _ in
                    finalizeCreation(skill: skill)
                }
            }
        }
        .onChange(of: showingInstallSheet) { _, isShowing in
            if !isShowing, let skill = createdSkill {
                finalizeCreation(skill: skill)
            }
        }
    }

    private func createItem() {
        let sanitizedName = skillName
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .filter { $0.isLetter || $0.isNumber || $0 == "-" }

        guard !sanitizedName.isEmpty else {
            errorMessage = "Invalid name"
            return
        }

        switch selectedDestination {
        case .tool(let tool):
            createItemInTool(tool, sanitizedName: sanitizedName)
        case .source(let source):
            createItemInSource(source, sanitizedName: sanitizedName)
        }
    }

    private func createItemInTool(_ tool: ToolSource, sanitizedName: String) {
        let fm = FileManager.default

        let basePath: String
        let fileName: String

        switch itemKind {
        case .agent:
            guard let dir = tool.globalAgentPaths.first else {
                errorMessage = "This tool doesn't support agents"
                return
            }
            basePath = "\(dir)/\(sanitizedName)"
            fileName = "\(sanitizedName).md"
        case .rule:
            guard let dir = tool.globalRulePaths.first else {
                errorMessage = "This tool doesn't support rules"
                return
            }
            basePath = dir
            fileName = "\(sanitizedName).md"
        case .skill:
            guard let dir = tool.globalPaths.first else {
                errorMessage = "This tool doesn't support skills"
                return
            }
            basePath = "\(dir)/\(sanitizedName)"
            fileName = "SKILL.md"
        }

        do {
            try fm.createDirectory(atPath: basePath, withIntermediateDirectories: true)

            let filePath = "\(basePath)/\(fileName)"
            var installedPaths = [filePath]
            var toolSources = [tool]

            guard !fm.fileExists(atPath: filePath) else {
                errorMessage = "A \(itemKind.singularName.lowercased()) with this name already exists"
                return
            }

            let boilerplate = generateBoilerplate(name: skillName, skillID: sanitizedName, tool: tool)
            try boilerplate.write(toFile: filePath, atomically: true, encoding: .utf8)

            if itemKind == .skill && tool == .agents {
                for agent in AgentTarget.installed {
                    let agentDir = "\(agent.expandedSkillsDir)/\(sanitizedName)"
                    guard !fm.fileExists(atPath: agentDir) else { continue }
                    try fm.createDirectory(atPath: agent.expandedSkillsDir, withIntermediateDirectories: true)
                    try fm.createSymbolicLink(atPath: agentDir, withDestinationPath: basePath)
                    installedPaths.append("\(agentDir)/SKILL.md")
                    if let toolSource = ToolSource.allCases.first(where: { $0.globalPaths.contains(agent.expandedSkillsDir) }) {
                        toolSources.append(toolSource)
                    }
                }
            }

            let parsed = FrontmatterParser.parse(boilerplate)
            let skill = Skill(
                filePath: filePath,
                toolSource: tool,
                isDirectory: itemKind != .rule,
                name: skillName,
                skillDescription: parsed.description,
                content: parsed.content,
                frontmatter: parsed.frontmatter,
                fileModifiedDate: .now,
                fileSize: boilerplate.count,
                isGlobal: true,
                resolvedPath: filePath,
                kind: itemKind
            )
            skill.installedPaths = installedPaths
            skill.toolSources = toolSources
            modelContext.insert(skill)
            try modelContext.save()

            finalizeCreation(skill: skill)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func createItemInSource(_ source: Source, sanitizedName: String) {
        let fm = FileManager.default
        let basePath = "\(source.scanRootPath)/\(sanitizedName)"
        let filePath = "\(basePath)/SKILL.md"

        guard !fm.fileExists(atPath: filePath) else {
            errorMessage = "A skill with this name already exists in \(source.displayName)"
            return
        }

        do {
            try fm.createDirectory(atPath: basePath, withIntermediateDirectories: true)

            let boilerplate = generateBoilerplate(name: skillName, skillID: sanitizedName, tool: .custom)
            try boilerplate.write(toFile: filePath, atomically: true, encoding: .utf8)

            let parsed = FrontmatterParser.parse(boilerplate)
            let skill = Skill(
                filePath: filePath,
                toolSource: .custom,
                isDirectory: true,
                name: skillName,
                skillDescription: parsed.description,
                content: parsed.content,
                frontmatter: parsed.frontmatter,
                fileModifiedDate: .now,
                fileSize: boilerplate.count,
                isGlobal: false,
                resolvedPath: filePath,
                kind: .skill
            )
            modelContext.insert(skill)
            try modelContext.save()

            createdSkill = skill
            showingInstallSheet = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func finalizeCreation(skill: Skill) {
        switch itemKind {
        case .skill: appState.sidebarFilter = .allSkills
        case .agent: appState.sidebarFilter = .allAgents
        case .rule: appState.sidebarFilter = .allRules
        }
        appState.selectedSkill = skill
        appState.selectedSkillIDs = [skill.resolvedPath]
        dismiss()
    }

    private func generateBoilerplate(name: String, skillID: String, tool: ToolSource) -> String {
        switch itemKind {
        case .agent:
            return """
            ---
            name: \(skillID)
            description: \(name)
            ---

            # \(name)

            ## Instructions

            Add your agent instructions here.
            """
        case .rule:
            return """
            # \(name)

            Add your rule content here.
            """
        case .skill:
            switch tool {
            case .claude, .cursor, .agents, .custom:
                return """
                ---
                name: \(skillID)
                description: \(name)
                ---

                # \(name)

                ## When to Use

                - Describe when this skill should be activated

                ## Instructions

                Add your skill instructions here.
                """
            default:
                return """
                ---
                name: \(skillID)
                description: \(name)
                ---

                # \(name)

                ## Instructions

                Add your skill instructions here.
                """
            }
        }
    }
}
