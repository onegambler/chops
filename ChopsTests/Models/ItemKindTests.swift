import XCTest
@testable import Chops

final class ItemKindTests: XCTestCase {

    func testItemKindDisplayNames() {
        XCTAssertEqual(ItemKind.skill.displayName, "Skills")
        XCTAssertEqual(ItemKind.agent.displayName, "Agents")
        XCTAssertEqual(ItemKind.rule.displayName, "Rules")
    }

    func testItemKindSingularNames() {
        XCTAssertEqual(ItemKind.skill.singularName, "Skill")
        XCTAssertEqual(ItemKind.agent.singularName, "Agent")
        XCTAssertEqual(ItemKind.rule.singularName, "Rule")
    }

    func testItemKindIcons() {
        XCTAssertEqual(ItemKind.skill.icon, "doc.text")
        XCTAssertEqual(ItemKind.agent.icon, "person.crop.rectangle")
        XCTAssertEqual(ItemKind.rule.icon, "list.bullet.rectangle")
    }

    func testItemKindCodable() throws {
        for kind in ItemKind.allCases {
            let encoded = try JSONEncoder().encode(kind)
            let decoded = try JSONDecoder().decode(ItemKind.self, from: encoded)
            XCTAssertEqual(kind, decoded)
        }
    }

    func testItemKindRawValues() {
        XCTAssertEqual(ItemKind.skill.rawValue, "skill")
        XCTAssertEqual(ItemKind.agent.rawValue, "agent")
        XCTAssertEqual(ItemKind.rule.rawValue, "rule")
    }

    func testItemKindAllCases() {
        XCTAssertEqual(ItemKind.allCases.count, 3)
        XCTAssertTrue(ItemKind.allCases.contains(.skill))
        XCTAssertTrue(ItemKind.allCases.contains(.agent))
        XCTAssertTrue(ItemKind.allCases.contains(.rule))
    }
}
