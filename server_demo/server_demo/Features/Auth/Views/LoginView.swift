
//
//  LoginView.swift
//  server_demo
//
//  Created by Google on 2025/8/19.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var username = ""
    @State private var password = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Visionplay")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 40)
            
            TextField("用户名", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            SecureField("密码", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button(action: {
                // Perform login
                authViewModel.login(username: username, password_mock: password)
            }) {
                Text("登录")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 0.2, green: 0.6, blue: 0.1, opacity: 1.0))
                    .cornerRadius(10)
            }
            .padding(.top, 20)
            
            Button(action: {
                // Switch to registration view
                authViewModel.authState = .onboarding
            }) {
                Text("还没有账户？注册")
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
    }
}
