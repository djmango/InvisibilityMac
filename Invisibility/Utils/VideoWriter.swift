//
//  VideoWriter.swift
//  Invisibility
//
//  Created by Braeden Hall on 7/8/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//
import Alamofire
import AVFoundation
import Foundation
import ScreenCaptureKit

class VideoWriter {

    private let logger = InvisibilityLogger(subsystem: AppConfig.subsystem, category: "VideoWriter")

    let fileManager = FileManager.default
    let outputFileUrl: URL
    
    // Tools for saving video recordings
    private var videoWriter: AVAssetWriter?
    private var videoWriterInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    
    private let userManager: UserManager = .shared
    
    init() {
       outputFileUrl = FileManager.default.temporaryDirectory.appendingPathComponent("captured_video.mp4")
        logger.info("saving sidekick videos to \(outputFileUrl)")
    }

    private func getPresignedUrl() async throws -> String? {
        let urlString = AppConfig.invisibility_api_base + "/storage/sidekick/presigned_url"
        guard let jwtToken = userManager.token else {
            logger.warning("No JWT token")
            return nil
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            AF.request(urlString, method: .get, headers: ["Authorization": "Bearer \(jwtToken)"])
                .validate()
                .responseString() { response in
                    switch response.result {
                    case let .success(presignedUrl):
                        continuation.resume(returning: presignedUrl)
                    case let .failure(error):
                        self.logger.error("Error fetching user: \(error)")
                        continuation.resume(throwing: error)
                    }
                }
        }
    }
    
    private func uploadVideoToS3() async -> Bool {
        do {
            guard let presignedUrl = try await self.getPresignedUrl() else { return false }
            guard fileManager.fileExists(atPath: outputFileUrl.path) else { return false }
            
            let headers: HTTPHeaders = [
                "Content-Type": "video/mp4"
            ]
            
            let success =  try await withCheckedThrowingContinuation { continuation in
                AF.upload(outputFileUrl, to: presignedUrl, method: .put, headers: headers)
                    .validate(statusCode: 200..<300)
                    .response { response in
                        switch response.result {
                        case .success:
                            self.logger.info("File uploaded successfully")
                            continuation.resume(returning: true)
                        case .failure(let error):
                            self.logger.error("Upload failed with error: \(error.localizedDescription)")
                            continuation.resume(returning: true)
                        }
                    }
            }
            
            try fileManager.removeItem(at: outputFileUrl)
            
            return success
        } catch {
            self.logger.error("Error fetching the presigned URL: \(error)")
            return false
        }
    }
    
    func setupVideoWriter(frameSize: CGSize) {
        do {
            videoWriter = try AVAssetWriter(outputURL: outputFileUrl, fileType: .mp4)
            
            let videoSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.hevc,
                AVVideoWidthKey: frameSize.width,
                AVVideoHeightKey: frameSize.height,
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: 1_000_000
                ]
            ]
            
            videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            videoWriterInput?.expectsMediaDataInRealTime = true
            
            let sourcePixelBufferAttributes: [String: Any] = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
                kCVPixelBufferWidthKey as String: frameSize.width,
                kCVPixelBufferHeightKey as String: frameSize.height
            ]
            
            pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
                assetWriterInput: videoWriterInput!,
                sourcePixelBufferAttributes: sourcePixelBufferAttributes
            )
            
            if videoWriter!.canAdd(videoWriterInput!) {
                videoWriter!.add(videoWriterInput!)
            }
        } catch {
            print("Error setting up video writer: \(error)")
        }
    }

    func startWritingVideo() {
        guard videoWriter != nil else {
            logger.error("Video writer is nil")
            return
        }

        videoWriter?.startWriting()
        videoWriter?.startSession(atSourceTime: .zero)
    }

    func finishWritingVideo(completion: @escaping () -> Void) {
        videoWriterInput?.markAsFinished()
        videoWriter?.finishWriting {
            completion()
            Task {
                await self.uploadVideoToS3()
            }
        }

        videoWriter = nil
        videoWriterInput = nil
        pixelBufferAdaptor = nil
    }

    func appendFrameToVideo(_ cgImage: CGImage, at time: CMTime) {
        guard let pixelBufferAdaptor = pixelBufferAdaptor,
            let pixelBufferPool = pixelBufferAdaptor.pixelBufferPool else {
            return
        }
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferPoolCreatePixelBuffer(nil, pixelBufferPool, &pixelBuffer)
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return
        }
        
        let context = CIContext()
        let ciImage = CIImage(cgImage: cgImage)
        context.render(ciImage, to: buffer)
        
        if videoWriterInput!.isReadyForMoreMediaData {
            pixelBufferAdaptor.append(buffer, withPresentationTime: time)
        }
    }
}
