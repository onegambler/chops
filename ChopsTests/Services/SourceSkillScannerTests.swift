import XCTest
@testable import Chops

final class SourceSkillScannerTests: XCTestCase {
    var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        super.tearDown()
        try? FileManager.default.removeItem(at: tempDir)
    }

    // MARK: - Skill Directory Discovery

    func testFindSkillInRootDirectory() throws {
        let skillFile = tempDir.appendingPathComponent("SKILL.md")
        try "# Test Skill".write(to: skillFile, atomically: true, encoding: .utf8)

        let results = SourceSkillScanner.skillDirectories(rootPath: tempDir.path)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.path, tempDir.path)
    }

    func testFindSkillInSubdirectories() throws {
        let skill1 = tempDir.appendingPathComponent("skill1")
        let skill2 = tempDir.appendingPathComponent("skill2")

        try FileManager.default.createDirectory(at: skill1, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: skill2, withIntermediateDirectories: true)

        try "# Skill 1".write(to: skill1.appendingPathComponent("SKILL.md"), atomically: true, encoding: .utf8)
        try "# Skill 2".write(to: skill2.appendingPathComponent("SKILL.md"), atomically: true, encoding: .utf8)

        let results = SourceSkillScanner.skillDirectories(rootPath: tempDir.path)

        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.contains { $0.lastPathComponent == "skill1" })
        XCTAssertTrue(results.contains { $0.lastPathComponent == "skill2" })
    }

    func testFindNestedSkills() throws {
        let category = tempDir.appendingPathComponent("category")
        let skill = category.appendingPathComponent("my-skill")

        try FileManager.default.createDirectory(at: skill, withIntermediateDirectories: true)
        try "# Nested Skill".write(to: skill.appendingPathComponent("SKILL.md"), atomically: true, encoding: .utf8)

        let results = SourceSkillScanner.skillDirectories(rootPath: tempDir.path)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.lastPathComponent, "my-skill")
    }

    func testIgnoreGitDirectory() throws {
        let gitDir = tempDir.appendingPathComponent(".git")
        try FileManager.default.createDirectory(at: gitDir, withIntermediateDirectories: true)
        try "# Should not find".write(to: gitDir.appendingPathComponent("SKILL.md"), atomically: true, encoding: .utf8)

        let results = SourceSkillScanner.skillDirectories(rootPath: tempDir.path)

        XCTAssertEqual(results.count, 0)
    }

    func testIgnoreNodeModules() throws {
        let nodeModules = tempDir.appendingPathComponent("node_modules/package")
        try FileManager.default.createDirectory(at: nodeModules, withIntermediateDirectories: true)
        try "# Should not find".write(to: nodeModules.appendingPathComponent("SKILL.md"), atomically: true, encoding: .utf8)

        let results = SourceSkillScanner.skillDirectories(rootPath: tempDir.path)

        XCTAssertEqual(results.count, 0)
    }

    func testIgnoreBuildDirectories() throws {
        let buildDir = tempDir.appendingPathComponent("build")
        try FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)
        try "# Should not find".write(to: buildDir.appendingPathComponent("SKILL.md"), atomically: true, encoding: .utf8)

        let results = SourceSkillScanner.skillDirectories(rootPath: tempDir.path)

        XCTAssertEqual(results.count, 0)
    }

    func testStopsAtFirstSKILLmd() throws {
        let outer = tempDir.appendingPathComponent("outer-skill")
        let inner = outer.appendingPathComponent("inner-skill")

        try FileManager.default.createDirectory(at: inner, withIntermediateDirectories: true)
        try "# Outer".write(to: outer.appendingPathComponent("SKILL.md"), atomically: true, encoding: .utf8)
        try "# Inner".write(to: inner.appendingPathComponent("SKILL.md"), atomically: true, encoding: .utf8)

        let results = SourceSkillScanner.skillDirectories(rootPath: tempDir.path)

        // Should only find outer, not descend into inner
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.lastPathComponent, "outer-skill")
    }

    func testNonexistentPath() {
        let results = SourceSkillScanner.skillDirectories(rootPath: "/nonexistent/path")

        XCTAssertEqual(results.count, 0)
    }

    func testEmptyDirectory() throws {
        let results = SourceSkillScanner.skillDirectories(rootPath: tempDir.path)

        XCTAssertEqual(results.count, 0)
    }

    func testResultsAreSorted() throws {
        let skill3 = tempDir.appendingPathComponent("skill3")
        let skill1 = tempDir.appendingPathComponent("skill1")
        let skill2 = tempDir.appendingPathComponent("skill2")

        try FileManager.default.createDirectory(at: skill3, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: skill1, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: skill2, withIntermediateDirectories: true)

        try "# Skill".write(to: skill3.appendingPathComponent("SKILL.md"), atomically: true, encoding: .utf8)
        try "# Skill".write(to: skill1.appendingPathComponent("SKILL.md"), atomically: true, encoding: .utf8)
        try "# Skill".write(to: skill2.appendingPathComponent("SKILL.md"), atomically: true, encoding: .utf8)

        let results = SourceSkillScanner.skillDirectories(rootPath: tempDir.path)

        XCTAssertEqual(results.count, 3)
        XCTAssertEqual(results[0].lastPathComponent, "skill1")
        XCTAssertEqual(results[1].lastPathComponent, "skill2")
        XCTAssertEqual(results[2].lastPathComponent, "skill3")
    }

    // MARK: - Skill Count

    func testSkillCount() throws {
        let source = Source(
            id: "test",
            displayName: "Test",
            kind: .local,
            path: tempDir.path,
            branch: "",
            createdAt: .now
        )

        let skill1 = tempDir.appendingPathComponent("skill1")
        let skill2 = tempDir.appendingPathComponent("skill2")

        try FileManager.default.createDirectory(at: skill1, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: skill2, withIntermediateDirectories: true)

        try "# Skill 1".write(to: skill1.appendingPathComponent("SKILL.md"), atomically: true, encoding: .utf8)
        try "# Skill 2".write(to: skill2.appendingPathComponent("SKILL.md"), atomically: true, encoding: .utf8)

        let count = SourceSkillScanner.skillCount(in: source)

        XCTAssertEqual(count, 2)
    }
}
