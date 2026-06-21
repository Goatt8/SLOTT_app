import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let dailyVideoExporter = DailyVideoExporter()
  private let postVideoTransformer = PostVideoTransformer()
  private var didRegisterVideoChannels = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let launched = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    DispatchQueue.main.async { [weak self] in
      self?.registerVideoChannelsIfPossible()
    }
    return launched
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  func registerVideoChannelsIfPossible() {
    if didRegisterVideoChannels {
      return
    }

    if let controller = window?.rootViewController as? FlutterViewController {
      registerVideoChannels(with: controller)
      return
    }

    let controller = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }?
      .rootViewController as? FlutterViewController

    if let controller {
      registerVideoChannels(with: controller)
    }
  }

  func registerVideoChannels(with controller: FlutterViewController) {
    if didRegisterVideoChannels {
      return
    }
    didRegisterVideoChannels = true

    let dailyVideoExportChannel = FlutterMethodChannel(
      name: "slott/daily_video_export",
      binaryMessenger: controller.binaryMessenger
    )

    dailyVideoExportChannel.setMethodCallHandler { [dailyVideoExporter] call, result in
      guard call.method == "exportDailyVideo" else {
        result(FlutterMethodNotImplemented)
        return
      }

      guard let arguments = call.arguments as? [String: Any] else {
        result(FlutterError(code: "bad_args", message: "Invalid export arguments", details: nil))
        return
      }

      Task {
        do {
          let outputPath = try await dailyVideoExporter.export(arguments: arguments)
          await MainActor.run {
            result(outputPath)
          }
        } catch {
          await MainActor.run {
            result(FlutterError(
              code: "export_failed",
              message: error.localizedDescription,
              details: String(describing: error)
            ))
          }
        }
      }
    }

    let postVideoTransformChannel = FlutterMethodChannel(
      name: "slott/post_video_transform",
      binaryMessenger: controller.binaryMessenger
    )

    postVideoTransformChannel.setMethodCallHandler { [postVideoTransformer] call, result in
      guard call.method == "exportLandscapeCopy" else {
        result(FlutterMethodNotImplemented)
        return
      }

      guard
        let arguments = call.arguments as? [String: Any],
        let inputPath = arguments["inputPath"] as? String
      else {
        result(FlutterError(code: "bad_args", message: "Invalid transform arguments", details: nil))
        return
      }

      Task {
        do {
          let outputPath = try await postVideoTransformer.exportLandscapeCopy(inputPath: inputPath)
          await MainActor.run {
            result(outputPath)
          }
        } catch {
          await MainActor.run {
            result(FlutterError(
              code: "transform_failed",
              message: error.localizedDescription,
              details: String(describing: error)
            ))
          }
        }
      }
    }
  }
}
