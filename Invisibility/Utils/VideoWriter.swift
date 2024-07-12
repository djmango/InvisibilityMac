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
    private let userManager: UserManager = .shared
    private let logger = InvisibilityLogger(subsystem: AppConfig.subsystem, category: "VideoWriter")

    let fileManager = FileManager.default
    
    // Tools for saving video recordings
    private var videoWriter: AVAssetWriter?
    private var videoWriterInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    
    var frameSize: CGSize?
    private var currentClip: Clip?
    private var clipsToUpload: [Clip] = [] {
        didSet {
            processClips()
        }
    }

    private let processingQueue = DispatchQueue(label: "videowriter.processing")
    private var isProcessing = false
    
    private func processClips() {
        processingQueue.async {
            guard !self.isProcessing, !self.clipsToUpload.isEmpty else { return }
            self.isProcessing = true
            let clip = self.clipsToUpload.removeFirst()
            guard !clip.frames.isEmpty else { return }
            
            Task {
                await self.writeVideoClip(clip: clip)
                self.isProcessing = false
                self.processClips()
            }
        }
    }

    private func getPresignedUrl(timestamp: Int64) async throws -> String? {
        let urlString = AppConfig.invisibility_api_base + "/sidekick/fetch_save_url"
        guard let jwtToken = userManager.token else {
            logger.warning("No JWT token")
            return nil
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let body: [String: Any] = [
                "session_id": userManager.sessionId,
                "start_timestamp": timestamp
            ]
            
            AF.request(urlString, method: .post, parameters: body, encoding: JSONEncoding.default, headers: ["Authorization": "Bearer \(jwtToken)"])
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
    
    private func uploadVideoToS3(fileUrl: URL, timestamp: Int64) async -> Bool {
        do {
            guard let presignedUrl = try await self.getPresignedUrl(timestamp: timestamp) else { return false }
            guard fileManager.fileExists(atPath: fileUrl.path) else { return false }
            
            let headers: HTTPHeaders = [
                "Content-Type": "video/mp4"
            ]
            
            let success = try await withCheckedThrowingContinuation { continuation in
                AF.upload(fileUrl, to: presignedUrl, method: .put, headers: headers)
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
            
            return success
        } catch {
            self.logger.error("Error fetching the presigned URL: \(error)")
            return false
        }
    }
    
    func recordFrame(frame: CGImage) {
        if currentClip == nil {
            let timestamp = Int(Date().timeIntervalSince1970)
            currentClip = Clip(startTime: Int64(timestamp), frames: [])
        }

        currentClip!.frames.append(frame)

        if currentClip!.frames.count == 300 {
            clipsToUpload.append(currentClip!)
            
            currentClip = nil
        }
    }
    
    func sendCurrentClip() {
        guard let currentClip = currentClip else { return }
        
        clipsToUpload.append(currentClip)
    }
    
    func writeVideoClip(clip: Clip) async {
        logger.info("Writing new video clip")
        let outputFileUrl: URL = FileManager.default.temporaryDirectory.appendingPathComponent("video-\(clip.startTime).mp4")

        setupVideoWriter(fileUrl: outputFileUrl)
        startWritingVideo()
        
        for (index, frame) in clip.frames.enumerated() {
            let currentFrameTime = CMTime(value: Int64(index), timescale: 10)
            appendFrameToVideo(frame, at: currentFrameTime)
        }
        
        finishWritingVideo {
            if await self.uploadVideoToS3(fileUrl: outputFileUrl, timestamp: clip.startTime) {
                do {
                    try self.fileManager.removeItem(at: outputFileUrl)
                } catch {
                    self.logger.error("Error deleting local file: \(error)")
                }
            }
        }
    }
    
    private func setupVideoWriter(fileUrl: URL) {
        guard let frameSize = frameSize else { return }

        do {
            videoWriter = try AVAssetWriter(outputURL: fileUrl, fileType: .mp4)
            
            let videoSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.hevc,
                AVVideoWidthKey: frameSize.width,
                AVVideoHeightKey: frameSize.height,
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: 1_000_000
                ]
            ]
            
            videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            
            guard videoWriterInput != nil && videoWriter != nil else {
                logger.error("Error initializing video writer")
                return
            }
            
            videoWriterInput!.expectsMediaDataInRealTime = true
            
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
            logger.error("Error setting up video writer: \(error)")
        }
    }

    private func startWritingVideo() {
        guard videoWriter != nil else {
            logger.error("Video writer is nil")
            return
        }

        videoWriter!.startWriting()
        videoWriter!.startSession(atSourceTime: .zero)
    }

    private func finishWritingVideo(completion: @escaping () async -> Void) {
        videoWriterInput?.markAsFinished()
        videoWriter?.finishWriting {
            Task {
                await completion()
                
                self.videoWriter = nil
                self.videoWriterInput = nil
                self.pixelBufferAdaptor = nil
            }
        }
    }

    private func appendFrameToVideo(_ cgImage: CGImage, at time: CMTime) {
        guard videoWriterInput != nil else {
            logger.error("Video writer input is nil")
            return
        }
        
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

struct Clip {
    var startTime: Int64
    var frames: [CGImage]
}
