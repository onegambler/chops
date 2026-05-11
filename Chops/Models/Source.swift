import Foundation

enum SourceKind: String, Codable, CaseIterable, Identifiable {
    case local
    case git

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .local: "Local Folder"
        case .git: "Git Repo"
        }
    }

    var iconName: String {
        switch self {
        case .local: "folder"
        case .git: "arrow.triangle.branch"
        }
    }
}

struct Source: Identifiable, Codable, Hashable {
    var id: String
    var displayName: String
    var kind: SourceKind
    var path: String
    var url: String?
    var clonePath: String?
    var branch: String
    var createdAt: Date
    var lastScannedAt: Date?
    var lastSyncedAt: Date?
    var lastError: String?

    var scanRootPath: String {
        switch kind {
        case .local:
            return (path as NSString).expandingTildeInPath
        case .git:
            return ((clonePath ?? path) as NSString).expandingTildeInPath
        }
    }

    var displayPath: String {
        if kind == .git, let url {
            return url
        }
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return scanRootPath.hasPrefix(home) ? "~" + scanRootPath.dropFirst(home.count) : scanRootPath
    }
}

struct SourceInstall: Identifiable, Codable, Hashable {
    var id: String
    var sourceID: String
    var sourceSkillRelativePath: String
    var sourceSkillAbsolutePath: String
    var targetID: String
    var targetDisplayName: String
    var installedPath: String
    var symlinkTarget: String
    var installedAt: Date
}

struct SourceSkillMatch: Hashable {
    let source: Source
    let skillDirectoryPath: String
    let skillFilePath: String
    let relativeSkillPath: String

    var installName: String {
        let folder = URL(fileURLWithPath: skillDirectoryPath).lastPathComponent
        let cleaned = folder
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .filter { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "." || $0 == "_" }
            .trimmingCharacters(in: CharacterSet(charactersIn: ".-"))
        return cleaned.isEmpty ? "skill" : cleaned
    }
}
