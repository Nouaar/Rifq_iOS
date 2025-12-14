#!/bin/bash

# Setup script for testing, linting, documentation, and dependency injection
# Run this script to set up the development environment

set -e

echo "🚀 Setting up vet.tn iOS project..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if SwiftLint is installed
echo -e "${YELLOW}Checking SwiftLint installation...${NC}"
if ! command -v swiftlint &> /dev/null; then
    echo "⚠️  SwiftLint not found. Installing via Homebrew..."
    if command -v brew &> /dev/null; then
        brew install swiftlint
    else
        echo "❌ Homebrew not found. Please install SwiftLint manually:"
        echo "   brew install swiftlint"
        echo "   Or download from: https://github.com/realm/SwiftLint"
        exit 1
    fi
else
    echo -e "${GREEN}✓ SwiftLint is installed${NC}"
    swiftlint version
fi

# Verify SwiftLint configuration
echo -e "\n${YELLOW}Verifying SwiftLint configuration...${NC}"
if [ -f ".swiftlint.yml" ]; then
    echo -e "${GREEN}✓ .swiftlint.yml found${NC}"
else
    echo "❌ .swiftlint.yml not found"
    exit 1
fi

# Check Xcode version
echo -e "\n${YELLOW}Checking Xcode installation...${NC}"
if command -v xcodebuild &> /dev/null; then
    XCODE_VERSION=$(xcodebuild -version | head -n 1)
    echo -e "${GREEN}✓ $XCODE_VERSION${NC}"
else
    echo "❌ Xcode not found. Please install Xcode from the App Store."
    exit 1
fi

echo -e "\n${GREEN}✅ Setup complete!${NC}"
echo -e "\n${YELLOW}Next steps:${NC}"
echo "1. Open the project in Xcode"
echo "2. Add Swinject package dependency:"
echo "   - File → Add Package Dependencies"
echo "   - URL: https://github.com/Swinject/Swinject.git"
echo "   - Version: Latest"
echo "3. Add Unit Test Target:"
echo "   - File → New → Target"
echo "   - Select 'Unit Testing Bundle'"
echo "   - Name: vet.tnTests"
echo "4. Add SwiftLint build phase:"
echo "   - Select target → Build Phases"
echo "   - Click '+' → 'New Run Script Phase'"
echo "   - Add: \${SRCROOT}/swiftlint.sh"
echo "   - Move before 'Compile Sources'"
echo "5. See README_TESTING.md for detailed instructions"

