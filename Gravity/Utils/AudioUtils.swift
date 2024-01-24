//
//  AudioUtils.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/23/24.
//

import AVFoundation
import Foundation

func isValidAudioFile(url: URL) -> Bool {
    do {
        let _ = try AVAudioFile(forReading: url)
        return true
    } catch {
        print("Error: \(error.localizedDescription)")
        return false
    }
}
