import Foundation

struct SourceInstallSummary {
    var installed: [String] = []
    var uninstalled: [String] = []
    var skipped: [String] = []
    var failed: [String] = []

    var hasMessages: Bool {
        !installed.isEmpty || !uninstalled.isEmpty || !skipped.isEmpty || !failed.isEmpty
    }

    var displayText: String {
        var lines: [String] = []
        if !installed.isEmpty { lines.append("Installed: \(installed.count)") }
        if !uninstalled.isEmpty { lines.append("Uninstalled: \(uninstalled.count)") }
        if !skipped.isEmpty { lines.append("Skipped: \(skipped.count)") }
        if !failed.isEmpty { lines.append("Failed: \(failed.count)") }
        lines.append(contentsOf: (skipped + failed).prefix(8))
        return lines.joined(separator: "\n")
    }
}

enum SourceInstallError: LocalizedError {
    case notSourceSkill(String)
    case unmanagedConflict(String)
    case unsafeUninstall(String)

    var errorDescription: String? {
        switch self {
        case .notSourceSkill(let name):
            return "\(name) is not from a configured source."
        case .unmanagedConflict(let path):
            return "Target already exists and is not a Chops-managed symlink: \(path)"
        case .unsafeUninstall(let path):
            return "Refusing to remove path that is not the expected Chops-managed symlink: \(path)"
        }
    }
}

@MainActor
enum SourceInstallService {
    static func install(skills: [Skill], targets: [AgentTarget]) -> SourceInstallSummary {
        let store = SourceStore.shared
        var summary = SourceInstallSummary()
        for skill in skills {
            guard let match = store.match(for: skill) else {
                summary.failed.append(SourceInstallError.notSourceSkill(skill.name).localizedDescription)
                continue
            }
            for target in targets {
                do {
                    let path = try install(match: match, target: target)
                    summary.installed.append("\(skill.name) -> \(target.displayName): \(path)")
                } catch {
                    summary.failed.append("\(skill.name) -> \(target.displayName): \(error.localizedDescription)")
                }
            }
        }
        NotificationCenter.default.post(name: .customScanPathsChanged, object: nil)
        return summary
    }

    static func uninstall(skills: [Skill], targetIDs: Set<String>? = nil) -> SourceInstallSummary {
        let store = SourceStore.shared
        var summary = SourceInstallSummary()
        for skill in skills {
            guard let match = store.match(for: skill) else {
                summary.skipped.append("\(skill.name): not a Source skill")
                continue
            }
            let installs = store.installs(for: match).filter { install in
                targetIDs?.contains(install.targetID) ?? true
            }
            if installs.isEmpty {
                summary.skipped.append("\(skill.name): no managed installs")
                continue
            }
            for install in installs {
                do {
                    try uninstall(install: install)
                    summary.uninstalled.append("\(skill.name) <- \(install.targetDisplayName)")
                } catch {
                    summary.failed.append("\(skill.name) <- \(install.targetDisplayName): \(error.localizedDescription)")
                }
            }
        }
        NotificationCenter.default.post(name: .customScanPathsChanged, object: nil)
        return summary
    }

    static func installedTargetIDs(for skill: Skill) -> Set<String> {
        guard let match = SourceStore.shared.match(for: skill) else { return [] }
        return Set(SourceStore.shared.installs(for: match).map(\.targetID))
    }

    private static func install(match: SourceSkillMatch, target: AgentTarget) throws -> String {
        let fm = FileManager.default
        let installName = match.installName
        let targetPath = "\(target.expandedSkillsDir)/\(installName)"
        let sourceDir = URL(fileURLWithPath: match.skillDirectoryPath).resolvingSymlinksInPath().path

        if fm.fileExists(atPath: targetPath) || isSymlink(targetPath) {
            if symlinkTarget(targetPath) == sourceDir {
                try recordInstall(match: match, target: target, targetPath: targetPath, sourceDir: sourceDir)
                return targetPath
            }
            throw SourceInstallError.unmanagedConflict(targetPath)
        }

        try fm.createDirectory(atPath: target.expandedSkillsDir, withIntermediateDirectories: true)
        try fm.createSymbolicLink(atPath: targetPath, withDestinationPath: sourceDir)
        try recordInstall(match: match, target: target, targetPath: targetPath, sourceDir: sourceDir)
        return targetPath
    }

    private static func uninstall(install: SourceInstall) throws {
        let fm = FileManager.default
        let installed = install.installedPath
        let expected = URL(fileURLWithPath: install.symlinkTarget).resolvingSymlinksInPath().path

        if !fm.fileExists(atPath: installed) && !isSymlink(installed) {
            try SourceStore.shared.removeInstall(id: install.id)
            return
        }

        guard isSymlink(installed), symlinkTarget(installed) == expected else {
            throw SourceInstallError.unsafeUninstall(installed)
        }

        try fm.removeItem(atPath: installed)
        try SourceStore.shared.removeInstall(id: install.id)
    }

    private static func recordInstall(match: SourceSkillMatch, target: AgentTarget, targetPath: String, sourceDir: String) throws {
        let install = SourceInstall(
            id: "\(match.source.id)::\(match.relativeSkillPath)::\(target.id)",
            sourceID: match.source.id,
            sourceSkillRelativePath: match.relativeSkillPath,
            sourceSkillAbsolutePath: match.skillDirectoryPath,
            targetID: target.id,
            targetDisplayName: target.displayName,
            installedPath: targetPath,
            symlinkTarget: sourceDir,
            installedAt: .now
        )
        try SourceStore.shared.replaceInstall(install)
    }

    private static func isSymlink(_ path: String) -> Bool {
        ((try? FileManager.default.attributesOfItem(atPath: path)[.type] as? FileAttributeType) == .typeSymbolicLink)
    }

    private static func symlinkTarget(_ path: String) -> String? {
        guard let destination = try? FileManager.default.destinationOfSymbolicLink(atPath: path) else {
            return nil
        }
        let absolute: String
        if destination.hasPrefix("/") {
            absolute = destination
        } else {
            absolute = URL(fileURLWithPath: path).deletingLastPathComponent().appendingPathComponent(destination).path
        }
        return URL(fileURLWithPath: absolute).resolvingSymlinksInPath().path
    }
}
