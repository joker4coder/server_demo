//
//  server_demoApp.swift
//  server_demo
//
//  Created by 金啸 on 2025/8/16.
//


import SwiftUI

@main
struct server_demoApp: App {
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            AppLaunchView()
                .environmentObject(authViewModel)
        }
    }
}

