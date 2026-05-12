import XCTest
import SwiftData
@testable import Chops

@MainActor
final class SkillTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var tempDir: URL!

    override func setUp() async throws {
        try await super.setUp()

        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let schema = Schema([
            SchemaV1.Skill.self,
            SchemaV1.SkillCollection.self,
            SchemaV1.RemoteServer.self
        ])

        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        modelContainer = try ModelContainer(for: schema, configurations: [config])
        modelContext = ModelContext(modelContainer)
    }

    override func tearDown() async throws {
        try await super.tearDown()
        modelContainer = nil
        modelContext = nil
        try? FileManager.default.removeItem(at: tempDir)
    }

    // MARK: - ItemKind Property Tests

    func testItemKindProperty() {
        let skill = Skill(
            name: "Test",
            skillDescription: "Test",
            content: "Content",
            filePath: tempDir.appendingPathComponent("test.md").path,
            kind: "skill",
            toolSourcesRaw: "claude"
        )

        XCTAssertEqual(skill.itemKind, .skill)

        skill.itemKind = .agent
        XCTAssertEqual(skill.itemKind, .agent)
        XCTAssertEqual(skill.kind, "agent")
    }

    func testItemKindInvalidFallback() {
        let skill = Skill(
            name: "Test",
            skillDescription: "Test",
            content: "Content",
            filePath: tempDir.appendingPathComponent("test.md").path,
            kind: "invalid-kind",
            toolSourcesRaw: "claude"
        )

        XCTAssertEqual(skill.itemKind, .skill)
    }

    // MARK: - Display Type Name Tests

    func testDisplayTypeNameSkill() {
        let skill = Skill(
            name: "Test",
            skillDescription: "Test",
            content: "Content",
            filePath: tempDir.appendingPathComponent("test.md").path,
            kind: "skill",
            toolSourcesRaw: "claude"
        )

        XCTAssertEqual(skill.displayTypeName, "Skill")
    }

    func testDisplayTypeNameAgent() {
        let skill = Skill(
            name: "Test",
            skillDescription: "Test",
            content: "Content",
            filePath: tempDir.appendingPathComponent("test.md").path,
            kind: "agent",
            toolSourcesRaw: "claude"
        )

        XCTAssertEqual(skill.displayTypeName, "Agent")
    }

    func testDisplayTypeNameRule() {
        let skill = Skill(
            name: "Test",
            skillDescription: "Test",
            content: "Content",
            filePath: tempDir.appendingPathComponent("test.md").path,
            kind: "rule",
            toolSourcesRaw: "cursor"
        )

        XCTAssertEqual(skill.displayTypeName, "Rule")
    }

    // MARK: - Tool Sources Tests

    func testToolSourcesSingleTool() {
        let skill = Skill(
            name: "Test",
            skillDescription: "Test",
            content: "Content",
            filePath: tempDir.appendingPathComponent("test.md").path,
            kind: "skill",
            toolSourcesRaw: "claude"
        )

        XCTAssertEqual(skill.toolSources.count, 1)
        XCTAssertEqual(skill.toolSources.first, .claude)
        XCTAssertEqual(skill.toolSource, .claude)
    }

    func testToolSourcesMultipleTools() {
        let skill = Skill(
            name: "Test",
            skillDescription: "Test",
            content: "Content",
            filePath: tempDir.appendingPathComponent("test.md").path,
            kind: "skill",
            toolSourcesRaw: "claude,cursor,codex"
        )

        XCTAssertEqual(skill.toolSources.count, 3)
        XCTAssertTrue(skill.toolSources.contains(.claude))
        XCTAssertTrue(skill.toolSources.contains(.cursor))
        XCTAssertTrue(skill.toolSources.contains(.codex))
    }

    func testToolSourcesSetUnique() {
        let skill = Skill(
            name: "Test",
            skillDescription: "Test",
            content: "Content",
            filePath: tempDir.appendingPathComponent("test.md").path,
            kind: "skill",
            toolSourcesRaw: "claude"
        )

        skill.toolSources = [.claude, .cursor, .claude, .codex, .cursor]

        XCTAssertEqual(skill.toolSources.count, 3)
        XCTAssertTrue(skill.toolSources.contains(.claude))
        XCTAssertTrue(skill.toolSources.contains(.cursor))
        XCTAssertTrue(skill.toolSources.contains(.codex))
    }

    func testToolSourcesEmpty() {
        let skill = Skill(
            name: "Test",
            skillDescription: "Test",
            content: "Content",
            filePath: tempDir.appendingPathComponent("test.md").path,
            kind: "skill",
            toolSourcesRaw: ""
        )

        XCTAssertEqual(skill.toolSources.count, 0)
        XCTAssertEqual(skill.toolSource, .custom)
    }

    // MARK: - Installed Paths Tests

    func testInstalledPathsDefault() {
        let path = tempDir.appendingPathComponent("test.md").path
        let skill = Skill(
            name: "Test",
            skillDescription: "Test",
            content: "Content",
            filePath: path,
            kind: "skill",
            toolSourcesRaw: "claude"
        )

        XCTAssertEqual(skill.installedPaths, [path])
    }

    func testInstalledPathsMultiple() {
        let skill = Skill(
            name: "Test",
            skillDescription: "Test",
            content: "Content",
            filePath: "/path1/test.md",
            kind: "skill",
            toolSourcesRaw: "claude"
        )

        skill.installedPaths = ["/path1/test.md", "/path2/test.md", "/path3/test.md"]

        XCTAssertEqual(skill.installedPaths.count, 3)
        XCTAssertTrue(skill.installedPaths.contains("/path1/test.md"))
        XCTAssertTrue(skill.installedPaths.contains("/path2/test.md"))
        XCTAssertTrue(skill.installedPaths.contains("/path3/test.md"))
    }

    func testInstalledPathsUnique() {
        let skill = Skill(
            name: "Test",
            skillDescription: "Test",
            content: "Content",
            filePath: "/path/test.md",
            kind: "skill",
            toolSourcesRaw: "claude"
        )

        skill.installedPaths = ["/path/test.md", "/path/test.md", "/other/test.md"]

        XCTAssertEqual(skill.installedPaths.count, 2)
    }

    // MARK: - Frontmatter Tests

    func testFrontmatterEmpty() {
        let skill = Skill(
            name: "Test",
            skillDescription: "Test",
            content: "Content",
            filePath: tempDir.appendingPathComponent("test.md").path,
            kind: "skill",
            toolSourcesRaw: "claude"
        )

        XCTAssertTrue(skill.frontmatter.isEmpty)
    }

    func testFrontmatterSetGet() {
        let skill = Skill(
            name: "Test",
            skillDescription: "Test",
            content: "Content",
            filePath: tempDir.appendingPathComponent("test.md").path,
            kind: "skill",
            toolSourcesRaw: "claude"
        )

        skill.frontmatter = [
            "name": "Test Skill",
            "author": "Test Author",
            "version": "1.0"
        ]

        XCTAssertEqual(skill.frontmatter.count, 3)
        XCTAssertEqual(skill.frontmatter["name"], "Test Skill")
        XCTAssertEqual(skill.frontmatter["author"], "Test Author")
        XCTAssertEqual(skill.frontmatter["version"], "1.0")
    }

    // MARK: - Remote Skill Tests

    func testIsRemoteFalse() {
        let skill = Skill(
            name: "Test",
            skillDescription: "Test",
            content: "Content",
            filePath: tempDir.appendingPathComponent("test.md").path,
            kind: "skill",
            toolSourcesRaw: "claude"
        )

        XCTAssertFalse(skill.isRemote)
    }

    func testIsRemoteTrue() {
        let server = RemoteServer(
            label: "Test Server",
            host: "example.com",
            port: 22,
            username: "test",
            skillsBasePath: "/home/test/skills"
        )

        let skill = Skill(
            name: "Remote Skill",
            skillDescription: "Test",
            content: "Content",
            filePath: "remote://test-server/skill1",
            kind: "skill",
            toolSourcesRaw: "claude"
        )
        skill.remoteServer = server

        XCTAssertTrue(skill.isRemote)
    }

    // MARK: - Plugin Skill Tests

    func testIsPluginClaudePluginPath() {
        let skill = Skill(
            name: "Plugin Skill",
            skillDescription: "Test",
            content: "Content",
            filePath: "/Users/test/.claude/plugins/cache/publisher/plugin/1.0/skill.md",
            kind: "skill",
            toolSourcesRaw: "claude"
        )

        XCTAssertTrue(skill.isPlugin)
    }

    func testIsPluginClaudeDesktop() {
        let skill = Skill(
            name: "Desktop Skill",
            skillDescription: "Test",
            content: "Content",
            filePath: "/path/to/skill.md",
            kind: "skill",
            toolSourcesRaw: "claudeDesktop"
        )

        XCTAssertTrue(skill.isPlugin)
    }

    func testIsPluginSessionPath() {
        let skill = Skill(
            name: "Session Skill",
            skillDescription: "Test",
            content: "Content",
            filePath: "/Users/test/Library/Application Support/Claude/local-agent-mode-sessions/session/skill.md",
            kind: "skill",
            toolSourcesRaw: "claude"
        )

        XCTAssertTrue(skill.isPlugin)
    }

    func testIsPluginFalse() {
        let skill = Skill(
            name: "Regular Skill",
            skillDescription: "Test",
            content: "Content",
            filePath: "/Users/test/.claude/skills/skill.md",
            kind: "skill",
            toolSourcesRaw: "claude"
        )

        XCTAssertFalse(skill.isPlugin)
    }

    // MARK: - Read-Only Tests

    func testIsReadOnlyPlugin() {
        let skill = Skill(
            name: "Plugin Skill",
            skillDescription: "Test",
            content: "Content",
            filePath: "/Users/test/.claude/plugins/cache/publisher/plugin/1.0/skill.md",
            kind: "skill",
            toolSourcesRaw: "claude"
        )

        XCTAssertTrue(skill.isReadOnly)
    }

    func testIsReadOnlyFalse() {
        let skill = Skill(
            name: "Regular Skill",
            skillDescription: "Test",
            content: "Content",
            filePath: tempDir.appendingPathComponent("test.md").path,
            kind: "skill",
            toolSourcesRaw: "claude"
        )

        XCTAssertFalse(skill.isReadOnly)
    }
}
