
//
//  AuthenticationView.swift
//  server_demo
//
//  Created by Gemini on 2025/8/20.
//

import SwiftUI

struct AuthenticationView: View {
    @State private var isShowingLogin = true

    var body: some View {
        VStack {
            if isShowingLogin {
                LoginView()
            } else {
                RegistrationView()
            }
            
            Button(action: {
                withAnimation {
                    isShowingLogin.toggle()
                }
            }) {
                Text(isShowingLogin ? "还没有账户？注册" : "已有账户？登录")
                    .foregroundColor(.secondary)
                    .padding(.top, 10)
            }
            
            Spacer()
        }
        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
    }
}

struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView()
            .environmentObject(AuthViewModel())
    }
}
