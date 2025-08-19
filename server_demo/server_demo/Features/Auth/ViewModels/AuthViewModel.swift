
//
//  AuthViewModel.swift
//  server_demo
//
//  Created by Google on 2025/8/19.
//

import Foundation
import Combine

// Represents the overall authentication state of the app
enum AuthState {
    case onboarding
    case signedOut
    case signedIn
}

// A simple Codable struct for the user's profile data
struct UserProfile: Codable {
    let username: String
    // Add other profile data here if needed
}

// A simple Codable struct for the user's session data
struct UserSession: Codable {
    let token: String
    let expirationDate: Date
    
    var isExpired: Bool {
        return Date() >= expirationDate
    }
}

class AuthViewModel: ObservableObject {
    
    @Published var authState: AuthState = .onboarding
    @Published var userProfile: UserProfile?
    
    // UserDefaults keys
    private let userProfileKey = "userProfileKey"
    private let userSessionKey = "userSessionKey"
    
    // Session lifetime in seconds (e.g., 2 days)
    private let sessionLifetime: TimeInterval = 2 * 24 * 60 * 60

    init() {
        checkAuthenticationState()
    }
    
    func checkAuthenticationState() {
        // Check if user is registered
        guard let profileData = UserDefaults.standard.data(forKey: userProfileKey),
              let profile = try? JSONDecoder().decode(UserProfile.self, from: profileData) else {
            self.authState = .onboarding
            self.userProfile = nil
            return
        }
        
        // User is registered, now check for a valid session
        guard let sessionData = UserDefaults.standard.data(forKey: userSessionKey),
              let session = try? JSONDecoder().decode(UserSession.self, from: sessionData) else {
            self.authState = .signedOut
            self.userProfile = nil
            return
        }
        
        // Check if the session is expired
        if session.isExpired {
            // If expired, log them out and set state to signedOut
            logout()
        } else {
            // If session is valid, user is signed in
            self.authState = .signedIn
            self.userProfile = profile // Load profile on successful session check
        }
    }
    
    /// Mocks a registration process by saving a user profile.
    func register(username: String, password_mock: String) {
        let newUserProfile = UserProfile(username: username)
        
        if let encodedProfile = try? JSONEncoder().encode(newUserProfile) {
            UserDefaults.standard.set(encodedProfile, forKey: userProfileKey)
            // After registration, user needs to log in
            self.authState = .signedOut
        }
    }
    
    /// Mocks a login process by creating and saving a session.
    func login(username: String, password_mock: String) {
        // In a real app, you would validate the password against the registered user's credentials.
        // Here, we just check if the username exists.
        guard let profileData = UserDefaults.standard.data(forKey: userProfileKey),
              let profile = try? JSONDecoder().decode(UserProfile.self, from: profileData),
              profile.username.lowercased() == username.lowercased() else {
            // Handle incorrect username error in a real app
            print("Login failed: username does not match registered profile.")
            return
        }
        
        // Create and save a new session
        let newSession = UserSession(
            token: UUID().uuidString, // Mock token
            expirationDate: Date().addingTimeInterval(sessionLifetime)
        )
        
        if let encodedSession = try? JSONEncoder().encode(newSession) {
            UserDefaults.standard.set(encodedSession, forKey: userSessionKey)
            self.authState = .signedIn
            self.userProfile = profile // Set profile on successful login
        }
    }
    
    /// Logs the user out by deleting their session.
    func logout() {
        UserDefaults.standard.removeObject(forKey: userSessionKey)
        self.authState = .signedOut
        self.userProfile = nil // Clear profile on logout
    }
}
