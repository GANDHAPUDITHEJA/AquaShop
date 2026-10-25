import 'dart:async';

import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../config.dart';
import 'razorpay_types.dart';

Future<PayResult> payWithRazorpay({
  required double amount,
  required String email,
}) {
  final razorpay = Razorpay();
  final result = Completer<PayResult>();

  void complete(PayResult payment) {
    if (!result.isCompleted) {
      result.complete(payment);
      razorpay.clear();
    }
  }

  razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS,
      (PaymentSuccessResponse response) {
    complete(PayResult(PayStatus.paid, paymentId: response.paymentId));
  });
  razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
    complete(PayResult(PayStatus.failed, message: response.message));
  });
  razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET,
      (ExternalWalletResponse response) {
    complete(PayResult(
      PayStatus.failed,
      message: 'External wallet selected: ${response.walletName ?? 'unknown'}',
    ));
  });

  razorpay.open({
    'key': razorpayKeyId,
    'amount': (amount * 100).round(),
    'currency': 'INR',
    'name': 'AquaShop',
    'description': 'AquaShop order payment',
    'prefill': {'email': email},
    'theme': {'color': '#0288D1'},
  });

  return result.future;
}
