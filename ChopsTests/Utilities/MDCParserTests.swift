import XCTest
@testable import Chops

final class MDCParserTests: XCTestCase {

    func testParseMDCFile() {
        let content = """
        ---
        name: Test MDC Rule
        description: A Cursor MDC rule file
        ---

        # Rule Content

        This is an MDC rule.
        """

        let result = MDCParser.parse(content)

        XCTAssertEqual(result.name, "Test MDC Rule")
        XCTAssertEqual(result.description, "A Cursor MDC rule file")
        XCTAssertTrue(result.content.contains("# Rule Content"))
    }

    func testParseMDCWithoutFrontmatter() {
        let content = """
        # Simple MDC Rule

        Rule without frontmatter.
        """

        let result = MDCParser.parse(content)

        XCTAssertTrue(result.name.isEmpty)
        XCTAssertEqual(result.content, content)
    }

    func testMDCParserUsesFrontmatterParser() {
        // MDC parser should behave identically to frontmatter parser
        let content = """
        ---
        name: Test
        key: value
        ---

        Content here
        """

        let mdcResult = MDCParser.parse(content)
        let frontmatterResult = FrontmatterParser.parse(content)

        XCTAssertEqual(mdcResult.name, frontmatterResult.name)
        XCTAssertEqual(mdcResult.description, frontmatterResult.description)
        XCTAssertEqual(mdcResult.content, frontmatterResult.content)
        XCTAssertEqual(mdcResult.frontmatter, frontmatterResult.frontmatter)
    }
}
