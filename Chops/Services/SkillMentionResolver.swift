import Foundation

struct SkillPromptContext {
    let name: String
    let path: String
    let content: String
}

struct SkillMentionResolution {
    let expandedPrompt: String
    let contexts: [SkillPromptContext]
    let unresolved: [String]
}

enum SkillMentionResolver {
    static func candidates(for agentID: AgentID?, skills: [Skill]) -> [Skill] {
        guard let agentID else { return [] }
        let tool = agentID.toolSource
        return skills
            .filter { $0.itemKind == .skill && $0.toolSources.contains(tool) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    static func resolve(prompt: String, candidates: [Skill]) -> SkillMentionResolution {
        let mentions = mentionTokens(in: prompt)
        guard !mentions.isEmpty else {
            return SkillMentionResolution(expandedPrompt: prompt, contexts: [], unresolved: [])
        }

        var contexts: [SkillPromptContext] = []
        var unresolved: [String] = []
        var seen = Set<String>()

        for mention in mentions {
            let key = String(mention.dropFirst())
            guard let skill = findSkill(named: key, in: candidates) else {
                unresolved.append(mention)
                continue
            }
            let identity = skill.resolvedPath
            guard !seen.contains(identity) else { continue }
            seen.insert(identity)

            guard let content = try? String(contentsOfFile: skill.filePath, encoding: .utf8) else {
                unresolved.append(mention)
                continue
            }
            contexts.append(SkillPromptContext(name: skill.name, path: skill.filePath, content: content))
        }

        guard !contexts.isEmpty else {
            return SkillMentionResolution(expandedPrompt: prompt, contexts: [], unresolved: unresolved)
        }

        var parts: [String] = []
        parts.append("Use these selected skills as explicit instructions for this request:")
        for context in contexts {
            parts.append("")
            parts.append("## \(context.name)")
            parts.append("Path: \(context.path)")
            parts.append("```markdown")
            parts.append(context.content)
            parts.append("```")
        }
        parts.append("")
        parts.append("User request:")
        parts.append(prompt)

        return SkillMentionResolution(
            expandedPrompt: parts.joined(separator: "\n"),
            contexts: contexts,
            unresolved: unresolved
        )
    }

    static func activeMentionQuery(in text: String) -> String? {
        guard let token = text.split(whereSeparator: \.isWhitespace).last.map(String.init),
              token.count >= 1,
              token.first == "@" || token.first == "/" else {
            return nil
        }
        let body = String(token.dropFirst())
        guard body.range(of: #"^[A-Za-z0-9_.-]*$"#, options: .regularExpression) != nil else {
            return nil
        }
        return body
    }

    static func replacingActiveMention(in text: String, with skill: Skill) -> String {
        let mention = "@\(slug(for: skill))"
        guard let range = text.rangeOfLastTokenStartingWithMention else {
            return text.isEmpty ? "\(mention) " : "\(text) \(mention) "
        }
        var updated = text
        updated.replaceSubrange(range, with: mention)
        if !updated.hasSuffix(" ") {
            updated.append(" ")
        }
        return updated
    }

    private static func mentionTokens(in prompt: String) -> [String] {
        let pattern = #"(^|\s)([@/][A-Za-z0-9_.-]+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let nsRange = NSRange(prompt.startIndex..<prompt.endIndex, in: prompt)
        return regex.matches(in: prompt, range: nsRange).compactMap { match in
            guard match.numberOfRanges >= 3,
                  let range = Range(match.range(at: 2), in: prompt) else {
                return nil
            }
            return String(prompt[range])
        }
    }

    private static func findSkill(named value: String, in candidates: [Skill]) -> Skill? {
        let needle = normalize(value)
        return candidates.first { skill in
            normalize(skill.name) == needle ||
            normalize(URL(fileURLWithPath: skill.filePath).deletingLastPathComponent().lastPathComponent) == needle
        }
    }

    private static func slug(for skill: Skill) -> String {
        normalize(URL(fileURLWithPath: skill.filePath).deletingLastPathComponent().lastPathComponent)
    }

    private static func normalize(_ value: String) -> String {
        value
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .filter { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "." || $0 == "_" }
    }
}

private extension String {
    var rangeOfLastTokenStartingWithMention: Range<String.Index>? {
        var index = endIndex
        while index > startIndex {
            let previous = self.index(before: index)
            if self[previous].isWhitespace {
                let tokenStart = index
                guard tokenStart < endIndex, self[tokenStart] == "@" || self[tokenStart] == "/" else {
                    return nil
                }
                return tokenStart..<endIndex
            }
            index = previous
        }
        guard first == "@" || first == "/" else { return nil }
        return startIndex..<endIndex
    }
}
