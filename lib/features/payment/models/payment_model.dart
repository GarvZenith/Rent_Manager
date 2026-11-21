enum PaymentMode {
  upi,
  cash,
  bankTransfer,
  cheque,
}

/// Payment record tracking rent settlements and receipt allocations
class PaymentModel {
  final String id;
  final String invoiceId;
  final double amount;
  final DateTime paymentDate;
  final PaymentMode paymentMode;
  final String? transactionRef; // UTR or UPI reference number
  final String receiptNumber; // e.g. 'REC-2026-0001'
  final String? receiptPdfUrl;
  final String? notes;

  const PaymentModel({
    required this.id,
    required this.invoiceId,
    required this.amount,
    required this.paymentDate,
    this.paymentMode = PaymentMode.upi,
    this.transactionRef,
    required this.receiptNumber,
    this.receiptPdfUrl,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoiceId': invoiceId,
      'amount': amount,
      'paymentDate': paymentDate.toIso8601String(),
      'paymentMode': paymentMode.name,
      'transactionRef': transactionRef,
      'receiptNumber': receiptNumber,
      'receiptPdfUrl': receiptPdfUrl,
      'notes': notes,
    };
  }

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      invoiceId: json['invoiceId'] as String,
      amount: (json['amount'] as num).toDouble(),
      paymentDate: DateTime.parse(json['paymentDate'] as String),
      paymentMode: PaymentMode.values.firstWhere(
        (e) => e.name == json['paymentMode'],
        orElse: () => PaymentMode.upi,
      ),
      transactionRef: json['transactionRef'] as String?,
      receiptNumber: json['receiptNumber'] as String,
      receiptPdfUrl: json['receiptPdfUrl'] as String?,
      notes: json['notes'] as String?,
    );
  }

  PaymentModel copyWith({
    String? id,
    String? invoiceId,
    double? amount,
    DateTime? paymentDate,
    PaymentMode? paymentMode,
    String? transactionRef,
    String? receiptNumber,
    String? receiptPdfUrl,
    String? notes,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentMode: paymentMode ?? this.paymentMode,
      transactionRef: transactionRef ?? this.transactionRef,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      receiptPdfUrl: receiptPdfUrl ?? this.receiptPdfUrl,
      notes: notes ?? this.notes,
    );
  }
}
