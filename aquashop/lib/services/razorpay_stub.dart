import 'razorpay_types.dart';

Future<PayResult> payWithRazorpay({required double amount, required String email}) async =>
    const PayResult(PayStatus.unsupported);
