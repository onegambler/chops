import XCTest
import SwiftData
@testable import Chops

@MainActor
final class SkillLifecycleTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var tempDir: URL!

    override func setUp() async throws {
        try await super.setUp()

        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let schema = Schema([
            SchemaV1.Skill.self,
            SchemaV1.SkillCollection.self,
            SchemaV1.RemoteServer.self
        ])

        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        modelContainer = try ModelContainer(for: schema, configurations: [config])
        modelContext = ModelContext(modelContainer)
    }

    override func tearDown() async throws {
        try await super.tearDown()
        modelContainer = nil
        modelContext = nil
        try? FileManager.default.removeItem(at: tempDir)
    }

    // MARK: - Skill CRUD Tests

    func testCreateSkill() throws {
        let skill = Skill(
            name: "Test Skill",
            skillDescription: "A test skill",
            content: "Test content",
            filePath: tempDir.appendingPathComponent("test.md").path,
            kind: "skill",
            toolSourcesRaw: "claude"
        )

        modelContext.insert(skill)
        try modelContext.save()

        let descriptor = FetchDescriptor<Skill>()
        let skills = try modelContext.fetch(descriptor)

        XCTAssertEqual(skills.count, 1)
        XCTAssertEqual(skills.first?.name, "Test Skill")
    }

    func testUpdateSkill() throws {
        let skill = Skill(
            name: "Original Name",
            skillDescription: "Original description",
            content: "Original content",
            filePath: tempDir.appendingPathComponent("test.md").path,
            kind: "skill",
            toolSourcesRaw: "claude"
        )

        modelContext.insert(skill)
        try modelContext.save()

        skill.name = "Updated Name"
        skill.skillDescription = "Updated description"
        try modelContext.save()

        let descriptor = FetchDescriptor<Skill>()
        let skills = try modelContext.fetch(descriptor)

        XCTAssertEqual(skills.first?.name, "Updated Name")
        XCTAssertEqual(skills.first?.skillDescription, "Updated description")
    }

    func testDeleteSkill() throws {
        let skill = Skill(
            name: "To Delete",
            skillDescription: "Will be deleted",
            content: "Content",
            filePath: tempDir.appendingPathComponent("test.md").path,
            kind: "skill",
            toolSourcesRaw: "claude"
        )

        modelContext.insert(skill)
        try modelContext.save()

        modelContext.delete(skill)
        try modelContext.save()

        let descriptor = FetchDescriptor<Skill>()
        let skills = try modelContext.fetch(descriptor)

        XCTAssertEqual(skills.count, 0)
    }

    // MARK: - Skill Properties Tests

    func testSkillToolSources() throws {
        let skill = Skill(
            name: "Multi-tool Skill",
            skillDescription: "Works with multiple tools",
            content: "Content",
            filePath: tempDir.appendingPathComponent("test.md").path,
            kind: "skill",
            toolSourcesRaw: "claude,cursor,codex"
        )

        XCTAssertEqual(skill.toolSources.count, 3)
        XCTAssertTrue(skill.toolSources.contains(.claude))
        XCTAssertTrue(skill.toolSources.contains(.cursor))
        XCTAssertTrue(skill.toolSources.contains(.codex))
    }

    func testSkillItemKind() throws {
        let skill = Skill(
            name: "Agent Skill",
            skillDescription: "Agent type",
            content: "Content",
            filePath: tempDir.appendingPathComponent("agent.md").path,
            kind: "agent",
            toolSourcesRaw: "claude"
        )

        XCTAssertEqual(skill.itemKind, .agent)
        XCTAssertEqual(skill.displayTypeName, "Agent")
    }

    func testSkillFavorite() throws {
        let skill = Skill(
            name: "Favorite Skill",
            skillDescription: "A favorite",
            content: "Content",
            filePath: tempDir.appendingPathComponent("fav.md").path,
            kind: "skill",
            toolSourcesRaw: "claude"
        )

        XCTAssertFalse(skill.isFavorite)

        skill.isFavorite = true
        try modelContext.save()

        let descriptor = FetchDescriptor<Skill>()
        let skills = try modelContext.fetch(descriptor)

        XCTAssertTrue(skills.first?.isFavorite ?? false)
    }

    // MARK: - Collection Tests

    func testSkillCollections() throws {
        let collection1 = SkillCollection(name: "Collection 1", icon: "folder")
        let collection2 = SkillCollection(name: "Collection 2", icon: "folder")

        let skill = Skill(
            name: "Skill with Collections",
            skillDescription: "In multiple collections",
            content: "Content",
            filePath: tempDir.appendingPathComponent("skill.md").path,
            kind: "skill",
            toolSourcesRaw: "claude"
        )

        modelContext.insert(collection1)
        modelContext.insert(collection2)
        modelContext.insert(skill)

        skill.collections.append(collection1)
        skill.collections.append(collection2)

        try modelContext.save()

        XCTAssertEqual(skill.collections.count, 2)
        XCTAssertTrue(skill.collections.contains { $0.name == "Collection 1" })
        XCTAssertTrue(skill.collections.contains { $0.name == "Collection 2" })
    }

    func testRemoveSkillFromCollection() throws {
        let collection = SkillCollection(name: "Test Collection", icon: "folder")
        let skill = Skill(
            name: "Test Skill",
            skillDescription: "Test",
            content: "Content",
            filePath: tempDir.appendingPathComponent("test.md").path,
            kind: "skill",
            toolSourcesRaw: "claude"
        )

        modelContext.insert(collection)
        modelContext.insert(skill)

        skill.collections.append(collection)
        try modelContext.save()

        XCTAssertEqual(skill.collections.count, 1)

        skill.collections.removeAll { $0.name == "Test Collection" }
        try modelContext.save()

        XCTAssertEqual(skill.collections.count, 0)
    }

    // MARK: - Query Tests

    func testFetchSkillsByKind() throws {
        let skill1 = Skill(
            name: "Skill 1",
            skillDescription: "Skill type",
            content: "Content",
            filePath: tempDir.appendingPathComponent("skill1.md").path,
            kind: "skill",
            toolSourcesRaw: "claude"
        )

        let agent1 = Skill(
            name: "Agent 1",
            skillDescription: "Agent type",
            content: "Content",
            filePath: tempDir.appendingPathComponent("agent1.md").path,
            kind: "agent",
            toolSourcesRaw: "claude"
        )

        modelContext.insert(skill1)
        modelContext.insert(agent1)
        try modelContext.save()

        var descriptor = FetchDescriptor<Skill>()
        descriptor.predicate = #Predicate { $0.kind == "skill" }
        let skills = try modelContext.fetch(descriptor)

        XCTAssertEqual(skills.count, 1)
        XCTAssertEqual(skills.first?.name, "Skill 1")
    }

    func testFetchFavoriteSkills() throws {
        let skill1 = Skill(
            name: "Favorite",
            skillDescription: "Fav",
            content: "Content",
            filePath: tempDir.appendingPathComponent("fav.md").path,
            kind: "skill",
            toolSourcesRaw: "claude"
        )
        skill1.isFavorite = true

        let skill2 = Skill(
            name: "Not Favorite",
            skillDescription: "Regular",
            content: "Content",
            filePath: tempDir.appendingPathComponent("regular.md").path,
            kind: "skill",
            toolSourcesRaw: "claude"
        )

        modelContext.insert(skill1)
        modelContext.insert(skill2)
        try modelContext.save()

        var descriptor = FetchDescriptor<Skill>()
        descriptor.predicate = #Predicate { $0.isFavorite == true }
        let favorites = try modelContext.fetch(descriptor)

        XCTAssertEqual(favorites.count, 1)
        XCTAssertEqual(favorites.first?.name, "Favorite")
    }
}
