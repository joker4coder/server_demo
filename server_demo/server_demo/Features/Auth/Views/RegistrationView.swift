//
//  RegistrationView.swift
//  server_demo
//
//  Created by Google on 2025/8/19.
//
//  MODIFIED: Connected UI to the new async AuthViewModel, adding loading and error states.
//  MODIFIED: Added automatic navigation to home after successful registration
//

import SwiftUI

struct RegistrationView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss // 用于关闭注册页面
    
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    var isFormValid: Bool {
        !username.isEmpty && !password.isEmpty && password == confirmPassword
    }
    
    var body: some View {
        ZStack {
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
                
                if !password.isEmpty && !confirmPassword.isEmpty && password != confirmPassword {
                    Text("密码不匹配")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                // Show error message from the ViewModel
                if let errorMessage = authViewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.top)
                }
                
                Button(action: {
                    Task {
                        await authViewModel.register(username: username, password: password)
                        // 注册成功后，authState 会变为 .signedIn，触发导航
                    }
                }) {
                    Text("注册")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.blue : Color.gray)
                        .cornerRadius(10)
                }
                .disabled(!isFormValid || authViewModel.isLoading)
                .padding(.top, 20)
                
                Button(action: {
                    authViewModel.errorMessage = nil
                    dismiss() // 关闭注册页面，返回登录页面
                }) {
                    Text("已有账户？登录")
                        .foregroundColor(.blue)
                }
                
                Spacer()
            }
            .padding()
            .disabled(authViewModel.isLoading)
            
            // Loading indicator overlay
            if authViewModel.isLoading {
                ProgressView("正在注册...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(10)
            }
        }
        // 监听认证状态变化，注册成功后自动跳转
        .onChange(of: authViewModel.authState) { newState in
            if newState == .signedIn {
                dismiss() // 注册成功并登录后，关闭注册页面
            }
        }
        // 监听错误信息，如果有错误则停止加载
        .onChange(of: authViewModel.errorMessage) { errorMessage in
            if errorMessage != nil {
                // 如果有错误，可以在这里处理一些UI状态
            }
        }
    }
}
