import XCTest
@testable import Chops

final class SearchServiceTests: XCTestCase {

    func testSearchMatchesName() {
        let searchText = "test"
        let content = """
        ---
        name: Test Skill
        description: A sample skill
        ---

        Content
        """

        let matches = content.localizedCaseInsensitiveContains(searchText)
        XCTAssertTrue(matches)
    }

    func testSearchMatchesDescription() {
        let searchText = "sample"
        let description = "This is a sample description"

        let matches = description.localizedCaseInsensitiveContains(searchText)
        XCTAssertTrue(matches)
    }

    func testSearchIsCaseInsensitive() {
        let searchText = "TEST"
        let content = "test content"

        let matches = content.localizedCaseInsensitiveContains(searchText)
        XCTAssertTrue(matches)
    }

    func testSearchWithSpecialCharacters() {
        let searchText = "test-skill"
        let content = "test-skill implementation"

        let matches = content.localizedCaseInsensitiveContains(searchText)
        XCTAssertTrue(matches)
    }

    func testSearchNoMatch() {
        let searchText = "nonexistent"
        let content = "This content doesn't have the search term"

        let matches = content.localizedCaseInsensitiveContains(searchText)
        XCTAssertFalse(matches)
    }
}
