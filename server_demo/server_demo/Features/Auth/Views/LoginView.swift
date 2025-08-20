//
//  LoginView.swift
//  server_demo
//
//  Created by Google on 2025/8/19.
//
//  MODIFIED: Connected UI to the new async AuthViewModel, adding loading and error states.
//  MODIFIED: Added navigation to registration view
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var username = ""
    @State private var password = ""
    @State private var showRegistration = false // 控制注册页面的显示
    
    var isFormValid: Bool {
        !username.isEmpty && !password.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
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
                    
                    // Show error message from the ViewModel
                    if let errorMessage = authViewModel.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.top)
                    }
                    
                    Button(action: {
                        Task {
                            await authViewModel.login(username: username, password: password)
                        }
                    }) {
                        Text("登录")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFormValid ? Color(red: 0.2, green: 0.6, blue: 0.1, opacity: 1.0) : Color.gray)
                            .cornerRadius(10)
                    }
                    .disabled(!isFormValid || authViewModel.isLoading)
                    .padding(.top, 20)
                    
                    // 注册按钮 - 使用 NavigationLink 跳转到注册页面
                    NavigationLink(destination: RegistrationView(), isActive: $showRegistration) {
                        Button(action: {
                            showRegistration = true
                            authViewModel.errorMessage = nil // 清除错误信息
                        }) {
                            Text("创建新账户")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                .disabled(authViewModel.isLoading)
                
                // Loading indicator overlay
                if authViewModel.isLoading {
                    ProgressView("正在登录...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(10)
                }
            }
            .navigationTitle("登录")
            .navigationBarHidden(true) // 隐藏导航栏标题
        }
    }
}
