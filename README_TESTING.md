# Testing, Linting, Documentation, and Dependency Injection Setup

This document describes the testing, linting, documentation, and dependency injection setup for the vet.tn iOS project.

## Table of Contents

1. [Unit Testing](#unit-testing)
2. [Code Linting (SwiftLint)](#code-linting-swiftlint)
3. [Documentation (Swift DocC)](#documentation-swift-docc)
4. [Dependency Injection (Swinject)](#dependency-injection-swinject)

---

## Unit Testing

### Setup

1. **Add Test Target in Xcode:**
   - Open the project in Xcode
   - Go to File → New → Target
   - Select "Unit Testing Bundle"
   - Name it "vet.tnTests"
   - Ensure it's linked to the main app target

2. **Test Files Location:**
   - Test files are located in `vet.tn/Tests/`
   - Example tests are provided:
     - `AuthServiceTests.swift` - Tests for authentication service
     - `SessionManagerTests.swift` - Tests for session management

### Running Tests

- **In Xcode:** Press `Cmd + U` or go to Product → Test
- **Command Line:** `xcodebuild test -scheme vet.tn -destination 'platform=iOS Simulator,name=iPhone 15'`

### Writing Tests

```swift
import XCTest
@testable import vet_tn

final class MyServiceTests: XCTestCase {
    var sut: MyService! // System Under Test
    
    override func setUp() {
        super.setUp()
        sut = MyService()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testExample() {
        // Given
        let input = "test"
        
        // When
        let result = sut.process(input)
        
        // Then
        XCTAssertEqual(result, "expected")
    }
}
```

---

## Code Linting (SwiftLint)

### Installation

1. **Install SwiftLint:**
   ```bash
   brew install swiftlint
   ```

2. **Verify Installation:**
   ```bash
   swiftlint version
   ```

### Configuration

- Configuration file: `.swiftlint.yml` in the project root
- The configuration includes:
  - Line length limits (120 warning, 150 error)
  - Function body length limits
  - Type body length limits
  - Custom rules and exclusions

### Usage

1. **Manual Run:**
   ```bash
   cd "/Users/nourallah/Desktop/merge test/Rifq_iOS"
   swiftlint
   ```

2. **Auto-fix:**
   ```bash
   swiftlint --fix
   ```

3. **Xcode Integration:**
   - Add `swiftlint.sh` as a "Run Script" build phase:
     - Select your target
     - Go to Build Phases
     - Click "+" → "New Run Script Phase"
     - Add: `"${SRCROOT}/swiftlint.sh"`
     - Move it before "Compile Sources"

### Rules

The project uses a customized set of SwiftLint rules. Key configurations:
- **Line Length:** 120 characters (warning), 150 (error)
- **Function Length:** 100 lines (warning), 200 (error)
- **Type Length:** 400 lines (warning), 600 (error)
- **Complexity:** 15 (warning), 20 (error)

---

## Documentation (Swift DocC)

### Overview

Swift DocC is Apple's documentation compiler that generates rich documentation from code comments.

### Writing Documentation

Use triple-slash comments (`///`) for documentation:

```swift
/// A service for managing user authentication.
///
/// The `AuthService` handles all authentication-related operations.
///
/// ## Usage
///
/// ```swift
/// let authService = AuthService.shared
/// let response = try await authService.login(email: "user@example.com", password: "password")
/// ```
///
/// - Note: All network operations are asynchronous.
/// - Important: Tokens are stored securely in the keychain.
public class AuthService {
    /// Authenticates a user with email and password.
    ///
    /// - Parameters:
    ///   - email: The user's email address
    ///   - password: The user's password
    /// - Returns: An `AuthResponse` containing user information and tokens
    /// - Throws: An `AuthError` if authentication fails
    public func login(email: String, password: String) async throws -> AuthResponse {
        // Implementation
    }
}
```

### Generating Documentation

1. **In Xcode:**
   - Product → Build Documentation
   - Documentation will open in Xcode's documentation viewer

2. **Command Line:**
   ```bash
   xcodebuild docbuild -scheme vet.tn -destination 'generic/platform=iOS'
   ```

### Documentation Structure

- Use `///` for single-line documentation
- Use `/** */` for multi-line documentation
- Use `- Parameters:`, `- Returns:`, `- Throws:` for structured information
- Use `##` for sections
- Use code blocks with ` ```swift ` for examples

---

## Dependency Injection (Swinject)

### Overview

The project uses [Swinject](https://github.com/Swinject/Swinject) for dependency injection, which helps with:
- Testability (easy to inject mocks)
- Loose coupling
- Better code organization

### Setup

1. **Add Swinject Package:**
   - In Xcode: File → Add Package Dependencies
   - URL: `https://github.com/Swinject/Swinject.git`
   - Version: Latest (2.8.x or later)

2. **Container Location:**
   - Main container: `vet.tn/Core/DIContainer.swift`

### Usage

#### Registering Dependencies

Dependencies are registered in `DIContainer.setupDependencies()`:

```swift
// Singleton registration
container.register(AuthServiceProtocol.self) { _ in
    AuthService.shared
}.inObjectScope(.container)

// Factory registration (new instance each time)
container.register(PetViewModel.self) { resolver in
    let petService = resolver.resolve(PetServiceProtocol.self)!
    let sessionManager = resolver.resolve(SessionManager.self)!
    return PetViewModel(petService: petService, sessionManager: sessionManager)
}
```

#### Resolving Dependencies

```swift
// Get a dependency
let authService = DIContainer.shared.container.resolve(AuthServiceProtocol.self)!

// Inject into ViewModel
let petViewModel = DIContainer.shared.container.resolve(PetViewModel.self)!
```

#### Using in ViewModels

```swift
class PetViewModel: ObservableObject {
    private let petService: PetServiceProtocol
    private let sessionManager: SessionManager
    
    init(petService: PetServiceProtocol, sessionManager: SessionManager) {
        self.petService = petService
        self.sessionManager = sessionManager
    }
}
```

### Migration Guide

To migrate existing code to use dependency injection:

1. **Create Protocol:**
   ```swift
   protocol AuthServiceProtocol {
       func login(email: String, password: String) async throws -> AuthResponse
   }
   ```

2. **Make Service Conform:**
   ```swift
   extension AuthService: AuthServiceProtocol {}
   ```

3. **Update ViewModels:**
   - Change from `AuthService.shared` to injected dependency
   - Add initializer that accepts protocol

4. **Register in Container:**
   - Add registration in `DIContainer.setupDependencies()`

### Testing with DI

Dependency injection makes testing easier:

```swift
func testLogin() {
    // Create mock
    let mockAuthService = MockAuthService()
    
    // Inject into ViewModel
    let viewModel = LoginViewModel(authService: mockAuthService)
    
    // Test
    viewModel.login(email: "test@example.com", password: "password")
    
    // Verify
    XCTAssertTrue(mockAuthService.loginCalled)
}
```

---

## Best Practices

### Testing
- Write tests for business logic first
- Use dependency injection for testability
- Mock external dependencies (network, storage)
- Aim for >70% code coverage

### Linting
- Run SwiftLint before committing
- Fix warnings in new code
- Gradually fix warnings in existing code
- Use `// swiftlint:disable` sparingly and with justification

### Documentation
- Document public APIs
- Include usage examples
- Document parameters, return values, and errors
- Keep documentation up to date with code changes

### Dependency Injection
- Use protocols for all services
- Prefer constructor injection
- Register dependencies in one place (DIContainer)
- Use singletons only when necessary

---

## Troubleshooting

### SwiftLint Not Found
- Install via Homebrew: `brew install swiftlint`
- Or download from: https://github.com/realm/SwiftLint

### Tests Not Running
- Ensure test target is added to scheme
- Check that `@testable import vet_tn` is used
- Verify test files are included in test target

### DocC Not Generating
- Ensure code is marked as `public` or `open`
- Check that documentation comments use `///` or `/** */`
- Build the project first: `Product → Build`

### DI Container Issues
- Ensure Swinject is added as a package dependency
- Check that protocols are properly defined
- Verify registrations are in `setupDependencies()`

---

## Additional Resources

- [SwiftLint Documentation](https://realm.github.io/SwiftLint/)
- [Swift DocC Documentation](https://www.swift.org/documentation/docc/)
- [Swinject Documentation](https://github.com/Swinject/Swinject)
- [XCTest Documentation](https://developer.apple.com/documentation/xctest)

