// Mobile builds use Razorpay; web builds use a stub (plugin has no web support).
export 'razorpay_types.dart';
export 'razorpay_stub.dart' if (dart.library.io) 'razorpay_mobile.dart';
