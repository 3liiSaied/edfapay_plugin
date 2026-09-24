import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let applePayHandler = ApplePayHandler()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: "edfapay_plugin/apple_pay",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )

    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "start" else {
        result(FlutterMethodNotImplemented)
        return
      }

      guard
        let arguments = call.arguments as? [String: Any],
        let amount = arguments["amount"] as? NSNumber,
        let merchantIdentifier = arguments["merchantIdentifier"] as? String,
        !merchantIdentifier.isEmpty
      else {
        result(FlutterError(
          code: "INVALID_APPLE_PAY_ARGUMENTS",
          message: "Apple Pay amount and merchant identifier are required.",
          details: nil
        ))
        return
      }

      self?.applePayHandler.start(
        amount: amount.doubleValue,
        merchantIdentifier: merchantIdentifier,
        result: result
      )
    }
  }
}
