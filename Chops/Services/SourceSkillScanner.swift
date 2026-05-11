import Foundation

enum SourceSkillScanner {
    private static let ignoredDirectoryNames: Set<String> = [
        ".git",
        ".cache",
        ".swiftpm",
        "node_modules",
        ".build",
        "dist",
        "build",
        "__pycache__",
    ]

    static func skillDirectories(in source: Source) -> [URL] {
        skillDirectories(rootPath: source.scanRootPath)
    }

    static func skillDirectories(rootPath: String) -> [URL] {
        let root = URL(fileURLWithPath: (rootPath as NSString).expandingTildeInPath)
        let fm = FileManager.default
        guard fm.fileExists(atPath: root.path) else { return [] }
        if fm.fileExists(atPath: root.appendingPathComponent("SKILL.md").path) {
            return [root]
        }
        guard let enumerator = fm.enumerator(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsPackageDescendants]
        ) else { return [] }

        var results: [URL] = []
        for case let url as URL in enumerator {
            let name = url.lastPathComponent
            if shouldSkipDirectory(name) {
                enumerator.skipDescendants()
                continue
            }

            var isDirectory: ObjCBool = false
            guard fm.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue else {
                continue
            }
            if fm.fileExists(atPath: url.appendingPathComponent("SKILL.md").path) {
                results.append(url)
                enumerator.skipDescendants()
            }
        }
        return results.sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }
    }

    static func skillCount(in source: Source) -> Int {
        skillDirectories(in: source).count
    }

    private static func shouldSkipDirectory(_ name: String) -> Bool {
        ignoredDirectoryNames.contains(name)
    }
}
