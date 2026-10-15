import Cocoa
import FlutterMacOS
import AVFoundation

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // Lets Dart bring the window forward when a system notification is clicked.
    let windowChannel = FlutterMethodChannel(
      name: "roh_erp/window",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    windowChannel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "bringToFront", let window = self else {
        result(FlutterMethodNotImplemented)
        return
      }
      if window.isMiniaturized {
        window.deminiaturize(nil)
      }
      NSApp.activate(ignoringOtherApps: true)
      window.makeKeyAndOrderFront(nil)
      result(nil)
    }

    // Camera / microphone permissions (permission_handler has no macOS support).
    let permissionChannel = FlutterMethodChannel(
      name: "roh_erp/permissions",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    permissionChannel.setMethodCallHandler { call, result in
      let type = (call.arguments as? String) ?? ""
      let media: AVMediaType? = type == "camera" ? .video : (type == "microphone" ? .audio : nil)
      switch call.method {
      case "status":
        guard let media = media else { result("denied"); return }
        switch AVCaptureDevice.authorizationStatus(for: media) {
        case .authorized: result("granted")
        case .notDetermined: result("notDetermined")
        case .restricted: result("restricted")
        default: result("denied")
        }
      case "request":
        guard let media = media else { result(false); return }
        AVCaptureDevice.requestAccess(for: media) { granted in
          DispatchQueue.main.async { result(granted) }
        }
      case "openSettings":
        let pane: String
        switch type {
        case "camera": pane = "com.apple.preference.security?Privacy_Camera"
        case "microphone": pane = "com.apple.preference.security?Privacy_Microphone"
        default: pane = "com.apple.Notifications-Settings.extension"
        }
        if let url = URL(string: "x-apple.systempreferences:\(pane)") {
          NSWorkspace.shared.open(url)
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    super.awakeFromNib()
  }
}
