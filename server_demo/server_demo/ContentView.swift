//
//  ContentView.swift
//  server_demo
//
//  Created by Google on 2025/8/19.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            // First Tab: Home
            HomeView()
                .tabItem {
                    Label("首页", systemImage: "house")
                }
            
            // Second Tab: Analysis
            AnalysisView()
                .tabItem {
                    Label("分析", systemImage: "bolt.fill")
                }
            
            // Third Tab: My Profile
            MyProfileView()
                .tabItem {
                    Label("我的", systemImage: "person.fill")
                }
        }
    }
}