
//
//  VideoPicker.swift
//  server_demo
//
//  Created by Google on 2025/8/19.
//

import SwiftUI
import PhotosUI

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
                        // Create a new unique URL in the temporary directory to avoid overwriting
                        let newURL = FileManager.default.temporaryDirectory
                            .appendingPathComponent(UUID().uuidString)
                            .appendingPathExtension(url.pathExtension)
                        
                        do {
                            // Try to remove an existing item at the new URL, then copy the new one
                            try? FileManager.default.removeItem(at: newURL)
                            try FileManager.default.copyItem(at: url, to: newURL)
                            
                            DispatchQueue.main.async {
                                self.parent.onVideoPicked(newURL)
                            }
                        } catch {
                            print("Error copying file: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }
}
