
//
//  RegistrationView.swift
//  server_demo
//
//  Created by Google on 2025/8/19.
//

import SwiftUI

struct RegistrationView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("创建账户")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 40)
            
            TextField("用户名", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            SecureField("密码", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            SecureField("确认密码", text: $confirmPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            // Basic password confirmation validation
            if !password.isEmpty && !confirmPassword.isEmpty && password != confirmPassword {
                Text("密码不匹配")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            Button(action: {
                // Perform registration
                authViewModel.register(username: username, password_mock: password)
            }) {
                Text("注册")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(password == confirmPassword && !password.isEmpty ? Color.blue : Color.gray)
                    .cornerRadius(10)
            }
            .disabled(password != confirmPassword || password.isEmpty)
            .padding(.top, 20)
            
            Button(action: {
                // Switch to login view
                authViewModel.authState = .signedOut
            }) {
                Text("已有账户？登录")
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
    }
}
