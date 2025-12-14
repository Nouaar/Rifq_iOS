# Test Files Location

This directory contains unit test files for the vet.tn iOS project.

## ⚠️ Important Setup Required

These test files need to be added to a **separate test target** in Xcode:

1. **Create Test Target:**
   - In Xcode: File → New → Target...
   - Select "Unit Testing Bundle"
   - Name: `vet.tnTests`
   - Ensure it's linked to the `vet.tn` app target

2. **Add Test Files to Target:**
   - Select all files in this directory
   - In File Inspector (right panel), check "Target Membership"
   - Ensure `vet.tnTests` is checked (NOT `vet.tn`)

3. **Verify Test Target Settings:**
   - Test target should import: `@testable import vet_tn`
   - Test target should link to the main app target
   - Test target should have XCTest framework

## Files in This Directory

- `AuthServiceTests.swift` - Tests for authentication service
- `SessionManagerTests.swift` - Tests for session management

## Running Tests

After setting up the test target:

- **In Xcode:** Press `Cmd + U` or Product → Test
- **Command Line:** 
  ```bash
  xcodebuild test -scheme vet.tn -destination 'platform=iOS Simulator,name=iPhone 15'
  ```

## Note

These files are currently **NOT** part of any Xcode target. They will cause compilation errors if included in the main app target. They must be added to a separate test target as described above.

