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

    static let shared = VideoWriter()

    let fileManager = FileManager.default
    
    // Tools for saving video recordings
    private var videoWriter: AVAssetWriter?
    private var videoWriterInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var pixelBufferPool: CVPixelBufferPool?

    // testing this config rn. next -> 3_000_000, what is storage growth?
    // test recording when not keyed
    let vid_duration = 30
    let bitrate = 3_000_000
    let fps = 30
    
    var frameSize: CGSize?
    
    private var currentClip: Clip?
        
    private func getClipFileUrl(timestamp: Double?) -> URL? {
        guard let timestamp = timestamp ?? currentClip?.startTime else { return nil }

        return FileManager.default.temporaryDirectory.appendingPathComponent("video-\(timestamp).mp4")
    }

    private func getPresignedUrl(clipId: String, timestamp: Double, duration: Int64) async throws -> String? {
        let urlString = AppConfig.invisibility_api_base + "/sidekick/fetch_save_url"
        guard let jwtToken = userManager.token else {
            logger.warning("No JWT token")
            return nil
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let body: [String: Any] = [
                "recording_id": clipId,
                "session_id": userManager.sessionId,
                "start_timestamp_nanos": Int64(timestamp * 1_000_000_000),
                "duration_ms": duration
            ]
                        
            AF.request(urlString, method: .post, parameters: body, encoding: JSONEncoding.default, headers: ["Authorization": "Bearer \(jwtToken)"])
                .validate()
                .responseString() { response in
                    switch response.result {
                    case let .success(presignedUrl):
                        continuation.resume(returning: presignedUrl)
                    case let .failure(error):
                        self.logger.error("Error fetching presigned url: \(error)")
                        continuation.resume(throwing: error)
                    }
                }
        }
    }
    
    private func uploadVideoToS3(clipId: String, timestamp: Double, duration: Int64) async -> Bool {
        do {
            guard let presignedUrl = try await self.getPresignedUrl(clipId: clipId, timestamp: timestamp, duration: duration) else { return false }
            guard let fileUrl = getClipFileUrl(timestamp: timestamp) else { return false }
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
                            print(clipId, presignedUrl)
                            continuation.resume(returning: true)
                        case .failure(let error):
                            self.logger.error("Upload failed with error: \(error.localizedDescription)")
                            if let data = response.data, let str = String(data: data, encoding: .utf8) {
                               self.logger.error("Response body: \(str)")
                           }
                           if let statusCode = response.response?.statusCode {
                               self.logger.error("Status code: \(statusCode)")
                           }
                           continuation.resume(returning: false)
                        }
                    }
            }
            
            return success
        } catch {
            self.logger.error("Error fetching the presigned URL: \(error)")
            return false
        }
    }
    
    func getCurrentClipId() -> String? {
        return currentClip?.id
    }
    
    func recordFrame(frame: CGImage) {
        if currentClip == nil {
            currentClip = Clip(id: UUID().uuidString, startTime: Date().timeIntervalSince1970, frameCount: 0)
            
            setupVideoWriter()
            startWritingVideo()
        }

        // Append frame to video
        let currentFrameTime = CMTime(value: currentClip!.frameCount, timescale: CMTimeScale(fps))
        appendFrameToVideo(frame, at: currentFrameTime)
        currentClip?.frameCount += 1
        
        if currentClip!.frameCount % Int64(vid_duration * fps) == 0 {
            let clipTimestamp = currentClip!.startTime
            let clipId = self.currentClip!.id
            let frameCount = self.currentClip!.frameCount
            
            finishWritingVideo {
                let durationMs = Int64((frameCount * 1000) / Int64(self.fps))
                let _ = await self.uploadVideoToS3(clipId: clipId, timestamp: clipTimestamp, duration: durationMs)
                guard let fileUrl = self.getClipFileUrl(timestamp: clipTimestamp) else { return }

                do {
                    try self.fileManager.removeItem(at: fileUrl)
                } catch {
                    self.logger.error("Error deleting local file: \(error)")
                }
            }
            
            videoWriter = nil
            videoWriterInput = nil
            pixelBufferAdaptor = nil
            currentClip = nil
        }
    }
    
    func sendCurrentClip() {
        guard let clip = currentClip else { return }

        finishWritingVideo {
            let durationMs = Int64((clip.frameCount * 1000) / Int64(self.fps))
            let _ = await self.uploadVideoToS3(clipId: clip.id, timestamp: clip.startTime, duration: durationMs)
            guard let fileUrl = self.getClipFileUrl(timestamp: clip.startTime) else { return }

            do {
                try self.fileManager.removeItem(at: fileUrl)
            } catch {
                self.logger.error("Error deleting local file: \(error)")
            }
        }
        
        currentClip = nil
    }

    private func setupVideoWriter() {
        guard let frameSize = frameSize else { return }
        guard let fileUrl = getClipFileUrl(timestamp: nil) else { return }
        
        do {
            videoWriter = try AVAssetWriter(outputURL: fileUrl, fileType: .mp4)
            
            let videoSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.hevc,
                AVVideoWidthKey: frameSize.width,
                AVVideoHeightKey: frameSize.height,
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: bitrate
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

            CVPixelBufferPoolCreate(nil, nil, sourcePixelBufferAttributes as CFDictionary, &pixelBufferPool)
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
            }
        }
    }

    private func appendFrameToVideo(_ cgImage: CGImage, at time: CMTime) {
        guard videoWriterInput != nil else {
            logger.error("Video writer input is nil")
            return
        }
        
        guard let pixelBufferAdaptor = pixelBufferAdaptor,
            let pixelBufferPool = pixelBufferPool else {
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
        
        if videoWriterInput != nil, videoWriterInput!.isReadyForMoreMediaData {
            pixelBufferAdaptor.append(buffer, withPresentationTime: time)
        }
    }
}

struct Clip {
    let id: String
    let startTime: Double
    var frameCount: Int64
}
