import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {

  private let recordingOverlayTag = 987655

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    GeneratedPluginRegistrant.register(with: self)
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    // بعد ما Flutter يجهز الـ window
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }

      // ابدأ مراقبة تسجيل الشاشة
      self.startScreenRecordingDetection()

      // لو التسجيل شغال بالفعل وقت فتح التطبيق
      self.updateRecordingProtectionOverlay()
    }

    return result
  }

  // MARK: - Screen Recording Detection

  private func startScreenRecordingDetection() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(screenRecordingStatusChanged),
      name: UIScreen.capturedDidChangeNotification,
      object: nil
    )
  }

  @objc private func screenRecordingStatusChanged() {
    updateRecordingProtectionOverlay()
  }

  private func updateRecordingProtectionOverlay() {
    if UIScreen.main.isCaptured {
      // ✅ التسجيل شغال → غطي المحتوى بسواد
      showRecordingOverlay()
    } else {
      // ✅ التسجيل وقف → شيل الغطاء
      hideRecordingOverlay()
    }
  }

  private func showRecordingOverlay() {
    guard let window = self.window else { return }

    // منع التكرار
    if window.viewWithTag(recordingOverlayTag) != nil { return }

    let overlay = UIView(frame: window.bounds)
    overlay.tag = recordingOverlayTag
    overlay.backgroundColor = .black
    overlay.isUserInteractionEnabled = true // يخلي المستخدم مش قادر يتفاعل مع المحتوى أثناء التسجيل

    // لو عايز رسالة بدل السواد فقط، ممكن تضيف UILabel هنا (بس انت قلت أسود)
    window.addSubview(overlay)
    overlay.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      overlay.leadingAnchor.constraint(equalTo: window.leadingAnchor),
      overlay.trailingAnchor.constraint(equalTo: window.trailingAnchor),
      overlay.topAnchor.constraint(equalTo: window.topAnchor),
      overlay.bottomAnchor.constraint(equalTo: window.bottomAnchor),
    ])
  }

  private func hideRecordingOverlay() {
    guard let window = self.window else { return }
    window.viewWithTag(recordingOverlayTag)?.removeFromSuperview()
  }

  // MARK: - App Switcher (اختياري لكن مفيد)
  // يخفي لقطة الـ App Switcher (مش تسجيل الشاشة)

  override func applicationWillResignActive(_ application: UIApplication) {
    // لو انت مش عايز تأثير على الـ App Switcher، امسح السطرين دول
    showAppSwitcherPrivacyOverlay()
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    hideAppSwitcherPrivacyOverlay()
    // لو التسجيل شغال ورجعت للتطبيق، رجّع حماية التسجيل
    updateRecordingProtectionOverlay()
  }

  private let appSwitcherOverlayTag = 987656

  private func showAppSwitcherPrivacyOverlay() {
    guard let window = self.window else { return }
    if window.viewWithTag(appSwitcherOverlayTag) != nil { return }

    let overlay = UIView(frame: window.bounds)
    overlay.tag = appSwitcherOverlayTag
    overlay.backgroundColor = .black
    overlay.isUserInteractionEnabled = false

    window.addSubview(overlay)
    overlay.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      overlay.leadingAnchor.constraint(equalTo: window.leadingAnchor),
      overlay.trailingAnchor.constraint(equalTo: window.trailingAnchor),
      overlay.topAnchor.constraint(equalTo: window.topAnchor),
      overlay.bottomAnchor.constraint(equalTo: window.bottomAnchor),
    ])
  }

  private func hideAppSwitcherPrivacyOverlay() {
    guard let window = self.window else { return }
    window.viewWithTag(appSwitcherOverlayTag)?.removeFromSuperview()
  }
}
