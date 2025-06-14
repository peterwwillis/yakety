import SwiftUI
import AppKit
import Foundation

// MARK: - Download Dialog
struct DownloadDialogView: View {
    @ObservedObject var state: DownloadDialogState
    let modelName: String
    let downloadUrl: String
    let filePath: String
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with icon and title
            HStack(spacing: 12) {
                if let appIcon = loadAppIcon() {
                    Image(nsImage: appIcon)
                        .resizable()
                        .frame(width: 32, height: 32)
                }
                
                Text("Downloading \(modelName)")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 24)
            
            // Content area
            VStack(spacing: 16) {
                ProgressView(value: state.downloadProgress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .scaleEffect(x: 1, y: 1.5)
                
                Text(state.downloadStatus)
                    .foregroundColor(.secondary)
                    .font(.body)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            
            // Bottom buttons
            HStack(spacing: 12) {
                Spacer()
                
                Button("Cancel") {
                    state.downloadResult = 1 // Cancelled
                    state.isCompleted = true
                }
                .disabled(state.downloadProgress >= 1.0)
                .controlSize(.large)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(width: 400)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            startDownload()
        }
    }
    
    private func startDownload() {
        // Create the directory if it doesn't exist
        let directory = (filePath as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true, attributes: nil)
        
        guard let url = URL(string: downloadUrl) else {
            state.downloadStatus = "Invalid URL"
            state.downloadResult = 2 // Error
            state.isCompleted = true
            return
        }
        
        let destinationURL = URL(fileURLWithPath: filePath)
        
        // Use URLSession to download
        let task = URLSession.shared.downloadTask(with: url) { tempURL, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    state.downloadStatus = "Download failed: \(error.localizedDescription)"
                    state.downloadResult = 2 // Error
                    state.isCompleted = true
                    return
                }
                
                guard let tempURL = tempURL else {
                    state.downloadStatus = "Download failed: No data received"
                    state.downloadResult = 2 // Error
                    state.isCompleted = true
                    return
                }
                
                do {
                    // Remove existing file if it exists
                    if FileManager.default.fileExists(atPath: filePath) {
                        try FileManager.default.removeItem(at: destinationURL)
                    }
                    
                    // Move downloaded file to final location
                    try FileManager.default.moveItem(at: tempURL, to: destinationURL)
                    
                    state.downloadStatus = "Download complete"
                    state.downloadProgress = 1.0
                    state.downloadResult = 0 // Success
                    state.isCompleted = true
                } catch {
                    state.downloadStatus = "Failed to save file: \(error.localizedDescription)"
                    state.downloadResult = 2 // Error
                    state.isCompleted = true
                }
            }
        }
        
        // Monitor download progress
        let observation = task.progress.observe(\.fractionCompleted) { progress, _ in
            DispatchQueue.main.async {
                state.downloadProgress = progress.fractionCompleted
                let percentage = Int(progress.fractionCompleted * 100)
                state.downloadStatus = "Downloaded \(percentage)%"
            }
        }
        
        // Start the download
        task.resume()
        
        // Keep the observation alive
        state.progressObservation = observation
    }
}

// MARK: - Dialog State
class DownloadDialogState: ObservableObject {
    @Published var isCompleted = false
    @Published var downloadResult = 0 // 0 = success, 1 = cancelled, 2 = error
    @Published var downloadProgress: Double = 0
    @Published var downloadStatus = "Starting download..."
    var progressObservation: NSKeyValueObservation?
    
    deinit {
        progressObservation?.invalidate()
    }
}

// MARK: - ModalDialogState Conformance
extension DownloadDialogState: ModalDialogState {
    typealias ResultType = Int32
    
    var result: Int32 {
        return Int32(downloadResult)
    }
    
    func reset() {
        isCompleted = false
        downloadResult = 0
        downloadProgress = 0
        downloadStatus = "Starting download..."
        progressObservation?.invalidate()
        progressObservation = nil
    }
}

private var globalDownloadDialogState = DownloadDialogState()


// MARK: - C Interface Function
@_cdecl("dialog_model_download")
public func dialog_model_download(
    _ model_name: UnsafePointer<CChar>,
    _ download_url: UnsafePointer<CChar>,
    _ file_path: UnsafePointer<CChar>
) -> Int32 {
    
    let modelNameStr = String(cString: model_name)
    let downloadUrlStr = String(cString: download_url)
    let filePathStr = String(cString: file_path)
    
    return runModalDialog(
        content: DownloadDialogView(
            state: globalDownloadDialogState,
            modelName: modelNameStr,
            downloadUrl: downloadUrlStr,
            filePath: filePathStr
        ),
        state: globalDownloadDialogState,
        windowSize: NSSize(width: 400, height: 200),
        windowTitle: "Model Download"
    )
}