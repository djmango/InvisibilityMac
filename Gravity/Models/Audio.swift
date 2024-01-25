import Foundation
import SwiftData
import SwiftWhisper

@Model
final class AudioSegment: Identifiable {
    /// Unique identifier for the audio segment
    @Attribute(.unique) var id: UUID = UUID()
    /// Index of the segment in the audio
    @Attribute var index: Int
    /// The end time of the segment in milliseconds
    @Attribute let endTime: Int
    /// The start time of the segment in milliseconds
    @Attribute let startTime: Int
    /// The text of the segment
    @Attribute let text: String
    /// The audio the segment belongs to
    @Relationship var audio: Audio

    init(index: Int, endTime: Int, startTime: Int, text: String, audio: Audio) {
        self.index = index
        self.endTime = endTime
        self.startTime = startTime
        self.text = text
        self.audio = audio
    }

    /// Create an array of `AudioSegment` from an array of `Segment`
    static func fromSegments(segments: [Segment], audio: Audio) -> [AudioSegment] {
        segments.enumerated().map { index, segment in
            AudioSegment(index: index, endTime: segment.endTime, startTime: segment.startTime, text: segment.text, audio: audio)
        }
    }
}

@Model
final class Audio: Identifiable {
    /// Unique identifier for the audio
    @Attribute(.unique) var id: UUID = UUID()
    /// Name of the audio
    var name: String = ""
    /// Datetime the audio was created
    var createdAt: Date = Date.now
    /// Whether the audio processing has been completed
    var completed: Bool = false
    /// The progress of the audio processing
    var progress: Double = 0.0
    /// Whether the audio processing has errored
    var error: Bool = false
    /// The segments of the audio
    @Relationship(deleteRule: .cascade, inverse: \AudioSegment.audio) var segments: [AudioSegment] = []
    /// The WAV audio file, stored externally
    @Attribute(.externalStorage) var audioFile: Data
    /// The parent message of the audio
    @Relationship var message: Message?

    init(audioFile: Data) {
        self.audioFile = audioFile
    }

    /// The transcribed text of the audio
    @Transient var text: String {
        segments.map(\.text).joined(separator: " ")
    }

    /// The text of the last segment of the audio
    // @Transient var lastSegmentText: String {
    //     print("segments: \(segments.count)")
    //     return segments.last?.text ?? ""
    // }

    var lastSegmentText: String?
}
