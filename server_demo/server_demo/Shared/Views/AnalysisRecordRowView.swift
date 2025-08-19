
//
//  AnalysisRecordRowView.swift
//  server_demo
//
//  Created by Google on 2025/8/19.
//

import SwiftUI
import Photos

struct AnalysisRecordRowView: View {
    let record: AnalysisRecord
    
    @State private var thumbnailImage: UIImage?
    
    var body: some View {
        // If the record is completed and has a local identifier, make it navigable
        Group {
            if let localId = record.localIdentifier, record.status == .completed {
                NavigationLink(destination: VideoPlayerContainerView(localIdentifier: localId)) {
                    contentView
                }
                .buttonStyle(PlainButtonStyle()) // Remove the default blue link style
            } else {
                contentView
            }
        }
        .onAppear {
            if let localId = record.localIdentifier {
                let assets = PHAsset.fetchAssets(withLocalIdentifiers: [localId], options: nil)
                if let asset = assets.firstObject {
                    PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: 200, height: 200), contentMode: .aspectFill, options: nil) { result, _ in
                        self.thumbnailImage = result
                    }
                }
            } else {
                // If there's no local identifier (e.g., a processing record), use a placeholder
                self.thumbnailImage = UIImage(systemName: "photo.fill")?.withTintColor(.gray, renderingMode: .alwaysOriginal)
            }
        }
    }
    
    // The reusable content view
    private var contentView: some View {
        HStack(spacing: 15) {
            // Thumbnail and playback icon
            ZStack(alignment: .bottomLeading) {
                if let image = thumbnailImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 70)
                        .cornerRadius(8)
                } else {
                    ProgressView()
                        .frame(width: 100, height: 70)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
                
                HStack(spacing: 2) {
                    Image(systemName: "play.circle.fill")
                        .foregroundColor(.white)
                    Text(String(format: "%02d:%02d", Int(record.duration / 60), Int(record.duration.truncatingRemainder(dividingBy: 60))))
                        .font(.caption2)
                        .foregroundColor(.white)
                }
                .padding(4)
                .background(.black.opacity(0.6))
                .cornerRadius(5)
                .padding(4)
            }
            
            // Text information
            VStack(alignment: .leading, spacing: 5) {
                Text(record.title)
                    .font(.headline)
                
                HStack(spacing: 4) {
                    Text(record.date)
                    Text("|")
                    Text(record.location)
                }
                .font(.subheadline)
                .foregroundColor(.gray)
                
                HStack(spacing: 4) {
                    Text(record.status == .completed ? "已完成" : "处理中")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(record.status == .completed ? Color.green : Color.blue)
                        .cornerRadius(5)
                    
                    if record.status == .completed {
                        Text("3个精彩事件 · 78%完整度")
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else {
                        Text("正在生成热力图")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Spacer()
        }
        .padding(10)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
    }
}
