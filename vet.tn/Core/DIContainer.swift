//
//  DIContainer.swift
//  vet.tn
//
//  Dependency Injection Container using Swinject
//
//  NOTE: Add Swinject package dependency in Xcode:
//  File → Add Package Dependencies → https://github.com/Swinject/Swinject.git

import Foundation

#if canImport(Swinject)
import Swinject
#endif

/// Main dependency injection container for the application
final class DIContainer {
    /// Shared singleton instance
    static let shared = DIContainer()
    
    #if canImport(Swinject)
    /// The Swinject container
    let container: Container
    #else
    /// Placeholder container - Swinject not available
    /// Add Swinject package: File → Add Package Dependencies → https://github.com/Swinject/Swinject.git
    let container: Any = ()
    #endif
    
    private init() {
        #if canImport(Swinject)
        container = Container()
        setupDependencies()
        #else
        print("⚠️ Warning: Swinject not found. Add package dependency to enable dependency injection.")
        print("   File → Add Package Dependencies → https://github.com/Swinject/Swinject.git")
        #endif
    }
    
    /// Registers all dependencies in the container
    private func setupDependencies() {
        #if canImport(Swinject)
        // MARK: - Services
        registerServices()
        
        // MARK: - ViewModels
        registerViewModels()
        
        // MARK: - Managers
        registerManagers()
        #endif
    }
    
    // MARK: - Service Registration
    private func registerServices() {
        #if canImport(Swinject)
        // Auth Service - Singleton
        container.register(AuthServiceProtocol.self) { _ in
            AuthService.shared
        }.inObjectScope(.container)
        
        // Pet Service - Singleton
        container.register(PetServiceProtocol.self) { _ in
            PetService.shared
        }.inObjectScope(.container)
        
        // Booking Service - Singleton
        container.register(BookingServiceProtocol.self) { _ in
            BookingService.shared
        }.inObjectScope(.container)
        
        // Chat Service - Singleton
        container.register(ChatServiceProtocol.self) { _ in
            ChatService.shared
        }.inObjectScope(.container)
        
        // Community Service - Singleton
        container.register(CommunityServiceProtocol.self) { _ in
            CommunityService.shared
        }.inObjectScope(.container)
        
        // Notification Service - Singleton
        container.register(NotificationServiceProtocol.self) { _ in
            NotificationService.shared
        }.inObjectScope(.container)
        #endif
    }
    
    // MARK: - ViewModel Registration
    private func registerViewModels() {
        #if canImport(Swinject)
        // Session Manager - Singleton (uses AuthService.shared internally)
        container.register(SessionManager.self) { _ in
            SessionManager()
        }.inObjectScope(.container)
        
        // Pet ViewModel - New instance per use (with dependency injection)
        container.register(PetViewModel.self) { resolver in
            let petService = resolver.resolve(PetServiceProtocol.self)!
            let sessionManager = resolver.resolve(SessionManager.self)!
            return PetViewModel(petService: petService, sessionManager: sessionManager)
        }
        
        // Booking ViewModel - New instance per use (uses setSessionManager method)
        container.register(BookingViewModel.self) { resolver in
            let viewModel = BookingViewModel()
            let sessionManager = resolver.resolve(SessionManager.self)!
            viewModel.setSessionManager(sessionManager)
            return viewModel
        }
        
        // Chat ViewModel - New instance per use (uses services internally)
        container.register(ChatViewModel.self) { resolver in
            let viewModel = ChatViewModel()
            let sessionManager = resolver.resolve(SessionManager.self)!
            viewModel.sessionManager = sessionManager
            return viewModel
        }
        #endif
    }
    
    // MARK: - Manager Registration
    private func registerManagers() {
        #if canImport(Swinject)
        // FCM Manager - Singleton
        container.register(FCMManager.self) { _ in
            FCMManager.shared
        }.inObjectScope(.container)
        
        // Notification Manager - Singleton
        container.register(NotificationManager.self) { _ in
            NotificationManager.shared
        }.inObjectScope(.container)
        
        // Socket Manager - Singleton
        container.register(SocketManager.self) { _ in
            SocketManager.shared
        }.inObjectScope(.container)
        #endif
    }
}

// MARK: - Protocol Extensions for Dependency Injection
/// Protocol for AuthService to enable dependency injection
protocol AuthServiceProtocol {
    func login(email: String, password: String) async throws -> AuthResponse
    func register(
        name: String,
        email: String,
        password: String,
        captchaToken: String?,
        appVersion: String
    ) async throws -> RegisterResponse
    func google(idToken: String) async throws -> AuthResponse
    func apple(identityToken: String) async throws -> AuthResponse
    func me(accessToken: String) async throws -> AppUser
    // Add other methods as needed
}

// Note: AuthService.register has default values for captchaToken and appVersion.
// The protocol requires all parameters to match the full signature.
// When calling through the protocol, provide all parameters.
// When calling directly on AuthService, defaults are available.

extension AuthService: AuthServiceProtocol {}

// Add similar protocols for other services

/// Protocol for PetService to enable dependency injection
protocol PetServiceProtocol {
    func createPet(ownerId: String, request: CreatePetRequest, accessToken: String) async throws -> Pet
    func getPetsForOwner(ownerId: String, accessToken: String) async throws -> [Pet]
    func getPet(petId: String, accessToken: String) async throws -> Pet
    func updatePet(petId: String, request: UpdatePetRequest, accessToken: String) async throws -> Pet
    func deletePet(ownerId: String, petId: String, accessToken: String) async throws
}

protocol BookingServiceProtocol {}
protocol ChatServiceProtocol {}
protocol CommunityServiceProtocol {}
protocol NotificationServiceProtocol {}

// Extend existing services to conform to protocols
extension PetService: PetServiceProtocol {}
extension BookingService: BookingServiceProtocol {}
extension ChatService: ChatServiceProtocol {}
extension CommunityService: CommunityServiceProtocol {}
extension NotificationService: NotificationServiceProtocol {}

