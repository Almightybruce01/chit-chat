import Foundation
import AVFoundation
import ImageIO
import UniformTypeIdentifiers

enum MediaConversionError: Error {
    case invalidVideoData
    case exportFailed
    case gifEncodingFailed
}

enum MediaConversionService {
    static func createFiveSecondLoopVideo(from sourceData: Data) async throws -> Data {
        let inputURL = temporaryURL(ext: "mp4")
        let outputURL = temporaryURL(ext: "mp4")
        try sourceData.write(to: inputURL, options: [.atomic])

        defer {
            try? FileManager.default.removeItem(at: inputURL)
            try? FileManager.default.removeItem(at: outputURL)
        }

        let asset = AVURLAsset(url: inputURL)
        guard let export = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetMediumQuality) else {
            throw MediaConversionError.invalidVideoData
        }

        let durationSeconds = CMTimeGetSeconds(asset.duration)
        let trimmed = max(0.8, min(5.0, durationSeconds.isFinite ? durationSeconds : 5.0))
        export.outputURL = outputURL
        export.outputFileType = .mp4
        export.shouldOptimizeForNetworkUse = true
        export.timeRange = CMTimeRange(start: .zero, duration: CMTime(seconds: trimmed, preferredTimescale: 600))

        try await withCheckedThrowingContinuation { continuation in
            export.exportAsynchronously {
                switch export.status {
                case .completed:
                    continuation.resume(returning: ())
                default:
                    continuation.resume(throwing: export.error ?? MediaConversionError.exportFailed)
                }
            }
        }

        guard let exported = try? Data(contentsOf: outputURL), !exported.isEmpty else {
            throw MediaConversionError.exportFailed
        }
        return exported
    }

    static func createGIF(from sourceData: Data, maxDuration: Double = 5.0, fps: Int = 10) async throws -> Data {
        let inputURL = temporaryURL(ext: "mp4")
        try sourceData.write(to: inputURL, options: [.atomic])
        defer { try? FileManager.default.removeItem(at: inputURL) }

        let asset = AVURLAsset(url: inputURL)
        let durationSeconds = CMTimeGetSeconds(asset.duration)
        let usableDuration = max(0.5, min(maxDuration, durationSeconds.isFinite ? durationSeconds : maxDuration))
        let totalFrames = max(8, Int(usableDuration * Double(max(4, fps))))

        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 360, height: 640)

        let frameDelay = 1.0 / Double(max(4, fps))
        let times: [NSValue] = (0..<totalFrames).map { index in
            let seconds = min(usableDuration, Double(index) * frameDelay)
            return NSValue(time: CMTime(seconds: seconds, preferredTimescale: 600))
        }

        let gifData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(gifData, UTType.gif.identifier as CFString, totalFrames, nil) else {
            throw MediaConversionError.gifEncodingFailed
        }

        let gifProperties: [CFString: Any] = [
            kCGImagePropertyGIFDictionary: [
                kCGImagePropertyGIFLoopCount: 0
            ]
        ]
        CGImageDestinationSetProperties(destination, gifProperties as CFDictionary)

        let frameProps: [CFString: Any] = [
            kCGImagePropertyGIFDictionary: [
                kCGImagePropertyGIFDelayTime: frameDelay
            ]
        ]

        for time in times {
            let cg = try generator.copyCGImage(at: time.timeValue, actualTime: nil)
            CGImageDestinationAddImage(destination, cg, frameProps as CFDictionary)
        }

        guard CGImageDestinationFinalize(destination) else {
            throw MediaConversionError.gifEncodingFailed
        }
        return gifData as Data
    }

    private static func temporaryURL(ext: String) -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(ext)
    }
}
