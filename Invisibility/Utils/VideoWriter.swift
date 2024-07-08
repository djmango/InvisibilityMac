//
//  VideoWriter.swift
//  Invisibility
//
//  Created by Braeden Hall on 7/8/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import Foundation
import AVFoundation
import ScreenCaptureKit

class VideoWriter {

    private let logger = InvisibilityLogger(subsystem: AppConfig.subsystem, category: "VideoWriter")

    // Tools for saving video recordings
    private var videoWriter: AVAssetWriter?
    private var videoWriterInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    
    func setupVideoWriter(outputURL: URL, frameSize: CGSize) {
        do {
            videoWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
            
            let videoSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: frameSize.width,
                AVVideoHeightKey: frameSize.height
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
