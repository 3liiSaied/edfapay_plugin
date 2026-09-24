import Foundation
import Flutter
import PassKit
import UIKit

final class ApplePayHandler: NSObject, PKPaymentAuthorizationControllerDelegate {
  private var flutterResult: FlutterResult?

  func start(
    amount: Double,
    merchantIdentifier: String,
    result: @escaping FlutterResult
  ) {
    guard PKPaymentAuthorizationController.canMakePayments() else {
      result(FlutterError(
        code: "APPLE_PAY_UNAVAILABLE",
        message: "Apple Pay is not available on this device.",
        details: nil
      ))
      return
    }

    let request = PKPaymentRequest()
    request.merchantIdentifier = merchantIdentifier
    request.countryCode = "SA"
    request.currencyCode = "SAR"
    request.supportedNetworks = [.visa, .masterCard, .amex]
    request.merchantCapabilities = .capability3DS
    request.paymentSummaryItems = [
      PKPaymentSummaryItem(
        label: "EdfaPay order",
        amount: NSDecimalNumber(value: amount)
      )
    ]

    flutterResult = result
    let controller = PKPaymentAuthorizationController(paymentRequest: request)
    controller.delegate = self

    controller.present { presented in
      if !presented {
        self.finishWithError(
          code: "APPLE_PAY_PRESENTATION_FAILED",
          message: "Apple Pay could not be presented."
        )
      }
    }
  }

  func paymentAuthorizationController(
    _ controller: PKPaymentAuthorizationController,
    didAuthorizePayment payment: PKPayment,
    handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
  ) {
    let token = payment.token.paymentData.base64EncodedString()
    flutterResult?(["token": token])
    flutterResult = nil
    completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
  }

  func paymentAuthorizationControllerDidFinish(
    _ controller: PKPaymentAuthorizationController
  ) {
    controller.dismiss {
      if self.flutterResult != nil {
        self.finishWithError(
          code: "APPLE_PAY_CANCELLED",
          message: "Apple Pay was cancelled."
        )
      }
    }
  }

  private func finishWithError(code: String, message: String) {
    flutterResult?(FlutterError(code: code, message: message, details: nil))
    flutterResult = nil
  }
}
