
//
//  CustomSplashScreenView.swift
//  server_demo
//
//  Created by Google on 2025/8/19.
//

import SwiftUI

struct CustomSplashScreenView: View {
    @State private var isActive = false

    // Animation state properties
    @State private var ballScale: CGFloat = 0.1
    @State private var ballOpacity: Double = 1.0
    @State private var backgroundBlur: CGFloat = 0
    @State private var gridOpacity: Double = 0
    @State private var logoOpacity: Double = 0
    @State private var logoScale: CGFloat = 0.8

    var body: some View {
        ZStack {
            if isActive {
                AppLaunchView()
            } else {
                ZStack {
                    // 1. Background
                    LinearGradient(
                        gradient: Gradient(colors: [Color.green.opacity(0.4), Color.green.opacity(0.8)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .blur(radius: backgroundBlur)
                    .ignoresSafeArea()

                    // 2. Ball
                    Image(systemName: "soccerball.inverse")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 300, height: 300)
                        .scaleEffect(ballScale)
                        .opacity(ballOpacity)
                        .shadow(color: .white.opacity(0.7), radius: 20, x: 0, y: 0) // Glow effect

                    // 3. AI Grid Overlay
                    Circle()
                        .stroke(Color.white.opacity(gridOpacity * 0.5), lineWidth: 2)
                        .frame(width: 300 * ballScale, height: 300 * ballScale)
                        .overlay(
                            Image(systemName: "plus")
                                .font(.largeTitle)
                                .foregroundColor(.white)
                                .opacity(gridOpacity)
                        )

                    // 4. Logo
                    Text("VisionPlay")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                }
                .onAppear(perform: startAnimationSequence)
            }
        }
    }

    func startAnimationSequence() {
        // Stage 1: Ball flies in (0s - 1.2s)
        withAnimation(.easeIn(duration: 1.2)) {
            ballScale = 1.0
            backgroundBlur = 10
        }

        // Stage 2: Show scanning grid (1.2s - 1.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeOut(duration: 0.3)) {
                gridOpacity = 1.0
            }
        }

        // Stage 3: Transition to Logo (1.5s - 1.8s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeIn(duration: 0.3)) {
                ballOpacity = 0
                gridOpacity = 0
                logoOpacity = 1
                logoScale = 1.0
            }
        }

        // Stage 4: Finish and transition to app (2.0s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation {
                isActive = true
            }
        }
    }
}
