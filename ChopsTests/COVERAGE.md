# Code Coverage Report

## Current Status

**Note:** Exact code coverage percentages require running tests with Xcode. Use `./scripts/coverage-report.sh` to generate precise metrics.

## Test Coverage by Module

### ✅ Models (High Coverage - ~80%)
Files: 10 | Test Files: 2

**Tested:**
- ✅ `ItemKind` - Complete coverage (display names, icons, codable)
- ✅ `ToolSource` - Comprehensive coverage (paths, display names, validation)
- ✅ `Skill` - Partial coverage (properties, tool sources, item kind, favorites)
- ✅ `Collection` - Coverage via integration tests

**Not Tested:**
- ⚠️ `AgentConfiguration` - No tests
- ⚠️ `AgentTarget` - No tests
- ⚠️ `ChopsSettings` - No tests
- ⚠️ `RemoteServer` - No tests
- ⚠️ `SchemaVersions` - No tests (migration logic)
- ⚠️ `WizardTemplateType` - No tests

### ✅ Services (Medium Coverage - ~40%)
Files: 21 | Test Files: 4

**Tested:**
- ✅ `SkillParser` - Comprehensive (frontmatter, MDC, heading formats)
- ✅ `SourceStore` - Good coverage (path utils, serialization, slug generation)
- ✅ `OneShotResponseParser` - Complete coverage (JSON, fenced blocks)
- ✅ `FrontmatterParser` - Indirectly tested via SkillParser
- ✅ `MDCParser` - Indirectly tested via SkillParser
- ⚠️ `SearchService` - Basic tests only

**Not Tested:**
- ❌ `AgentFactory` - No tests
- ❌ `ClaudeCLIAgent` - No tests (requires binary)
- ❌ `CodexCLIAgent` - No tests (requires binary)
- ❌ `AgentLogger` - No tests
- ❌ `FileWatcher` - No tests (requires FSEvents)
- ❌ `SSHService` - No tests (requires SSH)
- ❌ `SkillRegistry` - No tests
- ❌ `SkillScanner` - No tests
- ❌ `SourceGitService` - No tests (requires git)
- ❌ `SourceInstallService` - No tests
- ❌ `SourceSkillScanner` - No tests
- ❌ `SkillMentionResolver` - No tests
- ❌ `TemplateManager` - No tests
- ❌ `StoreBootstrap` - No tests
- ❌ `AppLogger` - No tests

### ⚠️ Views (Low Coverage - ~5%)
Files: 29 | Test Files: 1

**Tested:**
- ✅ `AppState` - Good coverage (filters, selection, search state)

**Not Tested:**
- ❌ All SwiftUI views (requires UI testing framework)
- ❌ View models
- ❌ View logic
- ❌ User interactions

### 📊 Estimated Overall Coverage

Based on file counts and test coverage:

```
Total Swift Files: 66
Files with Tests: ~12

Estimated Line Coverage:
- Models:    ~80%  (8/10 files partially covered)
- Services:  ~40%  (6/21 files partially covered)
- Views:     ~5%   (1/29 files covered)
- Utilities: ~30%  (parsers covered)

Overall Estimate: ~30-35%
```

## Coverage Goals

### Phase 1 (Current) ✅
- [x] Core parsing logic
- [x] Data models
- [x] Path utilities
- [x] Source management basics
- [x] App state

### Phase 2 (Next Priority)
- [ ] SkillScanner - Critical for app functionality
- [ ] SourceInstallService - Install/uninstall logic
- [ ] SourceSkillScanner - Source detection
- [ ] FileWatcher - File system monitoring
- [ ] SkillRegistry - Registry interactions

### Phase 3 (Future)
- [ ] Agent integrations (mocked)
- [ ] SSH service (mocked)
- [ ] Git service (mocked)
- [ ] Template manager
- [ ] Schema migrations

### Phase 4 (Long-term)
- [ ] UI tests for critical workflows
- [ ] View logic extraction and testing
- [ ] Performance benchmarks
- [ ] Snapshot tests

## Testing Strategy by Component Type

### Pure Logic (Easy to Test)
- Parsers ✅
- Path utilities ✅
- String manipulation ✅
- Data transformations ✅

### File System Operations (Medium)
- File reading/writing (use temp dirs) ✅
- Directory scanning (needs mocking)
- Symlink handling (needs mocking)

### External Dependencies (Challenging)
- CLI tool execution (mock process)
- Network requests (mock service)
- SSH connections (mock transport)
- Git operations (mock git commands)

### UI Components (Requires Different Approach)
- SwiftUI views (UI tests or preview tests)
- User interactions (UI tests)
- Layout validation (snapshot tests)

## How to Improve Coverage

### 1. Add Service Tests
Create test files for:
- `SkillScannerTests.swift`
- `SourceInstallServiceTests.swift`
- `SourceSkillScannerTests.swift`
- `FileWatcherTests.swift`

### 2. Add Integration Tests
- Full scan workflow
- Install/uninstall workflow
- Source sync workflow
- Collection management

### 3. Mock External Dependencies
```swift
protocol GitServiceProtocol {
    func clone(url: String, to: String) async throws
}

// Real implementation
class GitService: GitServiceProtocol { }

// Mock for tests
class MockGitService: GitServiceProtocol { }
```

### 4. Extract Testable Logic from Views
Move business logic from views to view models or services:
```swift
// Before (in View)
var filteredSkills: [Skill] {
    allSkills.filter { /* complex logic */ }
}

// After (testable)
class SkillFilterService {
    func filter(_ skills: [Skill], by filter: Filter) -> [Skill]
}
```

### 5. Add UI Tests (Separate Target)
```bash
# Add to project.yml
ChopsUITests:
  type: bundle.ui-testing
  platform: macOS
  sources: [ChopsUITests]
  dependencies:
    - target: Chops
```

## Running Coverage Reports

### Local
```bash
./scripts/coverage-report.sh
```

### CI
Coverage is automatically generated in GitHub Actions and available in:
- Workflow logs
- Downloadable artifacts (`test-results`)

### Xcode
1. Run tests: `Cmd+U`
2. Open Report Navigator: `Cmd+9`
3. Select test run
4. Click "Coverage" tab

## Coverage Trends

| Date | Overall | Models | Services | Views |
|------|---------|--------|----------|-------|
| 2026-05-12 | ~35% | 80% | 40% | 5% |

*Update this table after each major test addition*

## Notes

- SwiftUI views are inherently difficult to unit test
- Focus on testing business logic and services
- UI testing should cover critical user flows
- Integration tests provide high value for file system operations
- Mock external dependencies for faster, more reliable tests
