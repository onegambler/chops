import XCTest
@testable import Chops

@MainActor
final class SourceStoreTests: XCTestCase {
    var tempDir: URL!
    var testSourcesDir: URL!

    override func setUp() async throws {
        try await super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        testSourcesDir = tempDir.appendingPathComponent("sources", isDirectory: true)
        try FileManager.default.createDirectory(at: testSourcesDir, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        try await super.tearDown()
        try? FileManager.default.removeItem(at: tempDir)
    }

    // MARK: - Source Management Tests

    func testLoadEmptySources() throws {
        let sources = try SourceStore.loadSourcesSnapshot()
        XCTAssertNotNil(sources)
    }

    func testSlugGeneration() {
        XCTAssertEqual(SourceStore.slug(for: "My Test Repo"), "my-test-repo")
        XCTAssertEqual(SourceStore.slug(for: "test.git"), "test")
        XCTAssertEqual(SourceStore.slug(for: "Test_Repo-123"), "test_repo-123")
        XCTAssertEqual(SourceStore.slug(for: "...test..."), "test")
        XCTAssertEqual(SourceStore.slug(for: ""), "source")
    }

    func testRepoNameExtraction() {
        XCTAssertEqual(SourceStore.repoName(from: "https://github.com/user/repo.git"), "repo")
        XCTAssertEqual(SourceStore.repoName(from: "git@github.com:user/repo.git"), "repo")
        XCTAssertEqual(SourceStore.repoName(from: "https://github.com/user/my-skills"), "my-skills")
        XCTAssertEqual(SourceStore.repoName(from: ""), "Git Source")
    }

    func testPathIsInside() {
        XCTAssertTrue(SourceStore.pathIsInside("/root/sub/file", root: "/root"))
        XCTAssertTrue(SourceStore.pathIsInside("/root", root: "/root"))
        XCTAssertFalse(SourceStore.pathIsInside("/other/file", root: "/root"))
        XCTAssertFalse(SourceStore.pathIsInside("/root-other/file", root: "/root"))
    }

    func testRelativePath() {
        XCTAssertEqual(
            SourceStore.relativePath("/root/sub/file", root: "/root"),
            "sub/file"
        )
        XCTAssertEqual(
            SourceStore.relativePath("/root/file.txt", root: "/root"),
            "file.txt"
        )
        XCTAssertEqual(
            SourceStore.relativePath("/other/file", root: "/root"),
            "file"
        )
    }

    func testSourceRootsSnapshot() {
        let roots = SourceStore.sourceRootsSnapshot()
        XCTAssertNotNil(roots)
    }

    // MARK: - Source JSON Serialization Tests

    func testSourceSerialization() throws {
        let source = Source(
            id: "test-source",
            displayName: "Test Source",
            kind: .local,
            path: "/tmp/test",
            branch: "",
            createdAt: Date()
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let sources: [Source] = [source]
        let data = try encoder.encode(sources)
        let decoded = try decoder.decode([Source].self, from: data)

        XCTAssertEqual(decoded.count, 1)
        XCTAssertEqual(decoded.first?.id, source.id)
        XCTAssertEqual(decoded.first?.displayName, source.displayName)
        XCTAssertEqual(decoded.first?.kind, source.kind)
    }

    func testInstallSerialization() throws {
        let install = SourceInstall(
            id: UUID().uuidString,
            sourceID: "test-source",
            sourceSkillRelativePath: "skills/test",
            sourceSkillAbsolutePath: "/source/skills/test",
            targetID: "claude",
            targetDisplayName: "Claude Code",
            installedPath: "/test/path",
            symlinkTarget: "/source/skills/test",
            installedAt: Date()
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let installs: [SourceInstall] = [install]
        let data = try encoder.encode(installs)
        let decoded = try decoder.decode([SourceInstall].self, from: data)

        XCTAssertEqual(decoded.count, 1)
        XCTAssertEqual(decoded.first?.sourceID, install.sourceID)
        XCTAssertEqual(decoded.first?.targetID, install.targetID)
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
