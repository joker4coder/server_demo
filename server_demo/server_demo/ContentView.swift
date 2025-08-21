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
import UniformTypeIdentifiers
import Security

// MARK: - New Data Models for Server Communication
struct ServerErrorResponse: Codable {
    let error: String
}

struct HighlightsResponse: Codable {
    let highlights: [HighlightInterval]
}

struct HighlightInterval: Codable {
    let startFrame: Int
    let endFrame: Int
}

struct LoginResponse: Codable {
    let userId: String
    let message: String
}

struct ServerHighlightsResponse: Codable {
    let records: [ServerRecord]
}

struct ServerRecord: Codable {
    let title: String
    let date: String
    let location: String
    let duration: Double
}

// MARK: - Data Models

// AnalysisRecord is now Codable for storage and retrieval
struct AnalysisRecord: Identifiable, Codable, Equatable {
    let id = UUID()
    let title: String
    let date: String
    let location: String
    let status: AnalysisStatus
    let thumbnail: String? // Local path string
    let duration: Double
    let localFileUrl: URL? // New: Store local file URL
    
    // CodingKeys required for Codable protocol
    enum CodingKeys: String, CodingKey {
        case id, title, date, location, status, thumbnail, duration, localFileUrl
    }
}

// AnalysisStatus is now Codable
enum AnalysisStatus: String, Codable {
    case completed
    case processing
}

// MARK: - Main Views

struct ContentView: View {
    // 使用一个枚举来管理认证状态
    enum AuthState {
        case loggedOut
        case registering
        case loggedIn
    }
    
    @State private var authState: AuthState = .loggedOut
    @State private var userId: String?
    
    var body: some View {
        Group {
            switch authState {
            case .loggedOut:
                LoginView(authState: $authState, userId: $userId)
            case .registering:
                RegisterView(authState: $authState)
            case .loggedIn:
                TabView {
                    // First Tab: Home
                    HomeView(userId: userId)
                        .tabItem {
                            Label("首页", systemImage: "house")
                        }
                    
                    // Second Tab: Analysis
                    AnalysisView()
                        .tabItem {
                            Label("分析", systemImage: "bolt.fill")
                        }
                    
                    // Third Tab: My Profile
                    MyProfileView(authState: $authState, userId: $userId)
                        .tabItem {
                            Label("我的", systemImage: "person.fill")
                        }
                }
            }
        }
        .onAppear {
            // 检查本地是否有已保存的userId
            if let savedUserId = UserDefaults.standard.string(forKey: "currentUserId") {
                userId = savedUserId
                authState = .loggedIn
            }
        }
    }
}

// MARK: - Login View

struct LoginView: View {
    @Binding var authState: ContentView.AuthState
    @Binding var userId: String?
    
    @State private var username = ""
    @State private var password = ""
    @State private var message = ""
    @State private var isLoading = false
    
    private let serverURL = URL(string: "http://192.168.3.38:5001/login")
    
    var body: some View {
        VStack(spacing: 20) {
            Text("登录")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            TextField("用户名", text: $username)
                .textFieldStyle(.roundedBorder)
            
            SecureField("密码", text: $password)
                .textFieldStyle(.roundedBorder)
            
            if isLoading {
                ProgressView()
            } else {
                Button("登录") {
                    login()
                }
                .buttonStyle(.borderedProminent)
            }
            
            Text(message)
                .foregroundColor(.red)
            
            Button("还没有账号？去注册") {
                authState = .registering
            }
            .buttonStyle(.plain)
        }
        .padding()
    }
    
    private func login() {
        isLoading = true
        message = ""
        
        guard let url = serverURL else {
            message = "服务器地址无效"
            isLoading = false
            return
        }
        
        let requestBody = ["username": username, "password": password]
        guard let httpBody = try? JSONSerialization.data(withJSONObject: requestBody) else {
            message = "数据格式错误"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = httpBody
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    message = "登录失败: \(error.localizedDescription)"
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    message = "服务器响应无效"
                    return
                }
                
                guard httpResponse.statusCode == 200, let data = data else {
                    let errorResponse = try? JSONDecoder().decode(ServerErrorResponse.self, from: data ?? Data())
                    message = errorResponse?.error ?? "未知的登录错误"
                    return
                }
                
                // 登录成功，解析userId并切换视图
                if let decodedResponse = try? JSONDecoder().decode(LoginResponse.self, from: data) {
                    self.userId = decodedResponse.userId
                    UserDefaults.standard.set(decodedResponse.userId, forKey: "currentUserId")
                    authState = .loggedIn
                    message = "登录成功"
                } else {
                    message = "解析服务器响应失败"
                }
            }
        }.resume()
    }
}

// MARK: - Register View

struct RegisterView: View {
    @Binding var authState: ContentView.AuthState
    
    @State private var username = ""
    @State private var password = ""
    @State private var message = ""
    @State private var isLoading = false
    
    private let serverURL = URL(string: "http://192.168.3.38:5001/register")
    
    var body: some View {
        VStack(spacing: 20) {
            Text("注册")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            TextField("用户名", text: $username)
                .textFieldStyle(.roundedBorder)
            
            SecureField("密码", text: $password)
                .textFieldStyle(.roundedBorder)
            
            if isLoading {
                ProgressView()
            } else {
                Button("注册") {
                    register()
                }
                .buttonStyle(.borderedProminent)
            }
            
            Text(message)
                .foregroundColor(.red)
            
            Button("已有账号？去登录") {
                authState = .loggedOut
            }
            .buttonStyle(.plain)
        }
        .padding()
    }
    
    private func register() {
        isLoading = true
        message = ""
        
        guard let url = serverURL else {
            message = "服务器地址无效"
            isLoading = false
            return
        }
        
        let requestBody = ["username": username, "password": password]
        guard let httpBody = try? JSONSerialization.data(withJSONObject: requestBody) else {
            message = "数据格式错误"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = httpBody
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    message = "注册失败: \(error.localizedDescription)"
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    message = "服务器响应无效"
                    return
                }
                
                guard httpResponse.statusCode == 201 else {
                    let errorResponse = try? JSONDecoder().decode(ServerErrorResponse.self, from: data ?? Data())
                    message = errorResponse?.error ?? "未知的注册错误"
                    return
                }
                
                message = "注册成功，请登录"
                authState = .loggedOut
            }
        }.resume()
    }
}

// MARK: - Home View (Video Upload and Recent Records)

struct HomeView: View {
    // Observe the model object for UI updates
    @StateObject private var viewModel = HighlightsViewModel()
    @State private var isPickerPresented = false
    @State private var statusMessage = "点击按钮选择视频..."
    @State private var isProcessing = false
    
    let userId: String?
    private let serverURL = URL(string: "http://192.168.3.38:5001/upload_video")
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Top navigation bar
                HStack {
                    Text("Visionplay")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    //                    Button(action: {
                    //                        // Button action
                    //                    }) {
                    //                        Image(systemName: "gearshape")
                    //                            .imageScale(.large)
                    //                            .foregroundColor(.gray)
                    //                    }
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
                                            .font(.system(size: 40, weight: .light))
                                            .foregroundColor(.white)
                                        Text("上传比赛视频")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .frame(width: 180, height: 180)
                            .background(Color(red: 0.2, green: 0.6, blue: 0.1, opacity: 1.0))
                            .clipShape(Circle())
                            .disabled(isProcessing) // Disable button when processing
                            
                            HStack(spacing: 40) {
                                Button(action: {
                                    // Photo library action
                                }) {
                                    HStack(spacing: 5) {
                                        Image(systemName: "photo.fill.on.rectangle.fill")
                                        Text("相册")
                                    }
                                    .foregroundColor(.gray)
                                }
                                
                                Button(action: {
                                    // Camera action
                                }) {
                                    HStack(spacing: 5) {
                                        Image(systemName: "camera.fill")
                                            .imageScale(.large)
                                        Text("拍摄")
                                    }
                                    .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(.top, 40)
                        
                        Divider().padding(.horizontal, 20)
                        
                        // Recent analysis records list
                        VStack(alignment: .leading, spacing: 15) {
                            Text("最近分析记录")
                                .font(.system(size: 18, weight: .bold))
                                .padding(.leading, 16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            ForEach(viewModel.highlightRecords.prefix(2)) { record in
                                AnalysisRecordRowView(record: record)
                                    .frame(maxWidth: .infinity, alignment: .leading)  // 确保标题左对齐
                                    .padding(.leading, 16)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)  // 确保标题左对齐
                    }
                    .padding()
                }
            }
            .sheet(isPresented: $isPickerPresented) {
                VideoPicker(onVideoPicked: processVideo)
            }
            .onAppear {
                viewModel.loadHighlights()
            }
        }
    }
    
    // MARK: - Video Processing and Upload
    
    // Process the selected video URL
    private func processVideo(url: URL) {
        isProcessing = true
        statusMessage = "正在上传视频到服务器..."
        
        Task {
            do {
                guard let highlights = try await uploadVideo(videoURL: url) else {
                    await MainActor.run {
                        statusMessage = "服务器未返回集锦数据"
                        isProcessing = false
                    }
                    return
                }
                
                print("服务器返回的集锦区间:")
                for (index, highlight) in highlights.enumerated() {
                    print("  片段 \(index + 1): 起始帧 \(highlight.startFrame), 结束帧 \(highlight.endFrame)")
                }
                
                statusMessage = "正在根据服务器返回的区间生成集锦视频..."
                
                let asset = AVURLAsset(url: url)
                let videoTrack = try await asset.load(.tracks).first(where: { $0.mediaType == .video })
                guard let videoTrack else {
                    throw NSError(domain: "VideoError", code: 1, userInfo: [NSLocalizedDescriptionKey: "未找到视频轨道。"])
                }
                let frameRate = try await videoTrack.load(.nominalFrameRate)
                
                var totalHighlightDuration: Double = 0
                for highlight in highlights {
                    totalHighlightDuration += Double(highlight.endFrame - highlight.startFrame) / Double(frameRate)
                }
                
                let localFileUrl = try await generateHighlightVideo(originalVideoURL: url, highlights: highlights)
                
                let updatedRecord = AnalysisRecord(
                    title: "新视频集锦",
                    date: Date().formatted(date: .abbreviated, time: .omitted),
                    location: "我的相册",
                    status: .completed,
                    thumbnail: localFileUrl.absoluteString,
                    duration: totalHighlightDuration,
                    localFileUrl: localFileUrl
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
    private func uploadVideo(videoURL: URL) async throws -> [HighlightInterval]? {
        guard let userId = userId else {
            throw NSError(domain: "AuthError", code: 100, userInfo: [NSLocalizedDescriptionKey: "用户未登录"])
        }
        
        guard let url = serverURL else {
            throw NSError(domain: "URL Error", code: 101, userInfo: [NSLocalizedDescriptionKey: "服务器地址无效"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var httpBody = Data()
        
        // Add userId to the form data
        httpBody.append("--\(boundary)\r\n".data(using: .utf8)!)
        httpBody.append("Content-Disposition: form-data; name=\"userId\"\r\n\r\n".data(using: .utf8)!)
        httpBody.append(userId.data(using: .utf8)!)
        httpBody.append("\r\n".data(using: .utf8)!)
        
        // Add video file
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
        
        let decodedResponse = try? JSONDecoder().decode(HighlightsResponse.self, from: data)
        return decodedResponse?.highlights
    }
    
    // gen by ds
    // Generate a highlight video with a watermark based on intervals and save to the app's document directory
    private func generateHighlightVideo(originalVideoURL: URL, highlights: [HighlightInterval]) async throws -> URL {
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
        
        // --- 修复点：将文件保存到文档目录，而不是临时目录 ---
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let outputURL = documentsDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")
        
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
        
        return outputURL
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
                viewModel.loadHighlights()
            }
        }
    }
}

// MARK: - My Profile View

struct MyProfileView: View {
    @Binding var authState: ContentView.AuthState
    @Binding var userId: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 1. 个人信息区域 - 包含背景图
                    ZStack(alignment: .bottomLeading) {
                        // 背景图只在此 ZStack 内部显示
                        Image("my-bg")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200) // 背景图的高度
                            .clipped()
                        
                        // 蒙版
                        LinearGradient(
                            gradient: Gradient(colors: [Color.black.opacity(0.1), Color.black.opacity(0.6)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 200)
                        
                        // 个人信息内容
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .bottom, spacing: 16) {
                                Image("player_avatar")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 8) {
                                        Text("小帅")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.white)
                                        PlayerPositionLabel(title: "前腰")
                                        PlayerPositionLabel(title: "右边")
                                        PlayerPositionLabel(title: "右前卫")
                                    }
                                    
                                    Text("所属球队: 深圳夜鹰.深圳种子队")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 40) // 调整与卡片间距
                    }
                    .frame(maxWidth: .infinity, alignment: .top)
                    .frame(height: 200) // ZStack 的整体高度
                    
                    // 2. 统计数据卡片
                    VStack(spacing: 20) {
                        HStack(spacing: 40) {
                            StatView(number: "766", label: "进球")
                            StatView(number: "68", label: "助攻")
                            StatView(number: "569", label: "出场")
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(color: Color.gray.opacity(0.1), radius: 5, x: 0, y: 5)
                    .padding(.horizontal, 16)
                    .offset(y: -40) // 向上移动，与背景图重叠
                    
                    // 3. 菜单列表
                    VStack(spacing: 0) {
                        MenuListRow(icon: "photo.on.rectangle.angled", title: "个人集锦", subtitle: "已保存至我的视频片段", showChevron: true)
                        MenuListRow(icon: "flag.fill", title: "我的比赛", subtitle: "仅显示我参加的比赛", showChevron: true)
                        MenuListRow(icon: "person.fill", title: "球员信息", subtitle: "个人基本信息，公开展示", showChevron: true)
                        MenuListRow(icon: "lock.shield.fill", title: "实名信息", subtitle: "参加赛事时需进行实名认证", showChevron: true)
                        MenuListRow(icon: "square.grid.2x2.fill", title: "个人属性", subtitle: "初次加入球队时，此为默认属性", showChevron: true)
                        
                        Divider().padding(.horizontal, 20)
                        
                        MenuListRow(icon: "list.bullet.rectangle.fill", title: "订单", showChevron: true)
                        MenuListRow(icon: "headphones", title: "客服", showChevron: true)
                        MenuListRow(icon: "gearshape.fill", title: "设置", showChevron: true)
                    }
                    .padding(.horizontal, 16)
                    .offset(y: -40)
                    
                    Button("退出登录") {
                        UserDefaults.standard.removeObject(forKey: "currentUserId")
                        userId = nil
                        authState = .loggedOut
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                    
                }
            }
            .background(Color(.systemGray6)) // 整个 ScrollView 的背景色
            //.navigationTitle("我的")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - List Item View (Reusable)

struct AnalysisRecordRowView: View {
    let record: AnalysisRecord
    
    @State private var thumbnailImage: UIImage?
    
    var body: some View {
        // If the record is completed and has a local identifier, make it navigable
        Group {
            // Only allow navigation if a local file URL exists
            if let localUrl = record.localFileUrl, record.status == .completed {
                NavigationLink(destination: VideoPlayerContainerView(localFileUrl: localUrl)) {
                    contentView
                }
                .buttonStyle(PlainButtonStyle()) // Remove the default blue link style
            } else {
                contentView
            }
        }
        .onAppear {
            if let localFileUrl = record.localFileUrl {
                generateThumbnail(for: localFileUrl)
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
    
    private func generateThumbnail(for videoURL: URL) {
        let asset = AVAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        
        Task {
            do {
                let thumbnailCGImage = try await generator.image(at: .zero).image
                await MainActor.run {
                    self.thumbnailImage = UIImage(cgImage: thumbnailCGImage)
                }
            } catch {
                print("Error generating thumbnail: \(error.localizedDescription)")
                self.thumbnailImage = UIImage(systemName: "exclamationmark.triangle.fill")
            }
        }
    }
}

// MARK: - Video Player View

struct VideoPlayerView: View {
    let localFileUrl: URL
    @State private var player: AVPlayer?
    @State private var hasAudio = false
    @State private var isMuted = false
    @State private var isShowingSaveAlert = false
    
    var body: some View {
        VStack {
            if let player = player {
                VideoPlayer(player: player)
                    .onAppear {
                        // 修复1: 配置音频会话
                        configureAudioSession()
                        player.play()
                    }
                    .onLongPressGesture {
                        // 长按时显示保存视频的对话框
                        isShowingSaveAlert = true
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
        .alert("保存视频", isPresented: $isShowingSaveAlert) {
            Button("保存到相册", role: .destructive) {
                saveVideoToPhotoLibrary(at: localFileUrl)
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("您确定要将此视频保存到您的相册吗？")
        }
    }
    
    private func loadVideoAsset() {
        let asset = AVAsset(url: localFileUrl)
        let audioTracks = asset.tracks(withMediaType: .audio)
        DispatchQueue.main.async {
            self.hasAudio = !audioTracks.isEmpty
            self.player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
            self.player?.isMuted = false
        }
    }
    
    private func configureAudioSession() {
        do {
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
    
    // Save the video to the photo album
    private func saveVideoToPhotoLibrary(at url: URL) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized else {
                print("未授权访问相册。")
                return
            }
            
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            } completionHandler: { success, error in
                if success {
                    print("视频已成功保存到相册。")
                } else {
                    print("保存视频到相册失败: \(error?.localizedDescription ?? "")")
                }
            }
        }
    }
}

// MARK: - Video Player Container View (for asynchronous video loading)

struct VideoPlayerContainerView: View {
    let localFileUrl: URL
    
    var body: some View {
        VideoPlayerView(localFileUrl: localFileUrl)
    }
}

// MARK: - View Model
class HighlightsViewModel: ObservableObject {
    @Published var highlightRecords: [AnalysisRecord] = []
    
    private let recordsKey = "highlightAnalysisRecords"
    
    // MARK: - 本地数据持久化
    
    func saveHighlights() {
        do {
            let encodedData = try JSONEncoder().encode(highlightRecords)
            UserDefaults.standard.set(encodedData, forKey: recordsKey)
            print("集锦记录已保存到 UserDefaults。")
        } catch {
            print("保存集锦记录失败: \(error.localizedDescription)")
        }
    }
    
    func loadHighlights() {
        if let savedData = UserDefaults.standard.data(forKey: recordsKey) {
            do {
                highlightRecords = try JSONDecoder().decode([AnalysisRecord].self, from: savedData)
                print("集锦记录已从 UserDefaults 加载。")
            } catch {
                print("加载集锦记录失败: \(error.localizedDescription)")
            }
        }
    }
    
    // Load data from server based on userId
    func fetchHighlights(userId: String?) {
        // This function is now for fetching server-side data, but the core issue
        // is with local persistence. We'll leave this here for future server
        // functionality, but the main fix is in loadHighlights().
        
        guard let userId = userId else {
            print("用户未登录，无法获取集锦记录。")
            // Instead of clearing, let's keep the local records
            return
        }
        
        guard let url = URL(string: "http://192.168.3.38:5001/get_highlights?userId=\(userId)") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                if let decodedResponse = try? JSONDecoder().decode(ServerHighlightsResponse.self, from: data) {
                    DispatchQueue.main.async {
                        // 将服务器返回的数据转换为本地模型
                        let serverRecords = decodedResponse.records.map { serverRecord -> AnalysisRecord in
                            // For simplicity, we create a dummy AnalysisRecord.
                            // In a real app, you would fetch these details from the server as well.
                            return AnalysisRecord(
                                title: serverRecord.title,
                                date: serverRecord.date,
                                location: serverRecord.location,
                                status: .completed, // Assuming all fetched are completed
                                thumbnail: nil, // We'll need to handle thumbnail from server later
                                duration: serverRecord.duration,
                                localFileUrl: nil // You would need a separate endpoint to download the video
                            )
                        }
                        // This would need a more complex merge logic in a real app
                        // For now, we'll just add new ones if they don't exist
                        let newRecords = serverRecords.filter { !self.highlightRecords.contains($0) }
                        self.highlightRecords.append(contentsOf: newRecords)
                        
                        // We also need to save the combined data
                        self.saveHighlights()
                    }
                    return
                }
            }
            print("Failed to fetch highlights: \(error?.localizedDescription ?? "未知错误")")
        }.resume()
    }
    
    // Add a new record and save
    func addHighlight(_ record: AnalysisRecord) {
        highlightRecords.insert(record, at: 0)
        // Immediately save to local storage after adding a new record
        saveHighlights()
    }
    
    func deleteAssets(at offsets: IndexSet) {
        // This function would need to be updated to delete records on the server
        highlightRecords.remove(atOffsets: offsets)
        saveHighlights()
    }
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
                        // --- 修复点：将文件保存到文档目录，而不是临时目录 ---
                        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                        let newURL = documentsDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")
                        
                        do {
                            if FileManager.default.fileExists(atPath: newURL.path) {
                                try FileManager.default.removeItem(at: newURL)
                            }
                            try FileManager.default.copyItem(at: url, to: newURL)
                            
                            DispatchQueue.main.async {
                                self.parent.onVideoPicked(newURL)
                            }
                        } catch {
                            print("Error copying video to Documents directory: \(error)")
                        }
                    }
                }
            }
        }
    }
}

// 辅助视图：用于球员位置标签
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

// 辅助视图：用于统计数据
struct StatView: View {
    let number: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(number)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
    }
}

// 辅助视图：用于菜单列表行
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
