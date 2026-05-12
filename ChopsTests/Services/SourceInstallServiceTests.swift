import XCTest
@testable import Chops

@MainActor
final class SourceInstallServiceTests: XCTestCase {
    var tempDir: URL!

    override func setUp() async throws {
        try await super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        try await super.tearDown()
        try? FileManager.default.removeItem(at: tempDir)
    }

    // MARK: - Install Summary Tests

    func testInstallSummaryDisplayText() {
        var summary = SourceInstallSummary()
        summary.installed = ["skill1", "skill2"]
        summary.uninstalled = ["skill3"]
        summary.skipped = ["skill4"]
        summary.failed = ["skill5"]

        let text = summary.displayText

        XCTAssertTrue(text.contains("Installed: 2"))
        XCTAssertTrue(text.contains("Uninstalled: 1"))
        XCTAssertTrue(text.contains("Skipped: 1"))
        XCTAssertTrue(text.contains("Failed: 1"))
    }

    func testInstallSummaryEmpty() {
        let summary = SourceInstallSummary()

        XCTAssertFalse(summary.hasMessages)
        XCTAssertTrue(summary.displayText.isEmpty)
    }

    func testInstallSummaryWithMessages() {
        var summary = SourceInstallSummary()
        summary.installed = ["skill1"]

        XCTAssertTrue(summary.hasMessages)
    }

    // MARK: - Error Tests

    func testNotSourceSkillError() {
        let error = SourceInstallError.notSourceSkill("TestSkill")

        XCTAssertEqual(
            error.errorDescription,
            "TestSkill is not from a configured source."
        )
    }

    func testUnmanagedConflictError() {
        let error = SourceInstallError.unmanagedConflict("/path/to/skill")

        XCTAssertTrue(error.errorDescription?.contains("/path/to/skill") ?? false)
        XCTAssertTrue(error.errorDescription?.contains("not a Chops-managed symlink") ?? false)
    }

    func testUnsafeUninstallError() {
        let error = SourceInstallError.unsafeUninstall("/path/to/skill")

        XCTAssertTrue(error.errorDescription?.contains("/path/to/skill") ?? false)
        XCTAssertTrue(error.errorDescription?.contains("Refusing to remove") ?? false)
    }
}
