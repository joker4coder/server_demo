
//
//  PlayerPositionLabel.swift
//  server_demo
//
//  Created by Google on 2025/8/19.
//

import SwiftUI

struct PlayerPositionLabel: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.black.opacity(0.4))
            .cornerRadius(4)
    }
}
