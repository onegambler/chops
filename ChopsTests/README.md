# Chops Test Suite

Comprehensive test suite for the Chops macOS application to prevent regressions and ensure code quality.

## Test Structure

```
ChopsTests/
├── Models/              # Unit tests for data models
│   ├── ItemKindTests.swift
│   └── ToolSourceTests.swift
├── Services/            # Unit tests for service layer
│   ├── SkillParserTests.swift
│   ├── SourceStoreTests.swift
│   ├── OneShotResponseParserTests.swift
│   └── SearchServiceTests.swift
└── Integration/         # Integration tests
    ├── SkillLifecycleTests.swift
    └── AppStateTests.swift
```

## Test Categories

### Model Tests
- **ItemKindTests**: Tests for skill types (skill, agent, rule)
- **ToolSourceTests**: Tests for tool source configurations and paths

### Service Tests
- **SkillParserTests**: Tests for parsing skill files (frontmatter, MDC, heading formats)
- **SourceStoreTests**: Tests for source management (repos, folders, installs)
- **OneShotResponseParserTests**: Tests for agent response parsing
- **SearchServiceTests**: Tests for search functionality

### Integration Tests
- **SkillLifecycleTests**: Full lifecycle tests for skills (CRUD, collections, queries)
- **AppStateTests**: Tests for app state management and UI state

## Running Tests

### From Xcode
1. Open `Chops.xcodeproj`
2. Select the `ChopsTests` scheme
3. Press `Cmd+U` to run all tests

### From Command Line
```bash
# Generate Xcode project
xcodegen generate

# Run tests
xcodebuild test \
  -project Chops.xcodeproj \
  -scheme ChopsTests \
  -destination 'platform=macOS'
```

### From CI/CD
Tests are automatically run on:
- Pull requests
- Main branch commits
- Manual workflow dispatch

## Test Coverage

The test suite covers:

✅ **Data Models**
- Item kinds (skills, agents, rules)
- Tool sources and paths
- Skill properties and metadata

✅ **Parsing**
- Frontmatter format
- MDC format
- Heading-based format
- Agent response formats (JSON, fenced blocks)

✅ **Source Management**
- Source CRUD operations
- Install tracking
- Path resolution
- Slug generation
- JSON serialization

✅ **Search & Filtering**
- Case-insensitive search
- Name/description/content matching
- Special character handling

✅ **Database Operations**
- SwiftData CRUD
- Collections
- Queries and predicates
- Favorites

✅ **State Management**
- App state initialization
- Filter changes
- Multi-selection
- Search state

## Adding New Tests

When adding new features:

1. **Unit tests** for isolated logic (parsers, utilities, models)
2. **Integration tests** for features involving multiple components
3. **Edge cases** for error handling and boundary conditions

Example test structure:
```swift
import XCTest
@testable import Chops

final class MyFeatureTests: XCTestCase {
    var sut: SystemUnderTest!

    override func setUp() {
        super.setUp()
        sut = SystemUnderTest()
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
    }

    func testFeatureBehavior() {
        // Given
        let input = "test"
        
        // When
        let result = sut.process(input)
        
        // Then
        XCTAssertEqual(result, "expected")
    }
}
```

## Test Utilities

The test suite uses:
- Temporary directories for file operations
- In-memory SwiftData containers for database tests
- Mock data for complex objects
- XCTest assertions for validation

## Continuous Improvement

As bugs are discovered:
1. Write a failing test that reproduces the bug
2. Fix the bug
3. Verify the test passes
4. Keep the test to prevent regression

## Performance Testing

For performance-critical paths, use:
```swift
func testPerformance() {
    measure {
        // Code to measure
    }
}
```

## Known Limitations

- UI tests are not included (requires separate UI test target)
- Agent CLI integration tests require installed binaries
- Remote server tests require network access
- Some tests use temporary directories (cleaned up automatically)

## Troubleshooting

**Tests fail with "Module not found"**
- Run `xcodegen generate` to regenerate the Xcode project

**SwiftData tests fail**
- Ensure schema versions are correctly defined
- Check that models are properly annotated with `@Model`

**File path tests fail**
- Tests use temporary directories, check cleanup in `tearDown()`
- Ensure paths use `NSTemporaryDirectory()` or similar

## Contributing

When adding tests:
- Follow existing naming conventions
- Group related tests with `// MARK:` comments
- Keep tests focused and independent
- Clean up resources in `tearDown()`
- Use descriptive test names (testWhatItDoes)
