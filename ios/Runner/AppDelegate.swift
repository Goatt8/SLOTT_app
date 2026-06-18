import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let dailyVideoExporter = DailyVideoExporter()
  private var didRegisterDailyVideoExportChannel = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let launched = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    DispatchQueue.main.async { [weak self] in
      self?.registerDailyVideoExportChannelIfPossible()
    }
    return launched
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  func registerDailyVideoExportChannelIfPossible() {
    if didRegisterDailyVideoExportChannel {
      return
    }

    if let controller = window?.rootViewController as? FlutterViewController {
      registerDailyVideoExportChannel(with: controller)
      return
    }

    let controller = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }?
      .rootViewController as? FlutterViewController

    if let controller {
      registerDailyVideoExportChannel(with: controller)
    }
  }

  func registerDailyVideoExportChannel(with controller: FlutterViewController) {
    if didRegisterDailyVideoExportChannel {
      return
    }
    didRegisterDailyVideoExportChannel = true

    let channel = FlutterMethodChannel(
      name: "slott/daily_video_export",
      binaryMessenger: controller.binaryMessenger
    )

    channel.setMethodCallHandler { [dailyVideoExporter] call, result in
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
          result(outputPath)
        } catch {
          result(FlutterError(
            code: "export_failed",
            message: error.localizedDescription,
            details: String(describing: error)
          ))
        }
      }
    }
  }
}
