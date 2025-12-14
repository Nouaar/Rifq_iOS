//
//  DocumentationExample.swift
//  vet.tn
//
//  Example demonstrating Swift DocC documentation
//

import Foundation

/// A service for managing user authentication.
///
/// The `AuthService` handles all authentication-related operations including
/// login, registration, and token management. It communicates with the backend
/// API to authenticate users and manage their sessions.
///
/// ## Usage
///
/// ```swift
/// let authService = AuthService.shared
/// let response = try await authService.login(email: "user@example.com", password: "password")
/// ```
///
/// ## Topics
///
/// ### Authentication
/// - ``login(email:password:)``
/// - ``register(name:email:password:captchaToken:)``
/// - ``logout(refreshToken:)``
///
/// ### Token Management
/// - ``refresh(refreshToken:)``
/// - ``me(accessToken:)``
///
/// - Note: All network operations are asynchronous and should be called with `await`.
/// - Important: Tokens are stored securely in the keychain.
public class AuthServiceDocumentation {
    
    /// Authenticates a user with email and password.
    ///
    /// This method sends a login request to the backend API and returns
    /// authentication tokens upon successful authentication.
    ///
    /// - Parameters:
    ///   - email: The user's email address
    ///   - password: The user's password
    ///
    /// - Returns: An `AuthResponse` containing user information and tokens
    ///
    /// - Throws: An `AuthError` if authentication fails, or a network error
    ///   if the request cannot be completed.
    ///
    /// ## Example
    ///
    /// ```swift
    /// do {
    ///     let response = try await login(email: "user@example.com", password: "password123")
    ///     print("Logged in as: \(response.user.name)")
    /// } catch {
    ///     print("Login failed: \(error)")
    /// }
    /// ```
    ///
    /// - Note: The password should be at least 6 characters long.
    /// - Warning: Never log or store passwords in plain text.
    public func login(email: String, password: String) async throws -> String {
        // Implementation would go here
        return "token"
    }
    
    /// Registers a new user account.
    ///
    /// Creates a new user account with the provided information. The user
    /// will need to verify their email address before they can fully use the app.
    ///
    /// - Parameters:
    ///   - name: The user's full name
    ///   - email: The user's email address (must be unique)
    ///   - password: The user's password (minimum 6 characters)
    ///   - captchaToken: Optional CAPTCHA token for bot protection
    ///
    /// - Returns: A `RegisterResponse` indicating success and whether email verification is required
    ///
    /// - Throws: An `AuthError` if registration fails (e.g., email already exists)
    ///
    /// ## Example
    ///
    /// ```swift
    /// let response = try await register(
    ///     name: "John Doe",
    ///     email: "john@example.com",
    ///     password: "securePassword123"
    /// )
    /// if response.verificationRequired == true {
    ///     // Navigate to email verification screen
    /// }
    /// ```
    public func register(name: String, email: String, password: String, captchaToken: String? = nil) async throws -> String {
        // Implementation would go here
        return "success"
    }
}

/// Errors that can occur during authentication operations.
///
/// Use this enum to handle different types of authentication errors
/// that may occur when interacting with the `AuthService`.
public enum AuthDocumentationError: LocalizedError {
    /// The provided email address is invalid.
    case invalidEmail
    
    /// The password does not meet the minimum requirements.
    case invalidPassword
    
    /// The email address is already registered.
    case emailAlreadyExists
    
    /// The provided credentials are incorrect.
    case invalidCredentials
    
    /// The user's email address has not been verified.
    case emailNotVerified
    
    public var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "The email address is not valid."
        case .invalidPassword:
            return "The password must be at least 6 characters long."
        case .emailAlreadyExists:
            return "An account with this email already exists."
        case .invalidCredentials:
            return "The email or password is incorrect."
        case .emailNotVerified:
            return "Please verify your email address before signing in."
        }
    }
}

