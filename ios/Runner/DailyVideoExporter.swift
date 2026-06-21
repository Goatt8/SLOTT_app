import AVFoundation
import CoreText
import Photos
import UIKit

final class DailyVideoExporter {
    private let renderSize = CGSize(width: 1080, height: 1920)
    private let pageDuration = CMTime(seconds: 3, preferredTimescale: 600)
    
    func export(arguments: [String: Any]) async throws -> String {
        let request = try DailyVideoExportRequest(arguments: arguments)
        try registerFontFiles()
        
        let workDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("slott_daily_export_\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(
            at: workDirectory,
            withIntermediateDirectories: true
        )
        
        defer {
            try? FileManager.default.removeItem(at: workDirectory)
        }
        
        var pageUrls: [URL] = []
        for (index, page) in request.pages.enumerated() {
            let pageUrl = workDirectory.appendingPathComponent("page_\(index).mp4")
            try await exportPage(
                page,
                request: request,
                outputUrl: pageUrl
            )
            pageUrls.append(pageUrl)
        }
        
        let outputUrl = FileManager.default.temporaryDirectory
            .appendingPathComponent("slott_daily_\(UUID().uuidString).mp4")
        
        try await concatenateVideos(pageUrls: pageUrls, outputUrl: outputUrl)
        try await saveToPhotoLibrary(outputUrl)
        return outputUrl.path
    }
    
    private func exportPage(
        _ page: DailyVideoExportPage,
        request: DailyVideoExportRequest,
        outputUrl: URL
    ) async throws {
        let composition = AVMutableComposition()
        var instructions: [AVMutableVideoCompositionLayerInstruction] = []
        
        var hasAtLeastOneVideo = false
        
        for slot in page.slots {
            guard
                let videoPath = slot.videoPath,
                !videoPath.isEmpty,
                slot.videoRect.width > 0,
                slot.videoRect.height > 0
            else {
                continue
            }
            
            let asset = AVURLAsset(url: URL(fileURLWithPath: videoPath))
            let tracks = try await asset.loadTracks(withMediaType: .video)
            guard let sourceTrack = tracks.first else { continue }
            
            let duration = min(try await asset.load(.duration), pageDuration)
            guard duration.seconds > 0 else { continue }

            guard let compositionVideoTrack = composition.addMutableTrack(
                withMediaType: .video,
                preferredTrackID: kCMPersistentTrackID_Invalid
            ) else {
                throw DailyVideoExportError.exportFailed
            }
            
            try compositionVideoTrack.insertTimeRange(
                CMTimeRange(start: .zero, duration: duration),
                of: sourceTrack,
                at: .zero
            )

            if request.includeAudio && slot.includeAudio {
                try await insertAudioTracks(
                    from: asset,
                    into: composition,
                    duration: duration,
                    at: .zero
                )
            }
            
            if duration < pageDuration {
                compositionVideoTrack.scaleTimeRange(
                    CMTimeRange(start: .zero, duration: duration),
                    toDuration: pageDuration
                )
            }
            
            hasAtLeastOneVideo = true
            
            let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
            let naturalSize = try await sourceTrack.load(.naturalSize)
            let preferredTransform = try await sourceTrack.load(.preferredTransform)
            let placement = aspectFillPlacement(
                naturalSize: naturalSize,
                preferredTransform: preferredTransform,
                targetRect: slot.videoRect
            )
            instruction.setTransform(placement.transform, at: .zero)
            instruction.setCropRectangle(placement.cropRect, at: .zero)
            instructions.append(instruction)
        }
        
        if !hasAtLeastOneVideo {
            guard let compositionVideoTrack = composition.addMutableTrack(
                withMediaType: .video,
                preferredTrackID: kCMPersistentTrackID_Invalid
            ) else {
                throw DailyVideoExportError.exportFailed
            }
            let emptyRange = CMTimeRange(start: .zero, duration: pageDuration)
            compositionVideoTrack.insertEmptyTimeRange(emptyRange)
        }
        
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRange(start: .zero, duration: pageDuration)
        mainInstruction.layerInstructions = instructions.reversed()
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = renderSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.instructions = [mainInstruction]
        
        let parentLayer = CALayer()
        parentLayer.frame = CGRect(origin: .zero, size: renderSize)
        
        let videoLayer = CALayer()
        videoLayer.frame = parentLayer.frame
        parentLayer.addSublayer(videoLayer)
        
        let overlayLayer = buildOverlayLayer(
            page: page
        )
        overlayLayer.frame = CGRect(origin: .zero, size: renderSize)
        parentLayer.addSublayer(overlayLayer)
        
        videoLayer.zPosition = 0
        overlayLayer.zPosition = 1
        
        parentLayer.isGeometryFlipped = true
        
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
            postProcessingAsVideoLayer: videoLayer,
            in: parentLayer
        )
        
        try await exportComposition(
            composition,
            videoComposition: videoComposition,
            outputUrl: outputUrl
        )
    }
    
    private func concatenateVideos(pageUrls: [URL], outputUrl: URL) async throws {
        let composition = AVMutableComposition()
        guard let outputTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            throw DailyVideoExportError.exportFailed
        }
        
        var cursor = CMTime.zero
        
        for url in pageUrls {
            let asset = AVURLAsset(url: url)
            let tracks = try await asset.loadTracks(withMediaType: .video)
            guard let sourceTrack = tracks.first else { continue }
            let duration = try await asset.load(.duration)
            
            try outputTrack.insertTimeRange(
                CMTimeRange(start: .zero, duration: duration),
                of: sourceTrack,
                at: cursor
            )

            try await insertAudioTracks(
                from: asset,
                into: composition,
                duration: duration,
                at: cursor
            )
            
            cursor = cursor + duration
        }

        try await exportComposition(
            composition,
            videoComposition: nil,
            outputUrl: outputUrl
        )
    }
    
    private func exportComposition(
        _ composition: AVMutableComposition,
        videoComposition: AVMutableVideoComposition?,
        outputUrl: URL
    ) async throws {
        if FileManager.default.fileExists(atPath: outputUrl.path) {
            try FileManager.default.removeItem(at: outputUrl)
        }
        
        guard let exporter = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality
        ) else {
            throw DailyVideoExportError.exportFailed
        }
        
        exporter.outputURL = outputUrl
        exporter.outputFileType = .mp4
        exporter.shouldOptimizeForNetworkUse = true
        exporter.videoComposition = videoComposition
        
        await exporter.export()
        
        if exporter.status != .completed {
            throw exporter.error ?? DailyVideoExportError.exportFailed
        }
    }

    private func insertAudioTracks(
        from asset: AVURLAsset,
        into composition: AVMutableComposition,
        duration: CMTime,
        at startTime: CMTime
    ) async throws {
        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
        guard duration.seconds > 0 else { return }

        for sourceAudioTrack in audioTracks {
            let audioTimeRange = try await sourceAudioTrack.load(.timeRange)
            let audioDuration = min(duration, audioTimeRange.duration)
            guard audioDuration.seconds > 0 else { continue }

            guard let compositionAudioTrack = composition.addMutableTrack(
                withMediaType: .audio,
                preferredTrackID: kCMPersistentTrackID_Invalid
            ) else {
                throw DailyVideoExportError.exportFailed
            }

            try compositionAudioTrack.insertTimeRange(
                CMTimeRange(start: audioTimeRange.start, duration: audioDuration),
                of: sourceAudioTrack,
                at: startTime
            )

            if startTime == .zero && audioDuration < pageDuration {
                compositionAudioTrack.scaleTimeRange(
                    CMTimeRange(start: startTime, duration: audioDuration),
                    toDuration: pageDuration
                )
            }
        }
    }
    
    private func saveToPhotoLibrary(_ url: URL) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw DailyVideoExportError.photoPermissionDenied
        }
        
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }
    }
    
    private func buildOverlayLayer(
        page: DailyVideoExportPage
    ) -> CALayer {
        let overlay = CALayer()
        overlay.frame = CGRect(origin: .zero, size: renderSize)

        for slot in page.slots {
            if !slot.hasVideo {
                let backgroundLayer = CALayer()
                backgroundLayer.frame = slot.videoRect
                backgroundLayer.backgroundColor = UIColor(white: 0.08, alpha: 1).cgColor
                overlay.addSublayer(backgroundLayer)
            }

            let hourLayer = textLayer(
                text: slot.hourText,
                fontName: fontPostScriptName(for: slot.hourFontId),
                fontSize: slot.hourFontSize,
                color: slot.hourColor
            )

            hourLayer.frame = slot.hourRect
            overlay.addSublayer(hourLayer)

            guard !slot.commentText.isEmpty else { continue }
            
            let commentLayer = textLayer(
                text: slot.commentText,
                fontName: fontPostScriptName(for: slot.commentFontId),
                fontSize: slot.commentFontSize,
                color: slot.commentColor
            )

            commentLayer.frame = slot.commentRect
            overlay.addSublayer(commentLayer)
        }
        
        return overlay
    }
    
    private func textLayer(
        text: String,
        fontName: String,
        fontSize: CGFloat,
        color: UIColor
    ) -> CATextLayer {
        let layer = CATextLayer()
        layer.string = text
        layer.alignmentMode = .center
        layer.contentsScale = UIScreen.main.scale
        layer.foregroundColor = color.cgColor
        layer.isWrapped = true
        layer.truncationMode = .end
        
        let font = CTFontCreateWithName(fontName as CFString, fontSize, nil)
        layer.font = font
        layer.fontSize = fontSize
        return layer
    }
    
    private func aspectFillPlacement(
        naturalSize: CGSize,
        preferredTransform: CGAffineTransform,
        targetRect: CGRect
    ) -> VideoPlacement {
        let transformedRect = CGRect(origin: .zero, size: naturalSize).applying(preferredTransform)
        let videoSize = CGSize(width: abs(transformedRect.width), height: abs(transformedRect.height))
        guard videoSize.width > 0 && videoSize.height > 0 else {
            return VideoPlacement(
                transform: preferredTransform,
                cropRect: CGRect(origin: .zero, size: naturalSize)
            )
        }

        let targetAspect = targetRect.width / targetRect.height
        let videoAspect = videoSize.width / videoSize.height
        let cropSize: CGSize
        if videoAspect > targetAspect {
            cropSize = CGSize(width: videoSize.height * targetAspect, height: videoSize.height)
        } else {
            cropSize = CGSize(width: videoSize.width, height: videoSize.width / targetAspect)
        }

        let cropDisplayRect = CGRect(
            x: (videoSize.width - cropSize.width) / 2,
            y: (videoSize.height - cropSize.height) / 2,
            width: cropSize.width,
            height: cropSize.height
        )

        let normalizeTransform = preferredTransform.concatenating(CGAffineTransform(
            translationX: -transformedRect.minX,
            y: -transformedRect.minY
        ))
        let cropSourceRect = cropDisplayRect
            .applying(normalizeTransform.inverted())
            .standardized
            .intersection(CGRect(origin: .zero, size: naturalSize))
        let scale = targetRect.width / cropDisplayRect.width

        let transform = normalizeTransform
            .concatenating(CGAffineTransform(
                translationX: -cropDisplayRect.minX,
                y: -cropDisplayRect.minY
            ))
            .concatenating(CGAffineTransform(scaleX: scale, y: scale))
            .concatenating(CGAffineTransform(
                translationX: targetRect.minX,
                y: targetRect.minY
            ))

        return VideoPlacement(transform: transform, cropRect: cropSourceRect)
    }
    
    private func registerFontFiles() throws {
        for preset in NativeFontPreset.all.values {
            guard let url = flutterAssetUrl(path: "functions/assets/fonts/\(preset.file)") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
    
    private func flutterAssetUrl(path: String) -> URL? {
        if let appFrameworkPath = Bundle.main.path(forResource: "App", ofType: "framework", inDirectory: "Frameworks") {
            let url = URL(fileURLWithPath: appFrameworkPath).appendingPathComponent("flutter_assets").appendingPathComponent(path)
            if FileManager.default.fileExists(atPath: url.path) { return url }
        }
        let fallback = Bundle.main.bundleURL.appendingPathComponent("flutter_assets").appendingPathComponent(path)
        return FileManager.default.fileExists(atPath: fallback.path) ? fallback : nil
    }
    
    private func fontPostScriptName(for id: String) -> String {
        NativeFontPreset.all[id]?.postScriptName ?? NativeFontPreset.all["doHyeon"]!.postScriptName
    }
    
}

private enum DailyVideoExportError: LocalizedError {
    case badArguments
    case exportFailed
    case photoPermissionDenied

    var errorDescription: String? {
        switch self {
        case .badArguments:
            return "Invalid daily video export arguments."
        case .exportFailed:
            return "Daily video export failed."
        case .photoPermissionDenied:
            return "Photo library permission is required to save the video."
        }
    }
}

private struct VideoPlacement {
    let transform: CGAffineTransform
    let cropRect: CGRect
}

final class PostVideoTransformer {
    func exportLandscapeCopy(inputPath: String) async throws -> String {
        let inputUrl = URL(fileURLWithPath: inputPath)
        let outputUrl = FileManager.default.temporaryDirectory
            .appendingPathComponent("slott_post_landscape_\(UUID().uuidString).mp4")

        let asset = AVURLAsset(url: inputUrl)
        let videoTracks = try await asset.loadTracks(withMediaType: .video)
        guard let sourceVideoTrack = videoTracks.first else {
            throw PostVideoTransformError.missingVideoTrack
        }

        let duration = try await asset.load(.duration)
        guard duration.seconds > 0 else {
            throw PostVideoTransformError.exportFailed
        }

        let naturalSize = try await sourceVideoTrack.load(.naturalSize)
        let preferredTransform = try await sourceVideoTrack.load(.preferredTransform)
        let transformedRect = CGRect(origin: .zero, size: naturalSize).applying(preferredTransform)
        let displaySize = CGSize(
            width: abs(transformedRect.width),
            height: abs(transformedRect.height)
        )
        guard displaySize.width > 0 && displaySize.height > 0 else {
            throw PostVideoTransformError.exportFailed
        }

        let renderSize = CGSize(
            width: max(displaySize.width, displaySize.height),
            height: min(displaySize.width, displaySize.height)
        )

        let composition = AVMutableComposition()
        guard let compositionVideoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            throw PostVideoTransformError.exportFailed
        }

        try compositionVideoTrack.insertTimeRange(
            CMTimeRange(start: .zero, duration: duration),
            of: sourceVideoTrack,
            at: .zero
        )

        try await insertAudioTracks(from: asset, into: composition, duration: duration)

        let normalizeTransform = preferredTransform.concatenating(CGAffineTransform(
            translationX: -transformedRect.minX,
            y: -transformedRect.minY
        ))

        let landscapeTransform = normalizeTransform.concatenating(
            CGAffineTransform(translationX: 0, y: renderSize.height)
                .rotated(by: -.pi / 2)
        )

        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
        instruction.setTransform(landscapeTransform, at: .zero)

        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRange(start: .zero, duration: duration)
        mainInstruction.layerInstructions = [instruction]

        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = renderSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.instructions = [mainInstruction]

        if FileManager.default.fileExists(atPath: outputUrl.path) {
            try FileManager.default.removeItem(at: outputUrl)
        }

        guard let exporter = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality
        ) else {
            throw PostVideoTransformError.exportFailed
        }

        exporter.outputURL = outputUrl
        exporter.outputFileType = .mp4
        exporter.shouldOptimizeForNetworkUse = true
        exporter.videoComposition = videoComposition

        await exporter.export()

        if exporter.status != .completed {
            throw exporter.error ?? PostVideoTransformError.exportFailed
        }

        return outputUrl.path
    }

    private func insertAudioTracks(
        from asset: AVURLAsset,
        into composition: AVMutableComposition,
        duration: CMTime
    ) async throws {
        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
        guard duration.seconds > 0 else { return }

        for sourceAudioTrack in audioTracks {
            guard let compositionAudioTrack = composition.addMutableTrack(
                withMediaType: .audio,
                preferredTrackID: kCMPersistentTrackID_Invalid
            ) else {
                throw PostVideoTransformError.exportFailed
            }

            let audioTimeRange = try await sourceAudioTrack.load(.timeRange)
            let audioDuration = min(duration, audioTimeRange.duration)
            guard audioDuration.seconds > 0 else { continue }

            try compositionAudioTrack.insertTimeRange(
                CMTimeRange(start: audioTimeRange.start, duration: audioDuration),
                of: sourceAudioTrack,
                at: .zero
            )
        }
    }
}

private enum PostVideoTransformError: LocalizedError {
    case missingVideoTrack
    case exportFailed

    var errorDescription: String? {
        switch self {
        case .missingVideoTrack:
            return "Post video has no video track."
        case .exportFailed:
            return "Post video landscape transform failed."
        }
    }
}

private struct DailyVideoExportRequest {
    let slotCount: Int
    let useDiceLayout: Bool
    let fontId: String
    let colorId: String
    let hourFontId: String
    let includeAudio: Bool
    let pages: [DailyVideoExportPage]

    init(arguments: [String: Any]) throws {
        guard
            let slotCount = arguments["slotCount"] as? Int,
            let pagesRaw = arguments["pages"] as? [[String: Any]]
        else {
            throw DailyVideoExportError.badArguments
        }

        self.slotCount = slotCount
        self.useDiceLayout = arguments["useDiceLayout"] as? Bool ?? false
        self.fontId = arguments["fontId"] as? String ?? "doHyeon"
        self.colorId = arguments["colorId"] as? String ?? "white"
        self.hourFontId = arguments["hourFontId"] as? String ?? "doHyeon"
        self.includeAudio = arguments["includeAudio"] as? Bool ?? true
        self.pages = try pagesRaw.map { try DailyVideoExportPage(arguments: $0) }
    }
}

private struct DailyVideoExportPage {
    let hour: Int
    let slots: [DailyVideoExportSlot]

    init(arguments: [String: Any]) throws {
        guard
            let hour = arguments["hour"] as? Int,
            let slotsRaw = arguments["slots"] as? [[String: Any]]
        else {
            throw DailyVideoExportError.badArguments
        }

        self.hour = hour
        self.slots = try slotsRaw.map { try DailyVideoExportSlot(arguments: $0) }
    }
}

private struct DailyVideoExportSlot {
    let slotIndex: Int
    let videoPath: String?
    let includeAudio: Bool
    let comment: String
    let hasVideo: Bool
    let videoRect: CGRect
    let hourText: String
    let hourRect: CGRect
    let hourFontId: String
    let hourFontSize: CGFloat
    let hourColor: UIColor
    let commentText: String
    let commentRect: CGRect
    let commentFontId: String
    let commentFontSize: CGFloat
    let commentColor: UIColor
    let maxCommentLines: Int

    init(arguments: [String: Any]) throws {
        guard let slotIndex = arguments["slotIndex"] as? Int else {
            throw DailyVideoExportError.badArguments
        }

        self.slotIndex = slotIndex
        self.videoPath = arguments["videoPath"] as? String
        self.includeAudio = arguments["includeAudio"] as? Bool ?? false
        self.comment = arguments["comment"] as? String ?? ""
        self.hasVideo = arguments["hasVideo"] as? Bool ?? false
        self.videoRect = try NativeExportValueParser.rect(arguments["videoRect"])
        self.hourText = arguments["hourText"] as? String ?? ""
        self.hourRect = try NativeExportValueParser.rect(arguments["hourRect"])
        self.hourFontId = arguments["hourFontId"] as? String ?? "doHyeon"
        self.hourFontSize = NativeExportValueParser.cgFloat(arguments["hourFontSize"]) ?? 88
        self.hourColor = NativeExportValueParser.color(arguments["hourColor"]) ?? .white
        self.commentText = arguments["commentText"] as? String ?? comment
        self.commentRect = try NativeExportValueParser.rect(arguments["commentRect"])
        self.commentFontId = arguments["commentFontId"] as? String ?? "doHyeon"
        self.commentFontSize = NativeExportValueParser.cgFloat(arguments["commentFontSize"]) ?? 55
        self.commentColor = NativeExportValueParser.color(arguments["commentColor"]) ?? .white
        self.maxCommentLines = arguments["maxCommentLines"] as? Int ?? 2
    }
}

private enum NativeExportValueParser {
    static func rect(_ value: Any?) throws -> CGRect {
        guard let map = value as? [String: Any],
              let x = cgFloat(map["x"]),
              let y = cgFloat(map["y"]),
              let width = cgFloat(map["width"]),
              let height = cgFloat(map["height"])
        else {
            throw DailyVideoExportError.badArguments
        }

        return CGRect(x: x, y: y, width: width, height: height)
    }

    static func cgFloat(_ value: Any?) -> CGFloat? {
        if let value = value as? CGFloat { return value }
        if let value = value as? Double { return CGFloat(value) }
        if let value = value as? Float { return CGFloat(value) }
        if let value = value as? Int { return CGFloat(value) }
        if let value = value as? NSNumber { return CGFloat(truncating: value) }
        return nil
    }

    static func color(_ value: Any?) -> UIColor? {
        guard let number = value as? NSNumber else { return nil }
        let argb = number.uint32Value
        let alpha = CGFloat((argb >> 24) & 0xff) / 255
        let red = CGFloat((argb >> 16) & 0xff) / 255
        let green = CGFloat((argb >> 8) & 0xff) / 255
        let blue = CGFloat(argb & 0xff) / 255
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}

private struct NativeFontPreset {
    let file: String
    let postScriptName: String
    let postScale: CGFloat
    let hourScale: CGFloat

    static let all: [String: NativeFontPreset] = [
        "doHyeon": NativeFontPreset(
            file: "DoHyeon-Regular.ttf",
            postScriptName: "Do Hyeon",
            postScale: 1,
            hourScale: 1
        ),
        "blacHanSans": NativeFontPreset(
            file: "BlackHanSans-Regular.ttf",
            postScriptName: "Black Han Sans",
            postScale: 1,
            hourScale: 1
        ),
        "bagelfatOne": NativeFontPreset(
            file: "BagelFatOne-Regular.ttf",
            postScriptName: "Bagel Fat One",
            postScale: 1,
            hourScale: 1
        ),
        "nanumPenScript": NativeFontPreset(
            file: "NanumPenScript-Regular.ttf",
            postScriptName: "Nanum Pen Script",
            postScale: 1.22,
            hourScale: 1
        ),
        "silkscreen": NativeFontPreset(
            file: "Silkscreen-Regular.ttf",
            postScriptName: "Silkscreen",
            postScale: 0.78,
            hourScale: 1
        ),
        "blackOpsOne": NativeFontPreset(
            file: "BlackOpsOne-Regular.ttf",
            postScriptName: "Black Ops One",
            postScale: 1,
            hourScale: 1
        ),
        "noto serif kr": NativeFontPreset(
            file: "NotoSerifKR-Regular.otf",
            postScriptName: "Noto Serif KR",
            postScale: 1,
            hourScale: 1
        ),
        "gowunBatang": NativeFontPreset(
            file: "GowunBatang-Regular.ttf",
            postScriptName: "Gowun Batang",
            postScale: 1,
            hourScale: 1
        ),
        "fredoka": NativeFontPreset(
            file: "Fredoka-Regular.ttf",
            postScriptName: "Fredoka",
            postScale: 1,
            hourScale: 1
        ),
        "PressStart2P": NativeFontPreset(
            file: "PressStart2P-Regular.ttf",
            postScriptName: "Press Start 2P",
            postScale: 1,
            hourScale: 0.82
        ),
        "orbitron": NativeFontPreset(
            file: "Orbitron-Regular.ttf",
            postScriptName: "Orbitron",
            postScale: 1,
            hourScale: 1
        ),
        "playfairDisplay": NativeFontPreset(
            file: "PlayfairDisplay-Regular.ttf",
            postScriptName: "Playfair Display",
            postScale: 1,
            hourScale: 1
        ),
        "cinzel": NativeFontPreset(
            file: "Cinzel-Regular.ttf",
            postScriptName: "Cinzel",
            postScale: 1,
            hourScale: 1
        )
    ]
}
