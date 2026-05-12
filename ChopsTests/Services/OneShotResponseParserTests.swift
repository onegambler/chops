import XCTest
@testable import Chops

final class OneShotResponseParserTests: XCTestCase {

    // MARK: - Structured Edit Format Tests

    func testParseStructuredEditFormat() {
        let originalContent = """
        ---
        name: Test
        ---

        Original content
        """

        let response = """
        Updated skill description

        {
          "summary": "Updated skill description",
          "edits": [
            {"find": "Original content", "replace": "Updated content"}
          ]
        }
        """

        let result = OneShotResponseParser.parse(response, originalContent: originalContent)

        XCTAssertEqual(result.summary, "Updated skill description")
        XCTAssertTrue(result.newContent?.contains("Updated content") ?? false)
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

        let result = OneShotResponseParser.parse(response, originalContent: nil)

        XCTAssertEqual(result.summary, "I've updated the skill.")
        XCTAssertTrue(result.newContent?.contains("Test Skill") ?? false)
        XCTAssertTrue(result.newContent?.contains("updated content") ?? false)
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

        let result = OneShotResponseParser.parse(response, originalContent: nil)

        XCTAssertEqual(result.summary, "Updated the file:")
        XCTAssertTrue(result.newContent?.contains("Simple Skill") ?? false)
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

        let result = OneShotResponseParser.parse(response, originalContent: nil)

        XCTAssertNotNil(result.newContent)
        XCTAssertTrue(result.newContent?.contains("print(\"hello\")") ?? false)
    }

    // MARK: - Edge Cases

    func testParseResponseWithNoCodeBlocks() {
        let response = "This is just plain text without any code blocks."

        let result = OneShotResponseParser.parse(response, originalContent: nil)

        XCTAssertEqual(result.summary, response)
        XCTAssertNil(result.newContent)
    }

    func testParseEmptyResponse() {
        let response = ""

        let result = OneShotResponseParser.parse(response, originalContent: nil)

        XCTAssertEqual(result.summary, "")
        XCTAssertNil(result.newContent)
    }

    func testParseStructuredEditsWithNoEdits() {
        let response = """
        ```json
        {
          "summary": "No changes needed",
          "edits": []
        }
        ```
        """

        let result = OneShotResponseParser.parse(response, originalContent: "original")

        XCTAssertEqual(result.summary, "No changes needed")
        XCTAssertNil(result.newContent)
    }

    func testParseStructuredEditsWithoutOriginal() {
        let response = """
        ```json
        {
          "summary": "Made changes",
          "edits": [
            {"find": "old", "replace": "new"}
          ]
        }
        ```
        """

        let result = OneShotResponseParser.parse(response, originalContent: nil)

        XCTAssertEqual(result.summary, "Made changes")
        XCTAssertNil(result.newContent)
    }
}
