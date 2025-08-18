//
//  ContentView.swift
//  ClientServerDemo
//
//  这是应用的根视图，包含一个 TabView，用于在主页和分析列表之间切换。
//
//  作者：Google
//  版权所有：(c) Google, Inc. 保留所有权利。
//

import SwiftUI
import PhotosUI
import AVFoundation
import CoreGraphics
import AVKit

// MARK: - Data Models

// AnalysisRecord is now Codable for storage and retrieval
struct AnalysisRecord: Identifiable, Codable {
    let id = UUID()
    let title: String
    let date: String
    let location: String
    let status: AnalysisStatus
    let thumbnail: String? // Local identifier
    let duration: Double
    let localIdentifier: String? // Optional local identifier
    
    // CodingKeys required for Codable protocol
    enum CodingKeys: String, CodingKey {
        case id, title, date, location, status, thumbnail, duration, localIdentifier
    }
}

// AnalysisStatus is now Codable
enum AnalysisStatus: String, Codable {
    case completed
    case processing
}

// MARK: - Main Views

struct ContentView: View {
    var body: some View {
        TabView {
            // First Tab: Home
            HomeView()
                .tabItem {
                    Label("首页", systemImage: "house")
                }
            
            // Second Tab: Analysis
            AnalysisView()
                .tabItem {
                    Label("分析", systemImage: "bolt.fill")
                }
            
            // Third Tab: My Profile
            MyProfileView()
                .tabItem {
                    Label("我的", systemImage: "person.fill")
                }
        }
    }
}

// MARK: - Home View (Video Upload and Recent Records)

struct HomeView: View {
    // Observe the model object for UI updates
    @StateObject private var viewModel = HighlightsViewModel()
    
    // State management
    @State private var isPickerPresented = false
    @State private var statusMessage = "点击按钮选择视频..."
    @State private var isProcessing = false
    
    // Replace with your local IP address and port
    private let serverURL = URL(string: "http://192.168.3.38:5001/upload_video")!

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Top navigation bar
                HStack {
                    Text("Visionplay")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: {
                        // Button action
                    }) {
                        Image(systemName: "gearshape")
                            .imageScale(.large)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Upload video area
                        VStack(spacing: 20) {
                            Button(action: {
                                PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                                    if status == .authorized {
                                        isPickerPresented = true
                                    } else {
                                        statusMessage = "请在“设置”中授予应用访问照片的权限。"
                                    }
                                }
                            }) {
                                if isProcessing {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .tint(.white)
                                } else {
                                    VStack(spacing: 8) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 40, weight: .bold))
                                            .foregroundColor(.white)
                                        Text("上传比赛视频")
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .frame(width: 150, height: 150)
                            .background(Color.green)
                            .clipShape(Circle())
                            .disabled(isProcessing) // Disable button when processing
                            
                            HStack(spacing: 40) {
                                Button(action: {
                                    // Photo library action
                                }) {
                                    VStack(spacing: 5) {
                                        Image(systemName: "photo.fill.on.rectangle.fill")
                                            .imageScale(.large)
                                        Text("相册")
                                    }
                                }
                                
                                Button(action: {
                                    // Camera action
                                }) {
                                    VStack(spacing: 5) {
                                        Image(systemName: "camera.fill")
                                            .imageScale(.large)
                                        Text("拍摄")
                                    }
                                }
                            }
                        }
                        .padding(.top, 40)
                        
                        // Status display text
                        Text(statusMessage)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                        
                        // Recent analysis records list
                        VStack(alignment: .leading, spacing: 15) {
                            Text("最近分析记录")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.leading)
                            
                            ForEach(viewModel.highlightRecords.prefix(2)) { record in
                                AnalysisRecordRowView(record: record)
                            }
                        }
                    }
                    .padding()
                }
            }
            .sheet(isPresented: $isPickerPresented) {
                VideoPicker(onVideoPicked: processVideo)
            }
            .onAppear {
                viewModel.fetchHighlights() // Load records when the view appears
            }
        }
    }
    
    // MARK: - Video Processing and Upload
    
    // Process the selected video URL
    private func processVideo(url: URL) {
        isProcessing = true
        statusMessage = "正在上传视频到服务器..."
        
        // Simulate an analysis record with "processing" status
        let newRecord = AnalysisRecord(title: "新视频分析", date: "今天", location: "未知", status: .processing, thumbnail: nil, duration: 0, localIdentifier: nil)
        
        Task {
            do {
                let highlights = try await uploadVideo(videoURL: url)
                
                print("服务器返回的集锦区间:")
                for (index, highlight) in highlights.enumerated() {
                    print("  片段 \(index + 1): 起始帧 \(highlight.startFrame), 结束帧 \(highlight.endFrame)")
                }
                
                statusMessage = "正在根据服务器返回的区间生成集锦视频..."
                
                // Get the original video's asset
                let asset = AVURLAsset(url: url)
                let videoTrack = try await asset.load(.tracks).first(where: { $0.mediaType == .video })
                guard let videoTrack else {
                    throw NSError(domain: "VideoError", code: 1, userInfo: [NSLocalizedDescriptionKey: "未找到视频轨道。"])
                }
                let frameRate = try await videoTrack.load(.nominalFrameRate)
                
                // Calculate the total duration of the highlights
                var totalHighlightDuration: Double = 0
                for highlight in highlights {
                    totalHighlightDuration += Double(highlight.endFrame - highlight.startFrame) / Double(frameRate)
                }
                
                // Save the video to the photo album
                let localIdentifier = try await generateHighlightVideo(originalVideoURL: url, highlights: highlights)

                // Update the record status with the correct duration
                let updatedRecord = AnalysisRecord(
                    title: "新视频集锦", // You can customize the title
                    date: Date().formatted(date: .abbreviated, time: .omitted),
                    location: "我的相册",
                    status: .completed,
                    thumbnail: localIdentifier,
                    duration: totalHighlightDuration, // Use the new duration
                    localIdentifier: localIdentifier
                )
                
                await MainActor.run {
                    viewModel.addHighlight(updatedRecord)
                    statusMessage = "视频集锦已成功保存到相册！"
                }
                
            } catch {
                await MainActor.run {
                    statusMessage = "操作失败: \(error.localizedDescription)"
                }
            }
            
            await MainActor.run {
                isProcessing = false
            }
        }
    }
    
    // Upload video to the server and get the response
    private func uploadVideo(videoURL: URL) async throws -> [HighlightInterval] {
        var request = URLRequest(url: serverURL)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var httpBody = Data()
        
        httpBody.append("--\(boundary)\r\n".data(using: .utf8)!)
        httpBody.append("Content-Disposition: form-data; name=\"video\"; filename=\"\(videoURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
        httpBody.append("Content-Type: video/mp4\r\n\r\n".data(using: .utf8)!)
        httpBody.append(try Data(contentsOf: videoURL))
        httpBody.append("\r\n".data(using: .utf8)!)
        
        httpBody.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        let (data, response) = try await URLSession.shared.upload(for: request, from: httpBody)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if httpResponse.statusCode != 200 {
            let errorResponse = try? JSONDecoder().decode(ServerErrorResponse.self, from: data)
            let errorMessage = errorResponse?.error ?? "未知的服务器错误"
            throw NSError(domain: "ServerError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        let decodedResponse = try JSONDecoder().decode(HighlightsResponse.self, from: data)
        return decodedResponse.highlights
    }
    // gen by ds 
    // Generate a highlight video with a watermark based on intervals and save to the photo album
    private func generateHighlightVideo(originalVideoURL: URL, highlights: [HighlightInterval]) async throws -> String {
        let asset = AVURLAsset(url: originalVideoURL)
        let tracks = try await asset.load(.tracks)
        let videoTrack = tracks.first(where: { $0.mediaType == .video })
        let audioTrack = tracks.first(where: { $0.mediaType == .audio })
        
        guard let videoTrack else {
            throw NSError(domain: "VideoError", code: 1, userInfo: [NSLocalizedDescriptionKey: "未找到视频轨道。"])
        }
        
        // Debugging print statements to help identify the issue
        if audioTrack != nil {
            print("原始视频有音频轨道。")
        } else {
            print("原始视频没有音频轨道，集锦视频将没有声音。")
        }
        
        let frameRate = try await videoTrack.load(.nominalFrameRate)
        let videoSize = try await videoTrack.load(.naturalSize)
        let preferredTransform = try await videoTrack.load(.preferredTransform)
        
        let videoRect = CGRect(origin: .zero, size: videoSize)
        let transformedVideoRect = videoRect.applying(preferredTransform)
        let outputSize = CGSize(width: transformedVideoRect.width, height: transformedVideoRect.height).applying(.identity)
        
        let composition = AVMutableComposition()
        let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        var compositionAudioTrack: AVMutableCompositionTrack?
        if let audioTrack = audioTrack {
            compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        }
        
        var currentTime = CMTime.zero
        var layerInstructions: [AVMutableVideoCompositionInstruction] = []
        
        let parentLayer = CALayer()
        let videoLayer = CALayer()
        parentLayer.frame = CGRect(origin: .zero, size: outputSize)
        videoLayer.frame = CGRect(origin: .zero, size: outputSize)
        
        parentLayer.addSublayer(videoLayer)
        
        for (index, highlight) in highlights.enumerated() {
            let startTime = CMTime(value: CMTimeValue(highlight.startFrame), timescale: CMTimeScale(frameRate))
            let endTime = CMTime(value: CMTimeValue(highlight.endFrame), timescale: CMTimeScale(frameRate))
            let timeRange = CMTimeRangeFromTimeToTime(start: startTime, end: endTime)
            
            // Insert video track
            try compositionVideoTrack?.insertTimeRange(timeRange, of: videoTrack, at: currentTime)
            
            // Insert audio track if it exists
            if let sourceAudioTrack = audioTrack, let compAudioTrack = compositionAudioTrack {
                do {
                    try compAudioTrack.insertTimeRange(timeRange, of: sourceAudioTrack, at: currentTime)
                } catch {
                    print("插入音频轨道时出错：\(error.localizedDescription)")
                }
            }
            
            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = CMTimeRange(start: currentTime, duration: timeRange.duration)
            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack!)
            layerInstruction.setTransform(preferredTransform, at: currentTime)
            instruction.layerInstructions = [layerInstruction]
            layerInstructions.append(instruction)
            
            let textLayer = CATextLayer()
            textLayer.string = "\(highlight.startFrame)-\(highlight.endFrame)"
            textLayer.font = CTFontCreateWithName("Helvetica-Bold" as CFString, 40, nil)
            textLayer.fontSize = 40
            textLayer.foregroundColor = UIColor.red.cgColor
            textLayer.alignmentMode = .right
            
            let attributedString = NSAttributedString(string: textLayer.string as! String, attributes: [NSAttributedString.Key.font: textLayer.font as! UIFont])
            let textSize = attributedString.boundingRect(with: CGSize(width: outputSize.width, height: .infinity), options: [.usesLineFragmentOrigin], context: nil).size
            
            let margin: CGFloat = 20
            textLayer.frame = CGRect(x: outputSize.width - textSize.width - margin, y: margin, width: textSize.width, height: textSize.height)
            
            let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
            opacityAnimation.values = [0.0, 1.0, 1.0, 0.0]
            
            let duration = timeRange.duration.seconds
            let fadeInTime = 0.5
            let fadeOutTime = duration - 0.5
            
            opacityAnimation.keyTimes = [0.0, NSNumber(value: fadeInTime / duration), NSNumber(value: fadeOutTime / duration), 1.0]
            
            opacityAnimation.beginTime = currentTime.seconds
            opacityAnimation.duration = duration
            
            opacityAnimation.isRemovedOnCompletion = false
            opacityAnimation.fillMode = .forwards
            
            textLayer.add(opacityAnimation, forKey: "textAnimation-\(index)")
            parentLayer.addSublayer(textLayer)
            
            currentTime = CMTimeAdd(currentTime, timeRange.duration)
        }
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = outputSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: CMTimeScale(frameRate))
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
        videoComposition.instructions = layerInstructions
        
        let outputURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")
        
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            throw NSError(domain: "VideoExportError", code: 2, userInfo: [NSLocalizedDescriptionKey: "无法创建导出会话。"])
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.videoComposition = videoComposition
        
        await exportSession.export()
        
        guard exportSession.status == .completed else {
            throw exportSession.error ?? NSError(domain: "VideoExportError", code: 3, userInfo: [NSLocalizedDescriptionKey: "视频导出失败。"])
        }
        
        // Save the video to the photo album and get its identifier
        let localIdentifier = try await saveVideoToPhotoLibrary(at: outputURL)
        
        try? FileManager.default.removeItem(at: outputURL)
        
        return localIdentifier
    }
    
    // Save the video to the photo album and return its local identifier
    private func saveVideoToPhotoLibrary(at url: URL) async throws -> String {
        var localIdentifier: String?
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            request?.creationDate = Date()
            localIdentifier = request?.placeholderForCreatedAsset?.localIdentifier
        }
        
        guard let identifier = localIdentifier else {
            throw NSError(domain: "PhotoLibraryError", code: 4, userInfo: [NSLocalizedDescriptionKey: "无法获取视频的本地标识符。"])
        }
        return identifier
    }
}

// MARK: - Analysis View (Full Records List)

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

// MARK: - My Profile View

struct MyProfileView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Profile Header
                    ZStack(alignment: .topLeading) {
                        Image("profile-background") // Placeholder for background image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 150)
                            .clipped()
                            .overlay(
                                LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.4), Color.clear]), startPoint: .top, endPoint: .bottom)
                            )
                        
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .bottom) {
                                Image(systemName: "person.circle.fill") // Placeholder for avatar
                                    .resizable()
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white, lineWidth: 4))
                                    .padding(.leading, 20)
                                
                                Text("小帅") // User's name
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Spacer()
                            }
                            
                            HStack(spacing: 5) {
                                Text("所属球队:")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                Text("深圳深夜鹰、深圳种子队")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                            }
                            .padding(.leading, 20)
                        }
                        .padding(.top, 20)
                    }
                    .frame(height: 150)
                    
                    // Stats Section
                    VStack(spacing: 15) {
                        HStack(spacing: 40) {
                            StatView(number: "766", label: "进球")
                            StatView(number: "68", label: "助攻")
                            StatView(number: "569", label: "出场")
                        }
                        .padding(.horizontal, 20)
                        
                        HStack {
                            Spacer()
                            Text("展开")
                            Image(systemName: "chevron.down")
                        }
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.trailing, 20)
                    }
                    .padding(.top, 20)
                    
                    // Menu List
                    VStack(spacing: 1) {
                        MenuListRow(icon: "photo.on.rectangle.angled", title: "个人集锦", subtitle: "已保存至我的视频片段", showChevron: true)
                        MenuListRow(icon: "flag.fill", title: "我的比赛", subtitle: "仅显示我参加的比赛", showChevron: true)
                        MenuListRow(icon: "person.fill", title: "球员信息", subtitle: "个人基本信息，公开展示", showChevron: true)
                        MenuListRow(icon: "lock.shield.fill", title: "实名信息", subtitle: "参加赛事时需进行实名认证", showChevron: true)
                        MenuListRow(icon: "square.grid.2x2.fill", title: "个人属性", subtitle: "初次加入球队时，此为默认属性", showChevron: true)
                        MenuListRow(icon: "list.bullet.rectangle.fill", title: "订单", showChevron: true)
                        MenuListRow(icon: "headphones", title: "客服", showChevron: true)
                        MenuListRow(icon: "gearshape.fill", title: "设置", showChevron: true)
                    }
                    .padding(.top, 20)
                }
            }
            .background(Color(.systemGray6))
            .navigationTitle("我的")
        }
    }
}

// A reusable view for a statistic
struct StatView: View {
    let number: String
    let label: String
    
    var body: some View {
        VStack(spacing: 5) {
            Text(number)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.black)
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

// A reusable view for a menu list row
struct MenuListRow: View {
    let icon: String
    let title: String
    var subtitle: String?
    var showChevron: Bool = false
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .imageScale(.large)
                .frame(width: 25)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            if showChevron {
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .imageScale(.small)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .background(Color.white)
    }
}


// MARK: - List Item View (Reusable)

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
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Video Player View

import AVFoundation // 确保已导入

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
// MARK: - Video Player Container View (for asynchronous video loading)

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

// MARK: - View Model
class HighlightsViewModel: ObservableObject {
    @Published var highlightRecords: [AnalysisRecord] = []
    
    private let recordsKey = "highlightAnalysisRecords"
    
    // Load data from UserDefaults
    func fetchHighlights() {
        if let savedRecordsData = UserDefaults.standard.data(forKey: recordsKey) {
            let decoder = JSONDecoder()
            if let savedRecords = try? decoder.decode([AnalysisRecord].self, from: savedRecordsData) {
                DispatchQueue.main.async {
                    self.highlightRecords = savedRecords
                }
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
                print("Error deleting assets: \(error?.localizedDescription ?? "")")
            }
        }
    }
}

// MARK: - Data Models and Utility Functions

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

// MARK: - PHPicker View Wrapper

struct VideoPicker: UIViewControllerRepresentable {
    var onVideoPicked: (URL) -> Void
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .videos
        configuration.selectionLimit = 1
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var parent: VideoPicker
        
        init(_ parent: VideoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let result = results.first else { return }
            
            let itemProvider = result.itemProvider
            let identifier = UTType.movie.identifier
            
            if itemProvider.hasItemConformingToTypeIdentifier(identifier) {
                itemProvider.loadFileRepresentation(forTypeIdentifier: identifier) { url, error in
                    if let url = url {
                        let documentsDirectory = FileManager.default.temporaryDirectory
                        let newURL = documentsDirectory.appendingPathComponent(url.lastPathComponent)
                        
                        try? FileManager.default.copyItem(at: url, to: newURL)
                        
                        DispatchQueue.main.async {
                            self.parent.onVideoPicked(newURL)
                        }
                    }
                }
            }
        }
    }
}
