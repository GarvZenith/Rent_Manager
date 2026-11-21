import '../../payment/models/payment_model.dart';
import '../models/expense_model.dart';

class MonthlyCashFlowSummary {
  final int month;
  final int year;
  final double totalRevenue;
  final double totalExpenses;
  final double netCashFlow;
  final double profitMarginPercentage;
  final Map<ExpenseCategory, double> categoryBreakdown;

  const MonthlyCashFlowSummary({
    required this.month,
    required this.year,
    required this.totalRevenue,
    required this.totalExpenses,
    required this.netCashFlow,
    required this.profitMarginPercentage,
    required this.categoryBreakdown,
  });

  bool get isProfitable => netCashFlow >= 0;
}

/// Ledger mathematics engine for computing gross rent revenues,
/// operational overhead deductions, and net monthly cash flow.
class ExpenseCalculator {
  /// Computes monthly cash flow summary for a given month and year
  static MonthlyCashFlowSummary calculateMonthlyCashFlow({
    required List<PaymentModel> payments,
    required List<ExpenseModel> expenses,
    required int month,
    required int year,
  }) {
    // 1. Calculate Gross Revenue from Payments received in this month & year
    final monthPayments = payments.where((p) =>
        p.paymentDate.month == month && p.paymentDate.year == year);
    final totalRevenue = monthPayments.fold<double>(
        0.0, (sum, p) => sum + p.amount);

    // 2. Calculate Total Expenses in this month & year
    final monthExpenses = expenses.where((e) =>
        e.expenseDate.month == month && e.expenseDate.year == year);

    final categoryBreakdown = <ExpenseCategory, double>{};
    double totalExpenses = 0.0;

    for (final exp in monthExpenses) {
      totalExpenses += exp.amount;
      categoryBreakdown[exp.category] =
          (categoryBreakdown[exp.category] ?? 0.0) + exp.amount;
    }

    // Round amounts to 2 decimal places
    final cleanRevenue = (totalRevenue * 100).roundToDouble() / 100.0;
    final cleanExpenses = (totalExpenses * 100).roundToDouble() / 100.0;
    final netCashFlow = ((cleanRevenue - cleanExpenses) * 100).roundToDouble() / 100.0;

    final profitMargin = cleanRevenue > 0
        ? ((netCashFlow / cleanRevenue) * 10000).roundToDouble() / 100.0
        : 0.0;

    return MonthlyCashFlowSummary(
      month: month,
      year: year,
      totalRevenue: cleanRevenue,
      totalExpenses: cleanExpenses,
      netCashFlow: netCashFlow,
      profitMarginPercentage: profitMargin,
      categoryBreakdown: categoryBreakdown,
    );
  }
}
