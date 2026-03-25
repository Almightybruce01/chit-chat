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

        let assetDuration = try await asset.load(.duration)
        let durationSeconds = CMTimeGetSeconds(assetDuration)
        let trimmed = max(0.8, min(5.0, durationSeconds.isFinite ? durationSeconds : 5.0))
        export.outputURL = outputURL
        export.outputFileType = .mp4
        export.shouldOptimizeForNetworkUse = true
        export.timeRange = CMTimeRange(start: .zero, duration: CMTime(seconds: trimmed, preferredTimescale: 600))
        try await exportVideo(export, to: outputURL)

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
        let assetDuration = try await asset.load(.duration)
        let durationSeconds = CMTimeGetSeconds(assetDuration)
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
            let cg = try await generateFrame(generator, at: time.timeValue)
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

    private static func exportVideo(_ export: AVAssetExportSession, to outputURL: URL) async throws {
        if #available(iOS 18.0, *) {
            do {
                try await export.export(to: outputURL, as: .mp4)
                return
            } catch {
                throw MediaConversionError.exportFailed
            }
        }
        try await exportVideoLegacy(export)
    }

    private static func generateFrame(_ generator: AVAssetImageGenerator, at time: CMTime) async throws -> CGImage {
        if #available(iOS 18.0, *) {
            return try await withCheckedThrowingContinuation { continuation in
                generator.generateCGImageAsynchronously(for: time) { cgImage, _, error in
                    if let cgImage {
                        continuation.resume(returning: cgImage)
                    } else {
                        continuation.resume(throwing: error ?? MediaConversionError.gifEncodingFailed)
                    }
                }
            }
        }
        return try copyFrameLegacy(generator, at: time)
    }

    @available(iOS, introduced: 13.0)
    private static func exportVideoLegacy(_ export: AVAssetExportSession) async throws {
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
    }

    @available(iOS, introduced: 13.0)
    private static func copyFrameLegacy(_ generator: AVAssetImageGenerator, at time: CMTime) throws -> CGImage {
        try generator.copyCGImage(at: time, actualTime: nil)
    }
}
