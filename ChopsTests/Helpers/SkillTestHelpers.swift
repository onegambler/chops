import Foundation
@testable import Chops

// Test-only convenience initializer for Skill with simplified parameter order
extension Skill {
    convenience init(
        name: String,
        skillDescription: String,
        content: String,
        filePath: String,
        kind: String,
        toolSourcesRaw: String
    ) {
        // Parse kind
        let itemKind = ItemKind(rawValue: kind) ?? .skill

        // Parse tool source - just use first one or custom
        let toolSource = toolSourcesRaw.split(separator: ",")
            .first
            .flatMap { ToolSource(rawValue: String($0)) } ?? .custom

        // Call real init
        self.init(
            filePath: filePath,
            toolSource: toolSource,
            name: name,
            skillDescription: skillDescription,
            content: content,
            kind: itemKind
        )

        // Set toolSourcesRaw manually after init
        self.toolSourcesRaw = toolSourcesRaw
    }
}
