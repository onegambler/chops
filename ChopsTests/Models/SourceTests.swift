import XCTest
@testable import Chops

final class SourceTests: XCTestCase {

    // MARK: - SourceKind Tests

    func testSourceKindDisplayNames() {
        XCTAssertEqual(SourceKind.local.displayName, "Local Folder")
        XCTAssertEqual(SourceKind.git.displayName, "Git Repo")
    }

    func testSourceKindIcons() {
        XCTAssertEqual(SourceKind.local.iconName, "folder")
        XCTAssertEqual(SourceKind.git.iconName, "arrow.triangle.branch")
    }

    func testSourceKindAllCases() {
        XCTAssertEqual(SourceKind.allCases.count, 2)
        XCTAssertTrue(SourceKind.allCases.contains(.local))
        XCTAssertTrue(SourceKind.allCases.contains(.git))
    }

    func testSourceKindCodable() throws {
        for kind in SourceKind.allCases {
            let encoded = try JSONEncoder().encode(kind)
            let decoded = try JSONDecoder().decode(SourceKind.self, from: encoded)
            XCTAssertEqual(kind, decoded)
        }
    }

    // MARK: - Source Tests

    func testLocalSourceScanPath() {
        let source = Source(
            id: "test",
            displayName: "Test Source",
            kind: .local,
            path: "~/test",
            branch: "",
            createdAt: .now
        )

        let home = FileManager.default.homeDirectoryForCurrentUser.path
        XCTAssertEqual(source.scanRootPath, "\(home)/test")
    }

    func testGitSourceScanPath() {
        let source = Source(
            id: "test",
            displayName: "Test Repo",
            kind: .git,
            path: "/tmp/repo",
            url: "https://github.com/user/repo",
            clonePath: "/tmp/clone",
            branch: "main",
            createdAt: .now
        )

        XCTAssertEqual(source.scanRootPath, "/tmp/clone")
    }

    func testGitSourceScanPathFallback() {
        let source = Source(
            id: "test",
            displayName: "Test Repo",
            kind: .git,
            path: "/tmp/repo",
            url: "https://github.com/user/repo",
            clonePath: nil,
            branch: "main",
            createdAt: .now
        )

        XCTAssertEqual(source.scanRootPath, "/tmp/repo")
    }

    func testLocalSourceDisplayPath() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let source = Source(
            id: "test",
            displayName: "Test Source",
            kind: .local,
            path: "\(home)/test",
            branch: "",
            createdAt: .now
        )

        XCTAssertEqual(source.displayPath, "~/test")
    }

    func testLocalSourceDisplayPathOutsideHome() {
        let source = Source(
            id: "test",
            displayName: "Test Source",
            kind: .local,
            path: "/tmp/test",
            branch: "",
            createdAt: .now
        )

        XCTAssertEqual(source.displayPath, "/tmp/test")
    }

    func testGitSourceDisplayPath() {
        let source = Source(
            id: "test",
            displayName: "Test Repo",
            kind: .git,
            path: "/tmp/repo",
            url: "https://github.com/user/repo",
            branch: "main",
            createdAt: .now
        )

        XCTAssertEqual(source.displayPath, "https://github.com/user/repo")
    }

    func testSourceCodable() throws {
        let source = Source(
            id: "test-123",
            displayName: "Test Source",
            kind: .local,
            path: "~/test",
            url: nil,
            clonePath: nil,
            branch: "",
            createdAt: Date(),
            lastScannedAt: nil,
            lastSyncedAt: nil,
            lastError: nil
        )

        let encoded = try JSONEncoder().encode(source)
        let decoded = try JSONDecoder().decode(Source.self, from: encoded)

        XCTAssertEqual(decoded.id, source.id)
        XCTAssertEqual(decoded.displayName, source.displayName)
        XCTAssertEqual(decoded.kind, source.kind)
        XCTAssertEqual(decoded.path, source.path)
    }

    // MARK: - SourceInstall Tests

    func testSourceInstallCodable() throws {
        let install = SourceInstall(
            id: "test-install",
            sourceID: "source-1",
            sourceSkillRelativePath: "skills/test",
            sourceSkillAbsolutePath: "/tmp/skills/test",
            targetID: "claude",
            targetDisplayName: "Claude",
            installedPath: "~/.claude/skills/test",
            symlinkTarget: "/tmp/skills/test",
            installedAt: Date()
        )

        let encoded = try JSONEncoder().encode(install)
        let decoded = try JSONDecoder().decode(SourceInstall.self, from: encoded)

        XCTAssertEqual(decoded.id, install.id)
        XCTAssertEqual(decoded.sourceID, install.sourceID)
        XCTAssertEqual(decoded.targetID, install.targetID)
        XCTAssertEqual(decoded.installedPath, install.installedPath)
    }

    // MARK: - SourceSkillMatch Tests

    func testInstallName() {
        let match = SourceSkillMatch(
            source: Source(
                id: "test",
                displayName: "Test",
                kind: .local,
                path: "/tmp",
                branch: "",
                createdAt: .now
            ),
            skillDirectoryPath: "/tmp/My Test Skill",
            skillFilePath: "/tmp/My Test Skill/SKILL.md",
            relativeSkillPath: "My Test Skill"
        )

        XCTAssertEqual(match.installName, "my-test-skill")
    }

    func testInstallNameWithSpecialCharacters() {
        let match = SourceSkillMatch(
            source: Source(
                id: "test",
                displayName: "Test",
                kind: .local,
                path: "/tmp",
                branch: "",
                createdAt: .now
            ),
            skillDirectoryPath: "/tmp/Test@Skill#123",
            skillFilePath: "/tmp/Test@Skill#123/SKILL.md",
            relativeSkillPath: "Test@Skill#123"
        )

        XCTAssertEqual(match.installName, "testskill123")
    }

    func testInstallNameWithLeadingTrailingDashes() {
        let match = SourceSkillMatch(
            source: Source(
                id: "test",
                displayName: "Test",
                kind: .local,
                path: "/tmp",
                branch: "",
                createdAt: .now
            ),
            skillDirectoryPath: "/tmp/---test-skill---",
            skillFilePath: "/tmp/---test-skill---/SKILL.md",
            relativeSkillPath: "---test-skill---"
        )

        XCTAssertEqual(match.installName, "test-skill")
    }

    func testInstallNameEmpty() {
        let match = SourceSkillMatch(
            source: Source(
                id: "test",
                displayName: "Test",
                kind: .local,
                path: "/tmp",
                branch: "",
                createdAt: .now
            ),
            skillDirectoryPath: "/tmp/@#$",
            skillFilePath: "/tmp/@#$/SKILL.md",
            relativeSkillPath: "@#$"
        )

        XCTAssertEqual(match.installName, "skill")
    }
}
