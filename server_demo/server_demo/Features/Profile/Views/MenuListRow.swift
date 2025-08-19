
//
//  MenuListRow.swift
//  server_demo
//
//  Created by Google on 2025/8/19.
//

import SwiftUI

struct MenuListRow: View {
    let icon: String
    let title: String
    var subtitle: String?
    var showChevron: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .frame(width: 25)
                    .foregroundColor(.gray)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16))
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                if showChevron {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            
            Divider()
                .padding(.leading, 50)
        }
    }
}
