import XCTest
@testable import Chops

final class SkillParserTests: XCTestCase {
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

    // MARK: - Frontmatter Parsing Tests

    func testParseFrontmatterSkill() throws {
        let content = """
        ---
        name: Test Skill
        description: A test skill for unit testing
        ---

        # Content

        This is the skill content.
        """

        let fileURL = tempDir.appendingPathComponent("test.md")
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        let result = SkillParser.parse(fileURL: fileURL, toolSource: .claude)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "Test Skill")
        XCTAssertEqual(result?.description, "A test skill for unit testing")
        XCTAssertTrue(result?.content.contains("# Content") ?? false)
    }

    func testParseSkillWithoutFrontmatter() throws {
        let content = """
        # Test Skill

        This is a skill without frontmatter.
        """

        let fileURL = tempDir.appendingPathComponent("test.md")
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        let result = SkillParser.parse(fileURL: fileURL, toolSource: .codex)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "Test Skill")
        XCTAssertEqual(result?.content, content)
    }

    func testParseMDCFormat() throws {
        let content = """
        This is an MDC format skill.

        It doesn't use frontmatter.
        """

        let fileURL = tempDir.appendingPathComponent("test.mdc")
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        let result = SkillParser.parse(fileURL: fileURL, toolSource: .claude)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.content, content)
    }

    func testParseInvalidFile() throws {
        let fileURL = tempDir.appendingPathComponent("nonexistent.md")

        let result = SkillParser.parse(fileURL: fileURL, toolSource: .claude)

        XCTAssertNil(result)
    }

    func testParseFrontmatterWithMultipleFields() throws {
        let content = """
        ---
        name: Advanced Skill
        description: A more complex skill
        author: Test Author
        version: "1.0"
        tags: test,unit,ci
        ---

        Skill implementation goes here.
        """

        let fileURL = tempDir.appendingPathComponent("advanced.md")
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        let result = SkillParser.parse(fileURL: fileURL, toolSource: .claude)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "Advanced Skill")
        XCTAssertEqual(result?.description, "A more complex skill")
        XCTAssertEqual(result?.frontmatter["author"], "Test Author")
        XCTAssertEqual(result?.frontmatter["version"], "1.0")
    }

    func testParseEmptyFile() throws {
        let content = ""
        let fileURL = tempDir.appendingPathComponent("empty.md")
        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        let result = SkillParser.parse(fileURL: fileURL, toolSource: .claude)

        XCTAssertNotNil(result)
        XCTAssertTrue(result?.name.isEmpty ?? false)
    }
}
