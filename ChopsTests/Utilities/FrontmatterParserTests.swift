import XCTest
@testable import Chops

final class FrontmatterParserTests: XCTestCase {

    func testParseValidFrontmatter() {
        let text = """
        ---
        name: Test Skill
        description: A test description
        author: Test Author
        ---

        # Content
        This is the content.
        """

        let result = FrontmatterParser.parse(text)

        XCTAssertEqual(result.name, "Test Skill")
        XCTAssertEqual(result.description, "A test description")
        XCTAssertEqual(result.frontmatter["author"], "Test Author")
        XCTAssertTrue(result.content.contains("# Content"))
        XCTAssertTrue(result.content.contains("This is the content."))
    }

    func testParseNoFrontmatter() {
        let text = """
        # Just Content
        No frontmatter here.
        """

        let result = FrontmatterParser.parse(text)

        XCTAssertTrue(result.name.isEmpty)
        XCTAssertTrue(result.description.isEmpty)
        XCTAssertTrue(result.frontmatter.isEmpty)
        XCTAssertEqual(result.content, text)
    }

    func testParseIncompleteFrontmatter() {
        let text = """
        ---
        name: Incomplete
        description: Missing closing delimiter

        Content here
        """

        let result = FrontmatterParser.parse(text)

        XCTAssertTrue(result.name.isEmpty)
        XCTAssertTrue(result.description.isEmpty)
        XCTAssertTrue(result.frontmatter.isEmpty)
        XCTAssertEqual(result.content, text)
    }

    func testParseFrontmatterWithQuotedValues() {
        let text = """
        ---
        name: "Quoted Name"
        description: 'Single quoted'
        version: "1.0.0"
        ---

        Content
        """

        let result = FrontmatterParser.parse(text)

        XCTAssertEqual(result.name, "\"Quoted Name\"")
        XCTAssertEqual(result.description, "'Single quoted'")
        XCTAssertEqual(result.frontmatter["version"], "\"1.0.0\"")
    }

    func testParseFrontmatterWithColonsInValue() {
        let text = """
        ---
        name: Test
        url: https://example.com:8080/path
        time: 12:30:45
        ---

        Content
        """

        let result = FrontmatterParser.parse(text)

        XCTAssertEqual(result.frontmatter["url"], "https://example.com:8080/path")
        XCTAssertEqual(result.frontmatter["time"], "12:30:45")
    }

    func testParseFrontmatterWithEmptyValues() {
        let text = """
        ---
        name: Test
        description:
        author:
        ---

        Content
        """

        let result = FrontmatterParser.parse(text)

        XCTAssertEqual(result.name, "Test")
        XCTAssertEqual(result.description, "")
        XCTAssertEqual(result.frontmatter["author"], "")
    }

    func testParseFrontmatterWithWhitespace() {
        let text = """
        ---
          name  :   Test Skill
          description:A description
        ---

        Content
        """

        let result = FrontmatterParser.parse(text)

        XCTAssertEqual(result.name, "Test Skill")
        XCTAssertEqual(result.description, "A description")
    }

    func testParseEmptyContent() {
        let text = """
        ---
        name: Test
        ---
        """

        let result = FrontmatterParser.parse(text)

        XCTAssertEqual(result.name, "Test")
        XCTAssertTrue(result.content.isEmpty)
    }

    func testParseEmptyString() {
        let result = FrontmatterParser.parse("")

        XCTAssertTrue(result.name.isEmpty)
        XCTAssertTrue(result.content.isEmpty)
    }

    func testParseFrontmatterOnlyDashes() {
        let text = """
        ---
        ---
        Content
        """

        let result = FrontmatterParser.parse(text)

        XCTAssertTrue(result.frontmatter.isEmpty)
        XCTAssertEqual(result.content, "Content")
    }

    func testParseFrontmatterWithInvalidLines() {
        let text = """
        ---
        name: Valid
        invalid line without colon
        description: Also valid
        ---

        Content
        """

        let result = FrontmatterParser.parse(text)

        XCTAssertEqual(result.name, "Valid")
        XCTAssertEqual(result.description, "Also valid")
        XCTAssertEqual(result.frontmatter.count, 2)
    }

    func testParseFrontmatterMultilineContent() {
        let text = """
        ---
        name: Test
        ---

        Line 1
        Line 2

        Line 4
        """

        let result = FrontmatterParser.parse(text)

        XCTAssertTrue(result.content.contains("Line 1"))
        XCTAssertTrue(result.content.contains("Line 2"))
        XCTAssertTrue(result.content.contains("Line 4"))
    }
}
