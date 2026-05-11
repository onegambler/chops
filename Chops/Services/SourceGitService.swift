import Foundation

enum SourceGitError: LocalizedError {
    case missingURL
    case dirtyRepository(String)
    case gitFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingURL:
            return "This source does not have a Git URL."
        case .dirtyRepository(let path):
            return "Repository has local changes. Chops will not overwrite it: \(path)"
        case .gitFailed(let message):
            return message
        }
    }
}

enum SourceGitService {
    private static let gitPath = "/usr/bin/git"

    static func cloneOrSync(_ source: Source) async throws {
        guard source.kind == .git else { return }
        guard let url = source.url, !url.isEmpty else { throw SourceGitError.missingURL }

        let clonePath = source.scanRootPath
        if FileManager.default.fileExists(atPath: "\(clonePath)/.git") {
            try await sync(source)
        } else {
            try await clone(url: url, branch: source.branch, to: clonePath)
        }
    }

    static func sync(_ source: Source) async throws {
        let repo = source.scanRootPath
        if try await isDirty(repo: repo) {
            throw SourceGitError.dirtyRepository(repo)
        }

        _ = try await run(["fetch", "--prune", "origin"], cwd: repo)
        if source.branch.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            _ = try await run(["pull", "--ff-only"], cwd: repo)
        } else {
            _ = try await run(["checkout", source.branch], cwd: repo)
            _ = try await run(["pull", "--ff-only", "origin", source.branch], cwd: repo)
        }
    }

    static func isDirty(repo: String) async throws -> Bool {
        let output = try await run(["status", "--porcelain"], cwd: repo)
        return !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private static func clone(url: String, branch: String, to path: String) async throws {
        let parent = URL(fileURLWithPath: path).deletingLastPathComponent().path
        try FileManager.default.createDirectory(atPath: parent, withIntermediateDirectories: true)

        var args = ["clone"]
        let trimmedBranch = branch.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedBranch.isEmpty {
            args += ["--branch", trimmedBranch]
        }
        args += [url, path]
        _ = try await run(args, cwd: nil)
    }

    private static func run(_ args: [String], cwd: String?) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: gitPath)
                process.arguments = args
                if let cwd {
                    process.currentDirectoryURL = URL(fileURLWithPath: cwd)
                }

                let stdout = Pipe()
                let stderr = Pipe()
                process.standardOutput = stdout
                process.standardError = stderr

                do {
                    try process.run()
                    process.waitUntilExit()
                    let outData = stdout.fileHandleForReading.readDataToEndOfFile()
                    let errData = stderr.fileHandleForReading.readDataToEndOfFile()
                    let out = String(data: outData, encoding: .utf8) ?? ""
                    let err = String(data: errData, encoding: .utf8) ?? ""

                    if process.terminationStatus == 0 {
                        continuation.resume(returning: out)
                    } else {
                        let message = err.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? out.trimmingCharacters(in: .whitespacesAndNewlines)
                            : err.trimmingCharacters(in: .whitespacesAndNewlines)
                        continuation.resume(throwing: SourceGitError.gitFailed(message.isEmpty ? "git \(args.joined(separator: " ")) failed" : message))
                    }
                } catch {
                    continuation.resume(throwing: SourceGitError.gitFailed(error.localizedDescription))
                }
            }
        }
    }
}
