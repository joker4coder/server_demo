

//
//  AnalysisView.swift
//  server_demo
//
//  Created by Google on 2025/8/19.
//

import SwiftUI

struct AnalysisView: View {
    // Observe the model object for UI updates
    @StateObject private var viewModel = HighlightsViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 15) {
                    ForEach(viewModel.highlightRecords) { record in
                        AnalysisRecordRowView(record: record)
                    }
                }
                .padding()
            }
            .navigationTitle("分析")
            .onAppear {
                viewModel.fetchHighlights() // Load records when the view appears
            }
        }
    }
}

