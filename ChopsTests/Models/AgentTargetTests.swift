import XCTest
@testable import Chops

final class AgentTargetTests: XCTestCase {

    func testAgentTargetProperties() {
        let target = AgentTarget(
            id: "test-agent",
            displayName: "Test Agent",
            globalSkillsDir: "~/.test/skills",
            skillFileName: "SKILL.md",
            evidencePaths: ["/test/path"],
            appBundleName: "TestApp",
            cliBinaryName: "test"
        )

        XCTAssertEqual(target.id, "test-agent")
        XCTAssertEqual(target.displayName, "Test Agent")
        XCTAssertEqual(target.skillFileName, "SKILL.md")
        XCTAssertEqual(target.evidencePaths.count, 1)
    }

    func testExpandedSkillsDir() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let target = AgentTarget(
            id: "test",
            displayName: "Test",
            globalSkillsDir: "~/.test/skills",
            skillFileName: "SKILL.md",
            evidencePaths: [],
            appBundleName: nil,
            cliBinaryName: nil
        )

        XCTAssertEqual(target.expandedSkillsDir, "\(home)/.test/skills")
    }

    func testExpandedSkillsDirAbsolute() {
        let target = AgentTarget(
            id: "test",
            displayName: "Test",
            globalSkillsDir: "/tmp/skills",
            skillFileName: "SKILL.md",
            evidencePaths: [],
            appBundleName: nil,
            cliBinaryName: nil
        )

        XCTAssertEqual(target.expandedSkillsDir, "/tmp/skills")
    }

    func testAllTargetsExist() {
        XCTAssertFalse(AgentTarget.all.isEmpty)
    }

    func testAllTargetsHaveUniqueIDs() {
        let ids = AgentTarget.all.map(\.id)
        let uniqueIDs = Set(ids)
        XCTAssertEqual(ids.count, uniqueIDs.count, "Agent target IDs must be unique")
    }

    func testAllTargetsHaveDisplayNames() {
        for target in AgentTarget.all {
            XCTAssertFalse(target.displayName.isEmpty, "\(target.id) should have a display name")
        }
    }

    func testAllTargetsHaveSkillsDir() {
        for target in AgentTarget.all {
            XCTAssertFalse(target.globalSkillsDir.isEmpty, "\(target.id) should have a skills directory")
        }
    }

    func testAllTargetsHaveEvidenceOrIdentifier() {
        for target in AgentTarget.all {
            let hasEvidence = !target.evidencePaths.isEmpty
            let hasApp = target.appBundleName != nil
            let hasCLI = target.cliBinaryName != nil

            XCTAssertTrue(
                hasEvidence || hasApp || hasCLI,
                "\(target.id) should have at least one way to detect installation"
            )
        }
    }

    func testKnownTargetsIncluded() {
        let ids = Set(AgentTarget.all.map(\.id))

        XCTAssertTrue(ids.contains("claude-code"))
        XCTAssertTrue(ids.contains("codex"))
        XCTAssertTrue(ids.contains("cursor"))
        XCTAssertTrue(ids.contains("windsurf"))
    }

    func testInstalledTargets() {
        let installed = AgentTarget.installed

        // Should be a subset of all targets
        XCTAssertTrue(installed.count <= AgentTarget.all.count)

        // All installed targets should report isInstalled as true
        for target in installed {
            XCTAssertTrue(target.isInstalled)
        }
    }

    func testHashable() {
        let target1 = AgentTarget(
            id: "test",
            displayName: "Test",
            globalSkillsDir: "~/.test",
            skillFileName: "SKILL.md",
            evidencePaths: [],
            appBundleName: nil,
            cliBinaryName: nil
        )

        let target2 = AgentTarget(
            id: "test",
            displayName: "Test",
            globalSkillsDir: "~/.test",
            skillFileName: "SKILL.md",
            evidencePaths: [],
            appBundleName: nil,
            cliBinaryName: nil
        )

        let target3 = AgentTarget(
            id: "different",
            displayName: "Different",
            globalSkillsDir: "~/.different",
            skillFileName: "SKILL.md",
            evidencePaths: [],
            appBundleName: nil,
            cliBinaryName: nil
        )

        XCTAssertEqual(target1, target2)
        XCTAssertNotEqual(target1, target3)

        let set: Set = [target1, target2, target3]
        XCTAssertEqual(set.count, 2)
    }
}
