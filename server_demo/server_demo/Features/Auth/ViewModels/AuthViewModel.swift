
//
//  AuthViewModel.swift
//  server_demo
//
//  Created by Google on 2025/8/19.
//
//  MODIFIED: Replaced mock UserDefaults logic with live API calls to a local Flask server.
//  MODIFIED: Added persistence of login state using UserDefaults with expiration logic.
//

import Foundation
import Combine

// Represents the overall authentication state of the app
enum AuthState {
    case signedOut
    case signedIn
}

// MARK: - API Data Models

// User object to hold user data after successful login
struct CurrentUser {
    let userId: Int
    let username: String
}

// Request body for login and registration
struct AuthRequest: Codable {
    let username: String
    let password: String
}

// Generic response for error messages
struct ErrorResponse: Codable {
    let status: String
    let message: String
}

// Response body for a successful login
struct LoginResponse: Codable {
    let status: String
    let message: String
    let user_id: Int
    let username: String
}

// Response body for a successful registration
struct RegisterResponse: Codable {
    let status: String
    let message: String
    let user_id: Int
}


// MARK: - AuthViewModel

@MainActor
class AuthViewModel: ObservableObject {
    
    @Published var authState: AuthState = .signedOut
    @Published var currentUser: CurrentUser?
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    // Use 127.0.0.1 for the iOS simulator. For a real device, use your computer's local network IP.
    //private let baseURL = "http://127.0.0.1:8000/api"
    private let baseURL = "http://10.93.5.1:8000/api"

    private let userDefaultsUserIdKey = "persistedUserId"
    private let userDefaultsUsernameKey = "persistedUsername"
    private let userDefaultsExpirationDateKey = "persistedExpirationDate"

    init() {
        // Attempt to load persisted user on app launch
        if let userId = UserDefaults.standard.object(forKey: userDefaultsUserIdKey) as? Int,
           let username = UserDefaults.standard.string(forKey: userDefaultsUsernameKey),
           let expirationDate = UserDefaults.standard.object(forKey: userDefaultsExpirationDateKey) as? Date {
            
            if Date() < expirationDate { // Check if session is still valid
                self.currentUser = CurrentUser(userId: userId, username: username)
                self.authState = .signedIn
            } else {
                // Session expired, clear data
                clearPersistedUserData()
            }
        }
    }
    
    // MARK: - Public API
    
    /// Registers a new user with the server.
    /// Registers a new user with the server.
    func register(username: String, password: String) async {
        guard !username.isEmpty, !password.isEmpty else {
            self.errorMessage = "Username and password cannot be empty."
            return
        }
        
        await performAuthRequest(
            endpoint: "/register",
            authRequest: AuthRequest(username: username, password: password),
            responseType: RegisterResponse.self
        ) { [weak self] response in
            guard let self = self else { return }
            
            print("Registration successful for user ID: \(response.user_id)")
            
            // 注册成功后直接创建用户会话（模拟登录）
            self.currentUser = CurrentUser(userId: response.user_id, username: username)
            self.authState = .signedIn
            
            // 计算过期时间（7天后）
            let expirationDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
            
            // 持久化用户数据
            UserDefaults.standard.set(response.user_id, forKey: self.userDefaultsUserIdKey)
            UserDefaults.standard.set(username, forKey: self.userDefaultsUsernameKey)
            UserDefaults.standard.set(expirationDate, forKey: self.userDefaultsExpirationDateKey)
            
            self.errorMessage = nil // 清除错误信息
        }
    }
    
    /// Logs in an existing user.
    func login(username: String, password: String) async {
        guard !username.isEmpty, !password.isEmpty else {
            self.errorMessage = "Username and password cannot be empty."
            return
        }
        
        await performAuthRequest(
            endpoint: "/login",
            authRequest: AuthRequest(username: username, password: password),
            responseType: LoginResponse.self
        ) { response in
            self.currentUser = CurrentUser(userId: response.user_id, username: response.username)
            self.authState = .signedIn
            
            // Calculate expiration date (7 days from now)
            let expirationDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
            
            // Persist user data to UserDefaults
            UserDefaults.standard.set(response.user_id, forKey: self.userDefaultsUserIdKey)
            UserDefaults.standard.set(response.username, forKey: self.userDefaultsUsernameKey)
            UserDefaults.standard.set(expirationDate, forKey: self.userDefaultsExpirationDateKey)
            
            self.errorMessage = nil // Clear previous errors
        }
    }
    
    /// Logs the user out by clearing local state.
    func logout() {
        self.currentUser = nil
        self.authState = .signedOut
        
        clearPersistedUserData()
    }
    
    // MARK: - Private Helper
    
    private func clearPersistedUserData() {
        UserDefaults.standard.removeObject(forKey: self.userDefaultsUserIdKey)
        UserDefaults.standard.removeObject(forKey: self.userDefaultsUsernameKey)
        UserDefaults.standard.removeObject(forKey: self.userDefaultsExpirationDateKey)
    }
    
    /// A generic helper function to perform authentication network requests.
    private func performAuthRequest<T: Decodable>(
        endpoint: String,
        authRequest: AuthRequest,
        responseType: T.Type,
        onSuccess: @escaping (T) -> Void
    ) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        guard let url = URL(string: baseURL + endpoint) else {
            errorMessage = "Invalid server URL."
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(authRequest)
        } catch {
            errorMessage = "Failed to encode request: \(error.localizedDescription)"
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                errorMessage = "Invalid response from server."
                return
            }
            
            if (200...299).contains(httpResponse.statusCode) {
                let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                onSuccess(decodedResponse)
            } else {
                let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
                errorMessage = errorResponse?.message ?? "An unknown error occurred."
            }
        } catch {
            errorMessage = "Network request failed: \(error.localizedDescription)"
        }
    }
}
