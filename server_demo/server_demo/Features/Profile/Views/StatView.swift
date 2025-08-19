
//
//  StatView.swift
//  server_demo
//
//  Created by Google on 2025/8/19.
//

import SwiftUI

struct StatView: View {
    let number: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(number)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
    }
}
