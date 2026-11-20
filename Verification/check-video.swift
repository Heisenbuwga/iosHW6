import AVFoundation
import AppKit
let asset = AVURLAsset(url: URL(fileURLWithPath: CommandLine.arguments[1]))
let semaphore = DispatchSemaphore(value: 0)
Task {
    do {
        let duration = try await asset.load(.duration)
        print("Duration: \(CMTimeGetSeconds(duration)) seconds")
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        for seconds in [8.0, 15.0, 22.0, 28.0] {
            let result = try await generator.image(at: CMTime(seconds: min(seconds, CMTimeGetSeconds(duration)-0.5), preferredTimescale: 600))
            let rep = NSBitmapImageRep(cgImage: result.image)
            try rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[2] + "-\(Int(seconds)).png"))
        }
    } catch { print("ERROR: \(error)") }
    semaphore.signal()
}
semaphore.wait()
