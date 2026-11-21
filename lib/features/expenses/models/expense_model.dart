import 'package:flutter/material.dart';
import '../../payment/models/payment_model.dart';

enum ExpenseCategory {
  electricityMain,
  staffSalary,
  maintenance,
  water,
  groceriesMess,
  internetWifi,
  propertyTax,
  other,
}

extension ExpenseCategoryX on ExpenseCategory {
  String get displayName {
    switch (this) {
      case ExpenseCategory.electricityMain:
        return 'Main Electricity (बिजली बिल)';
      case ExpenseCategory.staffSalary:
        return 'Staff Salary (कर्मचारी वेतन)';
      case ExpenseCategory.maintenance:
        return 'Repairs & Maintenance (मरम्मत)';
      case ExpenseCategory.water:
        return 'Water Supply (पानी टैंकर)';
      case ExpenseCategory.groceriesMess:
        return 'Mess & Ration (मेस/किराना)';
      case ExpenseCategory.internetWifi:
        return 'Wi-Fi & Internet (इंटरनेट)';
      case ExpenseCategory.propertyTax:
        return 'Property Tax / Govt (टैक्स)';
      case ExpenseCategory.other:
        return 'Miscellaneous (अन्य खर्च)';
    }
  }

  IconData get icon {
    switch (this) {
      case ExpenseCategory.electricityMain:
        return Icons.bolt_rounded;
      case ExpenseCategory.staffSalary:
        return Icons.badge_rounded;
      case ExpenseCategory.maintenance:
        return Icons.build_rounded;
      case ExpenseCategory.water:
        return Icons.water_drop_rounded;
      case ExpenseCategory.groceriesMess:
        return Icons.restaurant_rounded;
      case ExpenseCategory.internetWifi:
        return Icons.wifi_rounded;
      case ExpenseCategory.propertyTax:
        return Icons.account_balance_rounded;
      case ExpenseCategory.other:
        return Icons.receipt_rounded;
    }
  }
}

/// Operational expense entry for property management (DISCOM bill, staff, repairs)
class ExpenseModel {
  final String id;
  final String propertyId;
  final ExpenseCategory category;
  final String title;
  final double amount;
  final DateTime expenseDate;
  final PaymentMode paymentMode;
  final String? receiptPhotoUrl;
  final String? notes;
  final DateTime createdAt;

  const ExpenseModel({
    required this.id,
    required this.propertyId,
    required this.category,
    required this.title,
    required this.amount,
    required this.expenseDate,
    this.paymentMode = PaymentMode.cash,
    this.receiptPhotoUrl,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'propertyId': propertyId,
      'category': category.name,
      'title': title,
      'amount': amount,
      'expenseDate': expenseDate.toIso8601String(),
      'paymentMode': paymentMode.name,
      'receiptPhotoUrl': receiptPhotoUrl,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] as String,
      propertyId: json['propertyId'] as String,
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ExpenseCategory.other,
      ),
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      expenseDate: DateTime.parse(json['expenseDate'] as String),
      paymentMode: PaymentMode.values.firstWhere(
        (e) => e.name == json['paymentMode'],
        orElse: () => PaymentMode.cash,
      ),
      receiptPhotoUrl: json['receiptPhotoUrl'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  ExpenseModel copyWith({
    String? id,
    String? propertyId,
    ExpenseCategory? category,
    String? title,
    double? amount,
    DateTime? expenseDate,
    PaymentMode? paymentMode,
    String? receiptPhotoUrl,
    String? notes,
    DateTime? createdAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      category: category ?? this.category,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      expenseDate: expenseDate ?? this.expenseDate,
      paymentMode: paymentMode ?? this.paymentMode,
      receiptPhotoUrl: receiptPhotoUrl ?? this.receiptPhotoUrl,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
