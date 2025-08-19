
//
//  AppLaunchView.swift
//  server_demo
//
//  Created by Google on 2025/8/19.
//

import SwiftUI

struct AppLaunchView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        Group {
            switch authViewModel.authState {
            case .onboarding:
                RegistrationView()
            case .signedOut:
                LoginView()
            case .signedIn:
                ContentView()
            }
        }
        .onAppear {
            // Re-check auth state every time the view appears, 
            // for cases like session expiration.
            authViewModel.checkAuthenticationState()
        }
    }
}
