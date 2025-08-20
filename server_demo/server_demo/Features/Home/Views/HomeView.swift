//
//  HomeView.swift
//  server_demo
//
//  Created by Google on 2025/8/19.
//

import SwiftUI
import PhotosUI
import AVFoundation
import CoreGraphics

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    // Observe the model object for UI updates
    @StateObject private var viewModel = HighlightsViewModel()
    
    // State management
    @State private var isPickerPresented = false
    @State private var statusMessage = "点击按钮选择视频..."
    @State private var isProcessing = false
    
    // Replace with your local IP address and port 10.93.5.1
    //private let serverURL = URL(string: "http://127.0.0.1:8000/api/upload")!
    private let serverURL = URL(string: "http://10.93.5.1:8000/api/upload")!

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Top navigation bar
                HStack {
                    Text("Visionplay")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top)
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Upload video area
                        VStack(spacing: 20) {
                            Button(action: {
                                // Check if user is logged in
                                guard authViewModel.currentUser != nil else {
                                    statusMessage = "请先登录才能上传视频。"
                                    return
                                }
                                
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
                                            .imageScale(.large)
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
        }
    }
    
    // MARK: - Video Processing and Upload
    
    // Process the selected video URL
    private func processVideo(url: URL) {
        guard let userId = authViewModel.currentUser?.userId else {
            statusMessage = "请先登录才能上传视频。"
            return
        }
        
        isProcessing = true
        statusMessage = "正在上传视频到服务器..."
        
        Task {
            do {
                // Pass userId to the upload function
                let analysisResultDict = try await uploadVideo(videoURL: url, userId: userId)
                
                statusMessage = "正在根据服务器返回的区间生成集锦视频..."
                
                // Extract summary from the analysisResultDict
                guard let summary = analysisResultDict["summary"] as? String else {
                    throw NSError(domain: "AnalysisError", code: 2, userInfo: [NSLocalizedDescriptionKey: "服务器返回的分析结果格式不正确。"])
                }
                
                // Create a new AnalysisRecord with ALL required parameters
                let updatedRecord = AnalysisRecord(
                    title: "视频分析结果",
                    date: Date().formatted(date: .abbreviated, time: .omitted),
                    location: "服务器分析",
                    status: .completed,
                    thumbnail: nil,
                    duration: 0.0,
                    videoURL: url.absoluteString, // 必需的参数
                    analysisSummary: summary,     // 必需的参数
                    analysisDate: Date(),         // 必需的参数
                    localIdentifier: nil          // 必需的参数
                )
                
                await MainActor.run {
                    viewModel.addHighlight(updatedRecord)
                    statusMessage = "视频已成功上传并分析！"
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
    // Returns the 'data' dictionary from the server response
    private func uploadVideo(videoURL: URL, userId: Int) async throws -> [String: Any] {
        var request = URLRequest(url: serverURL)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var httpBody = Data()
        
        // Add user_id field
        httpBody.append("--\(boundary)\r\n".data(using: .utf8)!)
        httpBody.append("Content-Disposition: form-data; name=\"user_id\"\r\n".data(using: .utf8)!)
        httpBody.append("\r\n".data(using: .utf8)!)
        httpBody.append("\(userId)\r\n".data(using: .utf8)!)
        
        // Add video file
        httpBody.append("--\(boundary)\r\n".data(using: .utf8)!)
        httpBody.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(videoURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
        httpBody.append("Content-Type: video/mp4\r\n\r\n".data(using: .utf8)!)
        httpBody.append(try Data(contentsOf: videoURL))
        httpBody.append("\r\n".data(using: .utf8)!)
        
        httpBody.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = httpBody
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        // Decode the full JSON response
        guard let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw NSError(domain: "ServerError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "服务器返回了无效的JSON。"])
        }
        
        if (200...299).contains(httpResponse.statusCode) {
            // Check for 'status' and 'data' in the response
            if let status = jsonResponse["status"] as? String, status == "success",
               let responseData = jsonResponse["data"] as? [String: Any] {
                return responseData // Return the 'data' dictionary
            } else {
                let errorMessage = jsonResponse["message"] as? String ?? "未知成功响应格式。"
                throw NSError(domain: "ServerError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
            }
        } else {
            let errorMessage = jsonResponse["message"] as? String ?? "未知的服务器错误"
            throw NSError(domain: "ServerError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
    }
    
    // The following functions (generateHighlightVideo, saveVideoToPhotoLibrary)
    // are for local video processing and saving. They are kept but not directly
    // used in the current server-driven analysis flow.
    private func generateHighlightVideo(originalVideoURL: URL, highlights: [HighlightInterval]) async throws -> String {
        let asset = AVURLAsset(url: originalVideoURL)
        let tracks = try await asset.load(.tracks)
        let videoTrack = tracks.first(where: { $0.mediaType == .video })
        let audioTrack = tracks.first(where: { $0.mediaType == .audio })
        
        guard let videoTrack else {
            throw NSError(domain: "VideoError", code: 1, userInfo: [NSLocalizedDescriptionKey: "未找到视频轨道。"])
        }
        
        let frameRate = try await videoTrack.load(.nominalFrameRate)
        let videoSize = try await videoTrack.load(.naturalSize)
        let preferredTransform = try await videoTrack.load(.preferredTransform)
        
        let videoRect = CGRect(origin: .zero, size: videoSize)
        let transformedVideoRect = videoRect.applying(preferredTransform)
        let outputSize = CGSize(width: abs(transformedVideoRect.width), height: abs(transformedVideoRect.height))
        
        let composition = AVMutableComposition()
        guard let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else { throw URLError(.cannotCreateFile) }
        
        var compositionAudioTrack: AVMutableCompositionTrack?
        if let audioTrack = audioTrack {
            compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        }
        
        var currentTime = CMTime.zero
        var instructions: [AVMutableVideoCompositionInstruction] = []

        for highlight in highlights {
            let startTime = CMTime(value: CMTimeValue(highlight.startFrame), timescale: CMTimeScale(frameRate))
            let endTime = CMTime(value: CMTimeValue(highlight.endFrame), timescale: CMTimeScale(frameRate))
            let timeRange = CMTimeRange(start: startTime, end: endTime)

            try compositionVideoTrack.insertTimeRange(timeRange, of: videoTrack, at: currentTime)
            if let sourceAudioTrack = audioTrack, let compAudioTrack = compositionAudioTrack {
                try? compAudioTrack.insertTimeRange(timeRange, of: sourceAudioTrack, at: currentTime)
            }

            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
            layerInstruction.setTransform(preferredTransform, at: .zero)

            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = CMTimeRange(start: currentTime, duration: timeRange.duration)
            instruction.layerInstructions = [layerInstruction]
            
            instructions.append(instruction)

            currentTime = CMTimeAdd(currentTime, timeRange.duration)
        }

        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = outputSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: CMTimeScale(frameRate))
        videoComposition.instructions = instructions
        
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
        
        let localIdentifier = try await saveVideoToPhotoLibrary(at: outputURL)
        try? FileManager.default.removeItem(at: outputURL)
        return localIdentifier
    }
    
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
