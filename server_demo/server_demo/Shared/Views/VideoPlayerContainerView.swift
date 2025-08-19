
//
//  VideoPlayerContainerView.swift
//  server_demo
//
//  Created by Google on 2025/8/19.
//

import SwiftUI
import Photos

struct VideoPlayerContainerView: View {
    let localIdentifier: String
    @State private var asset: PHAsset?
    
    var body: some View {
        if let asset = asset {
            VideoPlayerView(asset: asset)
        } else {
            ProgressView("正在加载视频...")
                .navigationTitle("加载中...")
                .onAppear {
                    // When the view appears, get the PHAsset from the local identifier
                    let assets = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
                    if let fetchedAsset = assets.firstObject {
                        self.asset = fetchedAsset
                    }
                }
        }
    }
}
