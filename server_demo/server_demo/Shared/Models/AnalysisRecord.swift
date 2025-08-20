
//
//  AnalysisRecord.swift
//  server_demo
//
//  Created by Google on 2025/8/19.
//

import Foundation

// AnalysisRecord is now Codable for storage and retrieval
struct AnalysisRecord: Identifiable, Codable {
    let id = UUID()
    let title: String
    let date: String
    let location: String
    let status: AnalysisStatus
    let thumbnail: String? // Local identifier
    let duration: Double
    let videoURL: String // Added
    let analysisSummary: String // Added
    let analysisDate: Date // Added
    let localIdentifier: String? // Optional local identifier
    
    // CodingKeys required for Codable protocol
    enum CodingKeys: String, CodingKey {
        case id, title, date, location, status, thumbnail, duration, videoURL, analysisSummary, analysisDate, localIdentifier
    }
}

// AnalysisStatus is now Codable
enum AnalysisStatus: String, Codable {
    case completed
    case processing
}
