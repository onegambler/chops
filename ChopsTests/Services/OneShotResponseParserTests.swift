import XCTest
@testable import Chops

final class OneShotResponseParserTests: XCTestCase {

    // MARK: - Structured Edit Format Tests

    func testParseStructuredEditFormat() {
        let response = """
        Here's the updated file:

        ```json
        {
          "summary": "Updated skill description",
          "full_file": "---\\nname: Test\\n---\\n\\nUpdated content"
        }
        ```
        """

        let result = OneShotResponseParser.parse(response)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.summary, "Updated skill description")
        XCTAssertTrue(result?.fileContent.contains("Updated content") ?? false)
    }

    // MARK: - Fenced Block Format Tests

    func testParseFencedMarkdownBlock() {
        let response = """
        I've updated the skill.

        ```markdown
        ---
        name: Test Skill
        ---

        This is the updated content.
        ```
        """

        let result = OneShotResponseParser.parse(response)

        XCTAssertNotNil(result)
        XCTAssertTrue(result?.fileContent.contains("Test Skill") ?? false)
        XCTAssertTrue(result?.fileContent.contains("updated content") ?? false)
    }

    func testParseFencedCodeBlock() {
        let response = """
        Updated the file:

        ```
        ---
        name: Simple Skill
        ---

        Content here.
        ```
        """

        let result = OneShotResponseParser.parse(response)

        XCTAssertNotNil(result)
        XCTAssertTrue(result?.fileContent.contains("Simple Skill") ?? false)
    }

    func testParseMultipleFencedBlocks() {
        let response = """
        Here's a code example:

        ```python
        print("hello")
        ```

        And here's the full file:

        ```markdown
        ---
        name: Test
        ---

        Content
        ```
        """

        let result = OneShotResponseParser.parse(response)

        XCTAssertNotNil(result)
        XCTAssertTrue(result?.fileContent.contains("name: Test") ?? false)
    }

    // MARK: - Edge Cases

    func testParseResponseWithNoCodeBlocks() {
        let response = "This is just plain text without any code blocks."

        let result = OneShotResponseParser.parse(response)

        XCTAssertNil(result)
    }

    func testParseEmptyResponse() {
        let response = ""

        let result = OneShotResponseParser.parse(response)

        XCTAssertNil(result)
    }

    func testParseInvalidJSON() {
        let response = """
        ```json
        { invalid json here }
        ```
        """

        let result = OneShotResponseParser.parse(response)

        // Should fall back to raw fence content or return nil
        XCTAssertTrue(result == nil || result?.fileContent.contains("invalid") ?? false)
    }

    func testParseWithEscapedNewlines() {
        let response = """
        ```json
        {
          "summary": "Test",
          "full_file": "Line 1\\nLine 2\\nLine 3"
        }
        ```
        """

        let result = OneShotResponseParser.parse(response)

        XCTAssertNotNil(result)
        XCTAssertTrue(result?.fileContent.contains("Line 1") ?? false)
        XCTAssertTrue(result?.fileContent.contains("Line 2") ?? false)
    }
}
