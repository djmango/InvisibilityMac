import Foundation
import SwiftData
import SwiftWhisper

struct AudioSegment: Codable {
    /// The end time of the segment in milliseconds
    @Attribute let endTime: Int
    /// The start time of the segment in milliseconds
    @Attribute let startTime: Int
    /// The text of the segment
    @Attribute let text: String

    static func fromSegments(segments: [Segment]) -> [AudioSegment] {
        segments.map { segment in
            AudioSegment(endTime: segment.endTime, startTime: segment.startTime, text: segment.text)
        }
    }
}

/// Status for message generation and processing
enum AudioStatus: String, Codable {
    case pending
    case processing
    case complete
    case error
}

@Model
final class Audio: Identifiable {
    /// Unique identifier for the audio
    @Attribute(.unique) var id: UUID = UUID()
    /// Name of the audio
    var name: String = ""
    /// Datetime the audio was created
    var createdAt: Date = Date.now
    /// The status of the audio processing
    var status: AudioStatus? = AudioStatus.pending
    /// The drafted email, if any
    var email: String?
    /// The text of the last segment of the audio
    @Attribute(.externalStorage) var segmentsData: Data?

    var segments: [AudioSegment] {
        get {
            // Decode the segments from the stored Data
            (try? JSONDecoder().decode([AudioSegment].self, from: segmentsData ?? Data())) ?? []
        }
        set {
            // Encode the segments to Data
            segmentsData = try? JSONEncoder().encode(newValue)
        }
    }

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
}
