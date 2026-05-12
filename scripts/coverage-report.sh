#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "🧪 Running tests with code coverage..."

# Clean previous results
rm -rf build/TestResults.xcresult build/coverage.json

# Run tests with coverage
xcodebuild test \
  -project Chops.xcodeproj \
  -scheme ChopsTests \
  -destination 'platform=macOS' \
  -derivedDataPath build/DerivedData \
  -enableCodeCoverage YES \
  -resultBundlePath build/TestResults.xcresult \
  CODE_SIGNING_ALLOWED=NO \
  | xcpretty || true

echo ""
echo "📊 Generating coverage report..."

# Generate JSON coverage report
xcrun xccov view --report --json build/TestResults.xcresult > build/coverage.json

# Generate text coverage report
xcrun xccov view --report build/TestResults.xcresult > build/coverage.txt

# Display summary
echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}       CODE COVERAGE SUMMARY${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""

# Extract and display coverage percentages
cat build/coverage.txt | head -50

echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""

# Check coverage threshold (optional - set to 0 for now)
THRESHOLD=0
COVERAGE=$(xcrun xccov view --report build/TestResults.xcresult | grep "Chops.app" | awk '{print $3}' | sed 's/%//' || echo "0")

if [ -n "$COVERAGE" ] && [ "$COVERAGE" != "0" ]; then
    echo "Overall Coverage: ${COVERAGE}%"
    if (( $(echo "$COVERAGE < $THRESHOLD" | bc -l) )); then
        echo -e "${RED}⚠️  Coverage ${COVERAGE}% is below threshold ${THRESHOLD}%${NC}"
        # Uncomment to fail on low coverage:
        # exit 1
    else
        echo -e "${GREEN}✅ Coverage ${COVERAGE}% meets threshold${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Could not determine coverage percentage${NC}"
fi

echo ""
echo "📄 Detailed reports available:"
echo "  - JSON: build/coverage.json"
echo "  - Text: build/coverage.txt"
echo "  - Xcode: build/TestResults.xcresult"
echo ""
echo "To view in Xcode: open build/TestResults.xcresult"
