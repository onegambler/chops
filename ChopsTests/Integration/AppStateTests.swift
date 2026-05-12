import XCTest
@testable import Chops

@MainActor
final class AppStateTests: XCTestCase {
    var appState: AppState!

    override func setUp() {
        super.setUp()
        appState = AppState()
    }

    override func tearDown() {
        super.tearDown()
        appState = nil
    }

    // MARK: - Selection Tests

    func testInitialState() {
        XCTAssertNil(appState.selectedTool)
        XCTAssertNil(appState.selectedSkill)
        XCTAssertEqual(appState.searchText, "")
        XCTAssertFalse(appState.showingNewSkillSheet)
        XCTAssertEqual(appState.sidebarFilter, .allSkills)
        XCTAssertTrue(appState.selectedSkillIDs.isEmpty)
    }

    func testSidebarFilterChange() {
        appState.sidebarFilter = .allAgents
        XCTAssertEqual(appState.sidebarFilter, .allAgents)

        appState.sidebarFilter = .favorites
        XCTAssertEqual(appState.sidebarFilter, .favorites)
    }

    func testMultipleSkillSelection() {
        appState.selectedSkillIDs = ["skill1", "skill2", "skill3"]
        XCTAssertEqual(appState.selectedSkillIDs.count, 3)
        XCTAssertTrue(appState.selectedSkillIDs.contains("skill1"))
        XCTAssertTrue(appState.selectedSkillIDs.contains("skill2"))
        XCTAssertTrue(appState.selectedSkillIDs.contains("skill3"))
    }

    func testSearchTextUpdate() {
        appState.searchText = "test query"
        XCTAssertEqual(appState.searchText, "test query")

        appState.searchText = ""
        XCTAssertEqual(appState.searchText, "")
    }

    func testNewSkillSheetState() {
        XCTAssertFalse(appState.showingNewSkillSheet)

        appState.showingNewSkillSheet = true
        XCTAssertTrue(appState.showingNewSkillSheet)

        appState.newItemKind = .agent
        XCTAssertEqual(appState.newItemKind, .agent)
    }

    func testToolKindFilter() {
        XCTAssertNil(appState.toolKindFilter)

        appState.toolKindFilter = .agent
        XCTAssertEqual(appState.toolKindFilter, .agent)

        appState.toolKindFilter = nil
        XCTAssertNil(appState.toolKindFilter)
    }

    // MARK: - SidebarFilter Tests

    func testSidebarFilterHashable() {
        let filter1: SidebarFilter = .allSkills
        let filter2: SidebarFilter = .allSkills
        let filter3: SidebarFilter = .allAgents

        XCTAssertEqual(filter1, filter2)
        XCTAssertNotEqual(filter1, filter3)
    }

    func testSidebarFilterSourceCase() {
        let filter1: SidebarFilter = .source("source1")
        let filter2: SidebarFilter = .source("source1")
        let filter3: SidebarFilter = .source("source2")

        XCTAssertEqual(filter1, filter2)
        XCTAssertNotEqual(filter1, filter3)
    }

    func testSidebarFilterToolCase() {
        let filter1: SidebarFilter = .tool(.claude)
        let filter2: SidebarFilter = .tool(.claude)
        let filter3: SidebarFilter = .tool(.cursor)

        XCTAssertEqual(filter1, filter2)
        XCTAssertNotEqual(filter1, filter3)
    }

    func testSidebarFilterCollectionCase() {
        let filter1: SidebarFilter = .collection("Collection A")
        let filter2: SidebarFilter = .collection("Collection A")
        let filter3: SidebarFilter = .collection("Collection B")

        XCTAssertEqual(filter1, filter2)
        XCTAssertNotEqual(filter1, filter3)
    }

    func testSidebarFilterServerCase() {
        let filter1: SidebarFilter = .server("server1")
        let filter2: SidebarFilter = .server("server1")
        let filter3: SidebarFilter = .server("server2")

        XCTAssertEqual(filter1, filter2)
        XCTAssertNotEqual(filter1, filter3)
    }
}
