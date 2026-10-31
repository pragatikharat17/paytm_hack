class PaymentItem {
  final int? id;
  final String paymentId;
  final String orderId;
  final String customerId;
  final double amount;
  final String currency;
  final String method;
  final String status;
  final String? bankRef;
  final String gatewayStatus;
  final String bankStatus;
  final String? failureReason;
  final DateTime? createdAt;

  PaymentItem({
    this.id,
    required this.paymentId,
    required this.orderId,
    required this.customerId,
    required this.amount,
    this.currency = 'INR',
    this.method = 'UPI',
    required this.status,
    this.bankRef,
    required this.gatewayStatus,
    required this.bankStatus,
    this.failureReason,
    this.createdAt,
  });

  factory PaymentItem.fromJson(Map<String, dynamic> json) {
    return PaymentItem(
      id: json['id'],
      paymentId: json['payment_id'] ?? '',
      orderId: json['order_id'] ?? '',
      customerId: json['customer_id'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'INR',
      method: json['method'] ?? 'UPI',
      status: json['status'] ?? 'PENDING',
      bankRef: json['bank_ref'],
      gatewayStatus: json['gateway_status'] ?? 'PENDING',
      bankStatus: json['bank_status'] ?? 'DEBITED',
      failureReason: json['failure_reason'],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'payment_id': paymentId,
    'order_id': orderId,
    'customer_id': customerId,
    'amount': amount,
    'currency': currency,
    'method': method,
    'status': status,
    'bank_ref': bankRef,
    'gateway_status': gatewayStatus,
    'bank_status': bankStatus,
    'failure_reason': failureReason,
  };
}
