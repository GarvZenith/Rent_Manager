import 'package:intl/intl.dart';

/// Calculation breakdown result for electricity sub-meters
class ElectricityBillBreakdown {
  final double previousReading;
  final double currentReading;
  final double unitsConsumed;
  final double ratePerUnit;
  final double totalRoomAmount;
  final int activeTenantsCount;
  final double perTenantAmount;
  final bool isSurgeWarning;
  final double surgePercentage;

  const ElectricityBillBreakdown({
    required this.previousReading,
    required this.currentReading,
    required this.unitsConsumed,
    required this.ratePerUnit,
    required this.totalRoomAmount,
    this.activeTenantsCount = 1,
    required this.perTenantAmount,
    this.isSurgeWarning = false,
    this.surgePercentage = 0.0,
  });

  /// Generates dispute-proof mathematical string formatted for WhatsApp delivery
  String toWhatsAppMathString({required String roomNumber}) {
    final formatCurrency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    final buffer = StringBuffer();
    buffer.writeln('⚡ *Electricity Sub-Meter Math (Room $roomNumber)*');
    buffer.writeln('• Previous Reading: ${previousReading.toStringAsFixed(0)} Units');
    buffer.writeln('• Current Reading: ${currentReading.toStringAsFixed(0)} Units');
    buffer.writeln('• Units Consumed: *${unitsConsumed.toStringAsFixed(0)} Units*');
    buffer.writeln('• Tariff Rate: ₹${ratePerUnit.toStringAsFixed(0)} / Unit');
    buffer.writeln('• Total Room Bill: *${formatCurrency.format(totalRoomAmount)}*');

    if (activeTenantsCount > 1) {
      buffer.writeln('• Split ($activeTenantsCount Roommates): *${formatCurrency.format(perTenantAmount)} per student*');
    }

    if (isSurgeWarning) {
      buffer.writeln('⚠️ _Note: Consumption increased by ${surgePercentage.toStringAsFixed(0)}% compared to last cycle._');
    }

    return buffer.toString().trim();
  }
}

/// Pure domain calculator for sub-meter electricity math, splits & anomaly detection
class ElectricityCalculator {
  /// Calculate units, cost, shared splits and check for unusual consumption surges
  static ElectricityBillBreakdown calculate({
    required double previousReading,
    required double currentReading,
    required double ratePerUnit,
    int activeTenantsCount = 1,
    double? lastCycleUnitsConsumed,
  }) {
    if (currentReading < previousReading) {
      throw ArgumentError(
        'Current reading (${currentReading.toStringAsFixed(0)}) cannot be less than previous reading (${previousReading.toStringAsFixed(0)})',
      );
    }

    final unitsConsumed = currentReading - previousReading;
    final totalRoomAmount = unitsConsumed * ratePerUnit;
    final validTenants = activeTenantsCount > 0 ? activeTenantsCount : 1;
    final perTenantAmount = totalRoomAmount / validTenants;

    // Anomaly Surge Detection: If current units > 200% of last cycle units
    bool isSurge = false;
    double surgePct = 0.0;
    if (lastCycleUnitsConsumed != null && lastCycleUnitsConsumed > 10) {
      final ratio = unitsConsumed / lastCycleUnitsConsumed;
      if (ratio >= 2.0) {
        isSurge = true;
        surgePct = (ratio - 1.0) * 100;
      }
    }

    return ElectricityBillBreakdown(
      previousReading: previousReading,
      currentReading: currentReading,
      unitsConsumed: unitsConsumed,
      ratePerUnit: ratePerUnit,
      totalRoomAmount: totalRoomAmount,
      activeTenantsCount: validTenants,
      perTenantAmount: perTenantAmount,
      isSurgeWarning: isSurge,
      surgePercentage: surgePct,
    );
  }
}
