
//
//  AppLaunchView.swift
//  server_demo
//
//  Created by Google on 2025/8/19.
//
//  MODIFIED: Updated to use the new AuthState enum and route to AuthenticationView.
//

import SwiftUI

struct AppLaunchView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        Group {
            switch authViewModel.authState {
            case .signedOut:
                AuthenticationView()
            case .signedIn:
                ContentView()
            }
        }
    }
}
