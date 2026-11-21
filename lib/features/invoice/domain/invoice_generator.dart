import 'package:uuid/uuid.dart';
import '../../room/models/room_model.dart';
import '../../tenant/models/lease_model.dart';
import '../models/invoice_model.dart';

/// Calculation engine for monthly rent, pro-rata adjustments, utility aggregation,
/// and automated batch billing.
class InvoiceGenerator {
  static const _uuid = Uuid();

  /// Returns the total number of days in a given month and year,
  /// accurately accounting for leap years in February (28 vs 29 days).
  static int getDaysInMonth(int month, int year) {
    if (month < 1 || month > 12) {
      throw ArgumentError('Month must be between 1 and 12, got $month');
    }
    // Day 0 of the next month is the last day of the current month
    return DateTime(year, month + 1, 0).day;
  }

  /// Calculates pro-rata rent if a tenant moved in during the billing month.
  ///
  /// Formula:
  /// - Full month: If startDate <= 1st of billing month -> agreedMonthlyRent
  /// - Mid-month: If startDate is in billing month ->
  ///     (agreedMonthlyRent / daysInMonth) * activeDays
  ///     where activeDays = (daysInMonth - startDate.day + 1)
  /// - Future lease: If startDate > billing month -> 0.0
  static double calculateProRataRent({
    required double agreedMonthlyRent,
    required DateTime startDate,
    required int billingMonth,
    required int billingYear,
  }) {
    if (agreedMonthlyRent <= 0) return 0.0;

    final daysInMonth = getDaysInMonth(billingMonth, billingYear);
    final monthStart = DateTime(billingYear, billingMonth, 1);
    final monthEnd = DateTime(billingYear, billingMonth, daysInMonth, 23, 59, 59);

    // If lease starts after this billing month, rent is 0
    if (startDate.isAfter(monthEnd)) {
      return 0.0;
    }

    // If tenant joined on or before the 1st of this month, charge full rent
    if (startDate.isBefore(monthStart) ||
        (startDate.year == billingYear &&
            startDate.month == billingMonth &&
            startDate.day == 1)) {
      return agreedMonthlyRent;
    }

    // Tenant joined mid-month: calculate active days inclusive of move-in date
    final activeDays = daysInMonth - startDate.day + 1;
    final dailyRate = agreedMonthlyRent / daysInMonth;
    final proRata = dailyRate * activeDays;

    // Round to 2 decimal places
    return (proRata * 100).roundToDouble() / 100.0;
  }

  /// Calculates accumulated arrears (unpaid balance) from previous billing cycles.
  static double calculateArrears({
    required List<InvoiceModel> previousInvoices,
    required int currentMonth,
    required int currentYear,
  }) {
    double totalArrears = 0.0;

    for (final inv in previousInvoices) {
      final isBeforeCurrent = inv.billingYear < currentYear ||
          (inv.billingYear == currentYear && inv.billingMonth < currentMonth);

      if (isBeforeCurrent && inv.status != InvoiceStatus.cancelled) {
        totalArrears += inv.balanceDue;
      }
    }

    return (totalArrears * 100).roundToDouble() / 100.0;
  }

  /// Calculates late fees if current date is past the invoice due date.
  static double calculateLateFee({
    required DateTime dueDate,
    required DateTime currentDate,
    double perDayRate = 50.0,
    double maxLateFee = 500.0,
  }) {
    if (!currentDate.isAfter(dueDate)) {
      return 0.0;
    }

    final daysLate = currentDate.difference(dueDate).inDays;
    if (daysLate <= 0) return 0.0;

    final fee = daysLate * perDayRate;
    return fee > maxLateFee ? maxLateFee : fee;
  }

  /// Generates a standardized invoice reference number.
  /// Format: INV-YYYY-MM-{ROOM_NUMBER}-{SUFFIX}
  static String formatInvoiceNumber({
    required int year,
    required int month,
    required String roomNumber,
    String? suffix,
  }) {
    final m = month.toString().padLeft(2, '0');
    final s = suffix != null ? '-$suffix' : '';
    return 'INV-$year-$m-$roomNumber$s';
  }

  /// Creates a single monthly invoice for a lease.
  static InvoiceModel createMonthlyInvoice({
    required LeaseModel lease,
    required RoomModel room,
    required int billingMonth,
    required int billingYear,
    DateTime? issueDate,
    DateTime? dueDate,
    double electricityCharges = 0.0,
    double maintenanceCharges = 0.0,
    double foodMessCharges = 0.0,
    double previousArrears = 0.0,
    double discount = 0.0,
    double lateFee = 0.0,
  }) {
    final effectiveIssueDate = issueDate ?? DateTime(billingYear, billingMonth, 1);
    final effectiveDueDate = dueDate ?? DateTime(billingYear, billingMonth, 5);

    // Compute base rent (handling mid-month pro-rata)
    final calculatedBaseRent = calculateProRataRent(
      agreedMonthlyRent: lease.agreedMonthlyRent,
      startDate: lease.startDate,
      billingMonth: billingMonth,
      billingYear: billingYear,
    );

    final invoiceNumber = formatInvoiceNumber(
      year: billingYear,
      month: billingMonth,
      roomNumber: room.roomNumber,
      suffix: lease.id.substring(0, 4).toUpperCase(),
    );

    return InvoiceModel(
      id: _uuid.v4(),
      leaseId: lease.id,
      tenantId: lease.tenantId,
      roomId: room.id,
      invoiceNumber: invoiceNumber,
      billingMonth: billingMonth,
      billingYear: billingYear,
      issueDate: effectiveIssueDate,
      dueDate: effectiveDueDate,
      baseRent: calculatedBaseRent,
      electricityCharges: electricityCharges,
      maintenanceCharges: maintenanceCharges,
      foodMessCharges: foodMessCharges,
      otherCharges: previousArrears, // Arrears carried forward
      discountAmount: discount,
      lateFee: lateFee,
      amountPaid: 0.0,
      status: InvoiceStatus.pending,
      publicInvoiceToken: _uuid.v4(),
    );
  }

  /// Generates invoices in bulk for all active leases across a property
  /// for a specific month and year.
  ///
  /// Guarantees:
  /// 1. Skips leases that already have an invoice for this month and year (Idempotent).
  /// 2. Applies pro-rata rent for mid-month move-ins.
  /// 3. Distributes room electricity charges equally among active roommates.
  static List<InvoiceModel> generateBatchInvoices({
    required List<LeaseModel> activeLeases,
    required List<RoomModel> rooms,
    required List<InvoiceModel> existingInvoices,
    required int billingMonth,
    required int billingYear,
    Map<String, double>? roomElectricityCharges,
    double defaultMaintenance = 0.0,
    double defaultFoodMess = 0.0,
    int dueDayOfMonth = 5,
  }) {
    final generatedInvoices = <InvoiceModel>[];
    final roomMap = {for (final r in rooms) r.id: r};

    // Calculate active tenants count per room for electricity splitting
    final roomTenantCount = <String, int>{};
    for (final lease in activeLeases) {
      if (lease.isActive) {
        roomTenantCount[lease.roomId] = (roomTenantCount[lease.roomId] ?? 0) + 1;
      }
    }

    for (final lease in activeLeases) {
      if (!lease.isActive) continue;

      // Check if invoice already exists for this lease, month, and year
      final alreadyBilled = existingInvoices.any(
        (inv) =>
            inv.leaseId == lease.id &&
            inv.billingMonth == billingMonth &&
            inv.billingYear == billingYear &&
            inv.status != InvoiceStatus.cancelled,
      );

      if (alreadyBilled) continue;

      final room = roomMap[lease.roomId];
      if (room == null) continue;

      // Compute split electricity charges if room has an electricity total
      double splitElectricity = 0.0;
      if (roomElectricityCharges != null && roomElectricityCharges.containsKey(room.id)) {
        final totalRoomElec = roomElectricityCharges[room.id] ?? 0.0;
        final occupants = roomTenantCount[room.id] ?? 1;
        splitElectricity = occupants > 0
            ? (totalRoomElec / occupants * 100).roundToDouble() / 100.0
            : 0.0;
      }

      final invoice = createMonthlyInvoice(
        lease: lease,
        room: room,
        billingMonth: billingMonth,
        billingYear: billingYear,
        dueDate: DateTime(billingYear, billingMonth, dueDayOfMonth),
        electricityCharges: splitElectricity,
        maintenanceCharges: defaultMaintenance,
        foodMessCharges: defaultFoodMess,
      );

      generatedInvoices.add(invoice);
    }

    return generatedInvoices;
  }
}
