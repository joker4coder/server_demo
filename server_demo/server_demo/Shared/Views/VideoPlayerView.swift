
//
//  VideoPlayerView.swift
//  server_demo
//
//  Created by Google on 2025/8/19.
//

import SwiftUI
import AVKit
import Photos

struct VideoPlayerView: View {
    let asset: PHAsset
    @State private var player: AVPlayer?
    @State private var hasAudio = false
    @State private var isMuted = false
    
    var body: some View {
        VStack {
            if let player = player {
                VideoPlayer(player: player)
                    .onAppear {
                        // 修复1: 配置音频会话
                        configureAudioSession()
                        player.play()
                    }
            } else {
                ProgressView("加载视频中...")
            }
            
            HStack {
                Button(action: toggleMute) {
                    Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .padding()
                }
                
                if !hasAudio {
                    Text("⚠️ 检测不到音频轨道")
                        .foregroundColor(.red)
                }
            }
        }
        .onAppear {
            loadVideoAsset()
        }
        .onDisappear {
            player?.pause()
        }
        .navigationTitle("播放视频")
    }
    
    private func loadVideoAsset() {
        let options = PHVideoRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true // 允许从iCloud加载
        
        PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
            guard let avAsset = avAsset else { return }
            
            // 检查音频轨道
            let audioTracks = avAsset.tracks(withMediaType: .audio)
            DispatchQueue.main.async {
                self.hasAudio = !audioTracks.isEmpty
                self.player = AVPlayer(playerItem: AVPlayerItem(asset: avAsset))
                
                // 修复2: 确保非静音模式
                self.player?.isMuted = false
            }
        }
    }
    
    private func configureAudioSession() {
        do {
            // 修复3: 设置音频会话类别
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .moviePlayback,
                options: [.mixWithOthers, .duckOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("音频会话配置失败: \(error.localizedDescription)")
        }
    }
    
    private func toggleMute() {
        guard let player = player else { return }
        player.isMuted.toggle()
        isMuted = player.isMuted
    }
}
