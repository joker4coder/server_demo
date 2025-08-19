
//
//  ServerModels.swift
//  server_demo
//
//  Created by Google on 2025/8/19.
//

import Foundation

struct HighlightsResponse: Codable {
    let highlights: [HighlightInterval]
}

struct HighlightInterval: Codable {
    let startFrame: Int
    let endFrame: Int
}

struct ServerErrorResponse: Codable {
    let error: String
}
