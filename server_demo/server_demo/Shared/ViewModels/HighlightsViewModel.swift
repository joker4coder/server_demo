
//
//  HighlightsViewModel.swift
//  server_demo
//
//  Created by Google on 2025/8/19.
//

import Foundation
import Combine
import Photos

class HighlightsViewModel: ObservableObject {
    @Published var highlightRecords: [AnalysisRecord] = []
    
    private let recordsKey = "highlightAnalysisRecords"
    
    init() {
        fetchHighlights()
    }
    
    // Load data from UserDefaults
    func fetchHighlights() {
        guard let savedRecordsData = UserDefaults.standard.data(forKey: recordsKey) else { return }
        let decoder = JSONDecoder()
        if let savedRecords = try? decoder.decode([AnalysisRecord].self, from: savedRecordsData) {
            DispatchQueue.main.async {
                self.highlightRecords = savedRecords
            }
        }
    }
    
    // Add a new record and save
    func addHighlight(_ record: AnalysisRecord) {
        // Insert new record at the beginning of the list
        highlightRecords.insert(record, at: 0)
        saveHighlights()
    }
    
    // Save data to UserDefaults
    private func saveHighlights() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(highlightRecords) {
            UserDefaults.standard.set(encoded, forKey: recordsKey)
        }
    }
    
    func deleteAssets(at offsets: IndexSet) {
        let recordsToDelete = offsets.map { highlightRecords[$0] }
        let assetIDsToDelete = recordsToDelete.compactMap { $0.localIdentifier }
        
        guard !assetIDsToDelete.isEmpty else { return }
        
        PHPhotoLibrary.shared().performChanges({
            let assets = PHAsset.fetchAssets(withLocalIdentifiers: assetIDsToDelete, options: nil)
            PHAssetChangeRequest.deleteAssets(assets)
        }) { success, error in
            if success {
                DispatchQueue.main.async {
                    self.highlightRecords.remove(atOffsets: offsets)
                    self.saveHighlights()
                }
            } else {
                print("Error deleting assets: \(error?.localizedDescription ?? "Unknown error")")  }
        }
    }
}
