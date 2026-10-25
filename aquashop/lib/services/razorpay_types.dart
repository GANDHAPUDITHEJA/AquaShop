enum PayStatus { paid, failed, unsupported }

class PayResult {
  final PayStatus status;
  final String? paymentId, message;
  const PayResult(this.status, {this.paymentId, this.message});
}
