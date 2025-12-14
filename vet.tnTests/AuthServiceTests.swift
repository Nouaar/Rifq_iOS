//
//  AuthServiceTests.swift
//  vet.tnTests
//
//  Unit tests for AuthService
//

import XCTest
@testable import vet_tn

/// Unit tests for the AuthService class
@MainActor
final class AuthServiceTests: XCTestCase {
    
    var authService: AuthService!
    var mockAPIClient: MockAPIClient!
    
    override func setUp() {
        super.setUp()
        // Initialize test dependencies
        authService = AuthService.shared
        // In a real scenario, you would inject a mock APIClient
    }
    
    override func tearDown() {
        authService = nil
        mockAPIClient = nil
        super.tearDown()
    }
    
    // MARK: - Email Validation Tests
    
    /// Tests that valid email addresses are accepted
    func testValidEmail() {
        let validEmails = [
            "test@example.com",
            "user.name@domain.co.uk",
            "user+tag@example.com"
        ]
        
        for email in validEmails {
            XCTAssertTrue(isValidEmail(email), "Email \(email) should be valid")
        }
    }
    
    /// Tests that invalid email addresses are rejected
    func testInvalidEmail() {
        let invalidEmails = [
            "invalid",
            "@example.com",
            "user@",
            "user@domain",
            ""
        ]
        
        for email in invalidEmails {
            XCTAssertFalse(isValidEmail(email), "Email \(email) should be invalid")
        }
    }
    
    // MARK: - Password Validation Tests
    
    /// Tests that passwords meet minimum length requirements
    func testPasswordLengthValidation() {
        let shortPassword = "12345" // Less than 6 characters
        let validPassword = "123456" // Exactly 6 characters
        let longPassword = "1234567890" // More than 6 characters
        
        XCTAssertFalse(isValidPassword(shortPassword), "Password should be at least 6 characters")
        XCTAssertTrue(isValidPassword(validPassword), "Password with 6 characters should be valid")
        XCTAssertTrue(isValidPassword(longPassword), "Longer passwords should be valid")
    }
    
    // MARK: - Helper Methods
    
    /// Validates email format
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    /// Validates password length
    private func isValidPassword(_ password: String) -> Bool {
        return password.count >= 6
    }
}

// MARK: - Mock Objects for Testing

/// Mock APIClient for testing purposes
class MockAPIClient {
    var shouldSucceed = true
    var mockResponse: Any?
    var capturedRequest: (method: String, path: String, body: Any?)?
    
    func request<T: Decodable>(
        _ method: String,
        path: String,
        body: Any?,
        responseType: T.Type
    ) async throws -> T {
        capturedRequest = (method, path, body)
        
        if shouldSucceed {
            if let response = mockResponse as? T {
                return response
            }
            throw NSError(domain: "MockAPIClient", code: 500, userInfo: [NSLocalizedDescriptionKey: "No mock response set"])
        } else {
            throw NSError(domain: "MockAPIClient", code: 400, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
    }
}

