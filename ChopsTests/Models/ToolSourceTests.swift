import XCTest
@testable import Chops

final class ToolSourceTests: XCTestCase {

    func testAllToolSourcesHaveDisplayNames() {
        for tool in ToolSource.allCases {
            XCTAssertFalse(tool.displayName.isEmpty, "\(tool.rawValue) should have a display name")
        }
    }

    func testToolSourcePathsAreValid() {
        for tool in ToolSource.allCases {
            let paths = tool.globalPaths + tool.globalAgentPaths + tool.globalRulePaths

            // Some tools have conditional paths or no paths (custom, aider, claudeDesktop, etc.)
            // Just validate that any paths returned are properly formatted
            for path in paths {
                XCTAssertTrue(
                    path.hasPrefix("~") || path.hasPrefix("/"),
                    "\(tool.rawValue) path '\(path)' should be an absolute or tilde path"
                )
            }
        }
    }

    func testToolSourceListableFlag() {
        let listableTools = ToolSource.allCases.filter(\.listable)
        XCTAssertFalse(listableTools.isEmpty, "At least some tools should be listable")
    }

    func testToolSourceRawValues() {
        XCTAssertEqual(ToolSource.claude.rawValue, "claude")
        XCTAssertEqual(ToolSource.cursor.rawValue, "cursor")
        XCTAssertEqual(ToolSource.codex.rawValue, "codex")
        XCTAssertEqual(ToolSource.windsurf.rawValue, "windsurf")
    }

    func testToolSourceInitFromRawValue() {
        XCTAssertNotNil(ToolSource(rawValue: "claude"))
        XCTAssertNotNil(ToolSource(rawValue: "cursor"))
        XCTAssertNil(ToolSource(rawValue: "invalid-tool"))
    }
}
