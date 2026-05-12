import Foundation
import Observation

@Observable
@MainActor
final class SourceStore {
    static let shared = SourceStore()

    private(set) var sources: [Source] = []
    private(set) var installs: [SourceInstall] = []

    private init() {
        do {
            try Self.ensureStorage()
            sources = try Self.loadSourcesSnapshot(migratingLegacyPaths: true)
            installs = try Self.loadInstallsSnapshot()
        } catch {
            AppLogger.settings.error("SourceStore load failed: \(error.localizedDescription)")
            sources = []
            installs = []
        }
    }

    func reload() {
        do {
            sources = try Self.loadSourcesSnapshot(migratingLegacyPaths: true)
            installs = try Self.loadInstallsSnapshot()
        } catch {
            AppLogger.settings.error("SourceStore reload failed: \(error.localizedDescription)")
        }
    }

    func addLocalSource(path: String, displayName: String? = nil) throws {
        let expanded = (path as NSString).expandingTildeInPath
        let id = uniqueID(base: Self.slug(for: URL(fileURLWithPath: expanded).lastPathComponent))
        let name = displayName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let source = Source(
            id: id,
            displayName: (name?.isEmpty == false ? name : nil) ?? URL(fileURLWithPath: expanded).lastPathComponent,
            kind: .local,
            path: expanded,
            branch: "",
            createdAt: .now
        )
        sources.append(source)
        try saveSources()
    }

    func addGitSource(url: String, branch: String = "") async throws {
        let normalizedURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedURL.isEmpty else { throw SourceStoreError.invalidURL }

        let repoName = Self.repoName(from: normalizedURL)
        let id = uniqueID(base: Self.slug(for: repoName))
        let clonePath = try Self.sourcesDirectory().appendingPathComponent(id).appendingPathComponent("repo").path
        var source = Source(
            id: id,
            displayName: repoName,
            kind: .git,
            path: clonePath,
            url: normalizedURL,
            clonePath: clonePath,
            branch: branch.trimmingCharacters(in: .whitespacesAndNewlines),
            createdAt: .now
        )

        do {
            try await SourceGitService.cloneOrSync(source)
            source.lastSyncedAt = .now
            source.lastError = nil
        } catch {
            throw error
        }

        sources.append(source)
        try saveSources()
    }

    func sync(_ source: Source) async {
        guard let index = sources.firstIndex(where: { $0.id == source.id }) else { return }
        do {
            try await SourceGitService.cloneOrSync(sources[index])
            sources[index].lastSyncedAt = .now
            sources[index].lastError = nil
        } catch {
            sources[index].lastError = error.localizedDescription
        }
        try? saveSources()
    }

    func markScanned(_ sourceID: String, error: String? = nil) {
        guard let index = sources.firstIndex(where: { $0.id == sourceID }) else { return }
        sources[index].lastScannedAt = .now
        sources[index].lastError = error
        try? saveSources()
    }

    func remove(_ source: Source, removeFiles: Bool = false) throws {
        if installs.contains(where: { $0.sourceID == source.id }) {
            throw SourceStoreError.installedSkillsRemain
        }
        sources.removeAll { $0.id == source.id }
        try saveSources()
        if removeFiles, source.kind == .git, let clonePath = source.clonePath {
            try? FileManager.default.removeItem(atPath: (clonePath as NSString).expandingTildeInPath)
        }
    }

    func replaceInstall(_ install: SourceInstall) throws {
        installs.removeAll {
            $0.sourceID == install.sourceID &&
            $0.sourceSkillRelativePath == install.sourceSkillRelativePath &&
            $0.targetID == install.targetID
        }
        installs.append(install)
        try saveInstalls()
    }

    func removeInstall(id: String) throws {
        installs.removeAll { $0.id == id }
        try saveInstalls()
    }

    func installs(for match: SourceSkillMatch) -> [SourceInstall] {
        installs.filter {
            $0.sourceID == match.source.id &&
            $0.sourceSkillRelativePath == match.relativeSkillPath
        }
    }

    func match(for skill: Skill) -> SourceSkillMatch? {
        Self.match(for: skill, sources: sources)
    }

    func isSourceSkill(_ skill: Skill) -> Bool {
        match(for: skill) != nil
    }

    nonisolated static func isSourceSkillSync(_ skill: Skill) -> Bool {
        let sources = (try? loadSourcesSnapshot(migratingLegacyPaths: true)) ?? []
        return match(for: skill, sources: sources) != nil
    }

    nonisolated static func matchSync(for skill: Skill) -> SourceSkillMatch? {
        let sources = (try? loadSourcesSnapshot(migratingLegacyPaths: true)) ?? []
        return match(for: skill, sources: sources)
    }

    nonisolated static func sourceRootsSnapshot() -> [String] {
        ((try? loadSourcesSnapshot(migratingLegacyPaths: true)) ?? []).map(\.scanRootPath)
    }

    nonisolated static func writableSourcesSnapshot() -> [Source] {
        ((try? loadSourcesSnapshot(migratingLegacyPaths: true)) ?? []).filter(\.isWritable)
    }

    nonisolated static func loadSourcesSnapshot(migratingLegacyPaths: Bool = false) throws -> [Source] {
        try ensureStorage()
        let url = try sourcesJSONURL()
        var decoded: [Source] = []
        if FileManager.default.fileExists(atPath: url.path) {
            let data = try Data(contentsOf: url)
            decoded = try JSONDecoder.sourceDecoder.decode([Source].self, from: data)
        }
        if migratingLegacyPaths {
            let legacyPaths = UserDefaults.standard.stringArray(forKey: "customScanPaths") ?? []
            var changed = false
            for path in legacyPaths {
                let expanded = (path as NSString).expandingTildeInPath
                guard !decoded.contains(where: { $0.kind == .local && $0.scanRootPath == expanded }) else { continue }
                let base = slug(for: URL(fileURLWithPath: expanded).lastPathComponent)
                let id = uniqueID(base: base, existing: Set(decoded.map(\.id)))
                decoded.append(Source(
                    id: id,
                    displayName: URL(fileURLWithPath: expanded).lastPathComponent,
                    kind: .local,
                    path: expanded,
                    branch: "",
                    createdAt: .now
                ))
                changed = true
            }
            if changed {
                let data = try JSONEncoder.sourceEncoder.encode(decoded)
                try data.write(to: url, options: .atomic)
            }
        }
        return decoded
    }

    nonisolated static func loadInstallsSnapshot() throws -> [SourceInstall] {
        try ensureStorage()
        let url = try installsJSONURL()
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        let data = try Data(contentsOf: url)
        return try JSONDecoder.sourceDecoder.decode([SourceInstall].self, from: data)
    }

    nonisolated static func match(for skill: Skill, sources: [Source]) -> SourceSkillMatch? {
        let paths = ([skill.filePath] + skill.installedPaths).flatMap { path -> [String] in
            let expanded = (path as NSString).expandingTildeInPath
            let resolved = URL(fileURLWithPath: expanded).resolvingSymlinksInPath().path
            return expanded == resolved ? [expanded] : [expanded, resolved]
        }

        for source in sources {
            let root = URL(fileURLWithPath: source.scanRootPath).standardizedFileURL.path
            for path in paths {
                let standardized = URL(fileURLWithPath: path).standardizedFileURL.path
                guard pathIsInside(standardized, root: root) else { continue }
                let filePath = standardized.hasSuffix("/SKILL.md") ? standardized : "\(standardized)/SKILL.md"
                let skillDir = standardized.hasSuffix("/SKILL.md")
                    ? URL(fileURLWithPath: standardized).deletingLastPathComponent().path
                    : standardized
                let relative = relativePath(skillDir, root: root)
                return SourceSkillMatch(
                    source: source,
                    skillDirectoryPath: skillDir,
                    skillFilePath: filePath,
                    relativeSkillPath: relative
                )
            }
        }
        return nil
    }

    nonisolated static func appSupportDirectory() throws -> URL {
        guard let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw CocoaError(.fileNoSuchFile)
        }
        return base.appendingPathComponent("Chops", isDirectory: true)
    }

    nonisolated static func sourcesDirectory() throws -> URL {
        try appSupportDirectory().appendingPathComponent("Sources", isDirectory: true)
    }

    private func saveSources() throws {
        try Self.saveSourcesSnapshot(sources)
    }

    private func saveInstalls() throws {
        try Self.saveInstallsSnapshot(installs)
    }

    nonisolated static func saveSourcesSnapshot(_ sources: [Source]) throws {
        try ensureStorage()
        let data = try JSONEncoder.sourceEncoder.encode(sources)
        try data.write(to: try sourcesJSONURL(), options: .atomic)
    }

    nonisolated static func saveInstallsSnapshot(_ installs: [SourceInstall]) throws {
        try ensureStorage()
        let data = try JSONEncoder.sourceEncoder.encode(installs)
        try data.write(to: try installsJSONURL(), options: .atomic)
    }

    nonisolated static func ensureStorage() throws {
        try FileManager.default.createDirectory(at: try sourcesDirectory(), withIntermediateDirectories: true)
    }

    nonisolated static func sourcesJSONURL() throws -> URL {
        try sourcesDirectory().appendingPathComponent("sources.json")
    }

    nonisolated static func installsJSONURL() throws -> URL {
        try sourcesDirectory().appendingPathComponent("installs.json")
    }

    private func uniqueID(base: String) -> String {
        Self.uniqueID(base: base, existing: Set(sources.map(\.id)))
    }

    nonisolated private static func uniqueID(base: String, existing: Set<String>) -> String {
        var candidate = base.isEmpty ? "source" : base
        var index = 2
        while existing.contains(candidate) {
            candidate = "\(base)-\(index)"
            index += 1
        }
        return candidate
    }

    nonisolated static func slug(for value: String) -> String {
        let cleaned = value
            .lowercased()
            .replacingOccurrences(of: ".git", with: "")
            .replacingOccurrences(of: " ", with: "-")
            .filter { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" || $0 == "." }
            .trimmingCharacters(in: CharacterSet(charactersIn: ".-_"))
        return cleaned.isEmpty ? "source" : cleaned
    }

    nonisolated static func repoName(from url: String) -> String {
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        let withoutGit = trimmed.hasSuffix(".git") ? String(trimmed.dropLast(4)) : trimmed
        if let last = withoutGit.split(separator: "/").last {
            return String(last)
        }
        if let last = withoutGit.split(separator: ":").last {
            return String(last)
        }
        return "Git Source"
    }

    nonisolated static func pathIsInside(_ path: String, root: String) -> Bool {
        path == root || path.hasPrefix(root + "/")
    }

    nonisolated static func relativePath(_ path: String, root: String) -> String {
        guard path.hasPrefix(root + "/") else { return URL(fileURLWithPath: path).lastPathComponent }
        return String(path.dropFirst(root.count + 1))
    }
}

enum SourceStoreError: LocalizedError {
    case invalidURL
    case installedSkillsRemain

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Enter a GitHub HTTPS or SSH URL."
        case .installedSkillsRemain:
            return "Uninstall this source's managed skills before removing it."
        }
    }
}

private extension JSONEncoder {
    static var sourceEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private extension JSONDecoder {
    static var sourceDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
