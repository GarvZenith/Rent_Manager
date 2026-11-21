enum InvoiceStatus {
  pending,
  partiallyPaid,
  paid,
  overdue,
  cancelled,
}

/// Invoice model representing an itemized monthly rent & utility bill
class InvoiceModel {
  final String id;
  final String leaseId;
  final String tenantId;
  final String roomId;
  final String invoiceNumber;
  final int billingMonth;
  final int billingYear;
  final DateTime issueDate;
  final DateTime dueDate;

  // Breakdown line items
  final double baseRent;
  final double electricityCharges;
  final double maintenanceCharges;
  final double foodMessCharges;
  final double otherCharges;
  final double discountAmount;
  final double lateFee;

  // Payments summary
  final double amountPaid;
  final InvoiceStatus status;
  final String? dynamicUpiLink;
  final String? publicInvoiceToken;

  const InvoiceModel({
    required this.id,
    required this.leaseId,
    required this.tenantId,
    required this.roomId,
    required this.invoiceNumber,
    required this.billingMonth,
    required this.billingYear,
    required this.issueDate,
    required this.dueDate,
    this.baseRent = 0.0,
    this.electricityCharges = 0.0,
    this.maintenanceCharges = 0.0,
    this.foodMessCharges = 0.0,
    this.otherCharges = 0.0,
    this.discountAmount = 0.0,
    this.lateFee = 0.0,
    this.amountPaid = 0.0,
    this.status = InvoiceStatus.pending,
    this.dynamicUpiLink,
    this.publicInvoiceToken,
  });

  /// Total bill amount calculated accurately from line items
  double get totalAmount {
    final subtotal = baseRent +
        electricityCharges +
        maintenanceCharges +
        foodMessCharges +
        otherCharges +
        lateFee;
    return subtotal > discountAmount ? subtotal - discountAmount : 0.0;
  }

  /// Outstanding balance due
  double get balanceDue {
    final rem = totalAmount - amountPaid;
    return rem > 0 ? rem : 0.0;
  }

  /// True if invoice is completely settled
  bool get isFullyPaid => balanceDue <= 0 && totalAmount > 0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'leaseId': leaseId,
      'tenantId': tenantId,
      'roomId': roomId,
      'invoiceNumber': invoiceNumber,
      'billingMonth': billingMonth,
      'billingYear': billingYear,
      'issueDate': issueDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'baseRent': baseRent,
      'electricityCharges': electricityCharges,
      'maintenanceCharges': maintenanceCharges,
      'foodMessCharges': foodMessCharges,
      'otherCharges': otherCharges,
      'discountAmount': discountAmount,
      'lateFee': lateFee,
      'amountPaid': amountPaid,
      'totalAmount': totalAmount,
      'balanceDue': balanceDue,
      'status': status.name,
      'dynamicUpiLink': dynamicUpiLink,
      'publicInvoiceToken': publicInvoiceToken,
    };
  }

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'] as String,
      leaseId: json['leaseId'] as String,
      tenantId: json['tenantId'] as String,
      roomId: json['roomId'] as String,
      invoiceNumber: json['invoiceNumber'] as String,
      billingMonth: json['billingMonth'] as int,
      billingYear: json['billingYear'] as int,
      issueDate: DateTime.parse(json['issueDate'] as String),
      dueDate: DateTime.parse(json['dueDate'] as String),
      baseRent: (json['baseRent'] as num?)?.toDouble() ?? 0.0,
      electricityCharges: (json['electricityCharges'] as num?)?.toDouble() ?? 0.0,
      maintenanceCharges: (json['maintenanceCharges'] as num?)?.toDouble() ?? 0.0,
      foodMessCharges: (json['foodMessCharges'] as num?)?.toDouble() ?? 0.0,
      otherCharges: (json['otherCharges'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      lateFee: (json['lateFee'] as num?)?.toDouble() ?? 0.0,
      amountPaid: (json['amountPaid'] as num?)?.toDouble() ?? 0.0,
      status: InvoiceStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => InvoiceStatus.pending,
      ),
      dynamicUpiLink: json['dynamicUpiLink'] as String?,
      publicInvoiceToken: json['publicInvoiceToken'] as String?,
    );
  }

  InvoiceModel copyWith({
    String? id,
    String? leaseId,
    String? tenantId,
    String? roomId,
    String? invoiceNumber,
    int? billingMonth,
    int? billingYear,
    DateTime? issueDate,
    DateTime? dueDate,
    double? baseRent,
    double? electricityCharges,
    double? maintenanceCharges,
    double? foodMessCharges,
    double? otherCharges,
    double? discountAmount,
    double? lateFee,
    double? amountPaid,
    InvoiceStatus? status,
    String? dynamicUpiLink,
    String? publicInvoiceToken,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      leaseId: leaseId ?? this.leaseId,
      tenantId: tenantId ?? this.tenantId,
      roomId: roomId ?? this.roomId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      billingMonth: billingMonth ?? this.billingMonth,
      billingYear: billingYear ?? this.billingYear,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      baseRent: baseRent ?? this.baseRent,
      electricityCharges: electricityCharges ?? this.electricityCharges,
      maintenanceCharges: maintenanceCharges ?? this.maintenanceCharges,
      foodMessCharges: foodMessCharges ?? this.foodMessCharges,
      otherCharges: otherCharges ?? this.otherCharges,
      discountAmount: discountAmount ?? this.discountAmount,
      lateFee: lateFee ?? this.lateFee,
      amountPaid: amountPaid ?? this.amountPaid,
      status: status ?? this.status,
      dynamicUpiLink: dynamicUpiLink ?? this.dynamicUpiLink,
      publicInvoiceToken: publicInvoiceToken ?? this.publicInvoiceToken,
    );
  }
}
