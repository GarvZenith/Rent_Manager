import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rent_manager/core/database/rent_khata_repository.dart';
import 'package:rent_manager/features/expenses/domain/expense_calculator.dart';
import 'package:rent_manager/features/expenses/models/expense_model.dart';
import 'package:rent_manager/features/expenses/presentation/add_expense_dialog.dart';
import 'package:rent_manager/features/expenses/presentation/expense_tracker_screen.dart';
import 'package:rent_manager/features/payment/models/payment_model.dart';

void main() {
  group('Step 11 Audit: Expense & Cash Flow Ledger Domain Tests', () {
    test('Accurately computes Gross Revenue, Total Expenses, and Net Profit', () {
      final payments = [
        PaymentModel(
          id: 'p-1',
          invoiceId: 'inv-1',
          amount: 8000.0,
          paymentDate: DateTime(2026, 11, 2),
          receiptNumber: 'REC-1',
        ),
        PaymentModel(
          id: 'p-2',
          invoiceId: 'inv-2',
          amount: 7000.0,
          paymentDate: DateTime(2026, 11, 4),
          receiptNumber: 'REC-2',
        ),
        // Payment in another month (October) - should be excluded
        PaymentModel(
          id: 'p-3',
          invoiceId: 'inv-3',
          amount: 8000.0,
          paymentDate: DateTime(2026, 10, 28),
          receiptNumber: 'REC-3',
        ),
      ];

      final expenses = [
        ExpenseModel(
          id: 'e-1',
          propertyId: 'prop-1',
          category: ExpenseCategory.staffSalary,
          title: 'Maid Salary',
          amount: 4000.0,
          expenseDate: DateTime(2026, 11, 5),
          createdAt: DateTime(2026, 11, 5),
        ),
        ExpenseModel(
          id: 'e-2',
          propertyId: 'prop-1',
          category: ExpenseCategory.electricityMain,
          title: 'Main Electricity DISCOM',
          amount: 2500.0,
          expenseDate: DateTime(2026, 11, 10),
          createdAt: DateTime(2026, 11, 10),
        ),
        // Expense in October - should be excluded
        ExpenseModel(
          id: 'e-3',
          propertyId: 'prop-1',
          category: ExpenseCategory.maintenance,
          title: 'Plumbing Repair',
          amount: 1500.0,
          expenseDate: DateTime(2026, 10, 15),
          createdAt: DateTime(2026, 10, 15),
        ),
      ];

      final summary = ExpenseCalculator.calculateMonthlyCashFlow(
        payments: payments,
        expenses: expenses,
        month: 11,
        year: 2026,
      );

      // Revenue: 8000 + 7000 = 15000
      expect(summary.totalRevenue, 15000.0);
      // Expenses: 4000 + 2500 = 6500
      expect(summary.totalExpenses, 6500.0);
      // Net Profit: 15000 - 6500 = 8500
      expect(summary.netCashFlow, 8500.0);
      expect(summary.isProfitable, isTrue);

      // Profit Margin: (8500 / 15000) * 100 = 56.67%
      expect(summary.profitMarginPercentage, closeTo(56.67, 0.01));

      // Category breakdown
      expect(summary.categoryBreakdown[ExpenseCategory.staffSalary], 4000.0);
      expect(summary.categoryBreakdown[ExpenseCategory.electricityMain], 2500.0);
      expect(summary.categoryBreakdown.containsKey(ExpenseCategory.maintenance), isFalse);
    });

    test('Correctly flags negative cash flow / loss when expenses exceed collections', () {
      final payments = [
        PaymentModel(
          id: 'p-1',
          invoiceId: 'inv-1',
          amount: 5000.0,
          paymentDate: DateTime(2026, 11, 1),
          receiptNumber: 'REC-1',
        ),
      ];

      final expenses = [
        ExpenseModel(
          id: 'e-1',
          propertyId: 'prop-1',
          category: ExpenseCategory.maintenance,
          title: 'Roof Water-proofing',
          amount: 12000.0,
          expenseDate: DateTime(2026, 11, 3),
          createdAt: DateTime(2026, 11, 3),
        ),
      ];

      final summary = ExpenseCalculator.calculateMonthlyCashFlow(
        payments: payments,
        expenses: expenses,
        month: 11,
        year: 2026,
      );

      expect(summary.totalRevenue, 5000.0);
      expect(summary.totalExpenses, 12000.0);
      expect(summary.netCashFlow, -7000.0);
      expect(summary.isProfitable, isFalse);
    });
  });

  group('Step 11 Audit: Expense Management UI Widget Tests', () {
    testWidgets('AddExpenseDialog inputs and saves new expense to repository', (tester) async {
      final repo = RentKhataRepository();
      repo.addProperty(
        name: 'Kota PG',
        address: 'Kunhari',
        city: 'Kota',
        stateName: 'Rajasthan',
        pincode: '324008',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            rentKhataRepositoryProvider.overrideWith((ref) => repo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AddExpenseDialog(),
            ),
          ),
        ),
      );

      expect(find.text('Record Expense (खर्चा जोड़ें)'), findsOneWidget);

      // Enter Title
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Expense Title (खर्चे का विवरण) *'),
        'Cook Monthly Salary',
      );

      // Enter Amount
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Amount (राशि ₹) *'),
        '6500',
      );

      // Tap Save
      await tester.tap(find.text('Save Expense (खर्चा दर्ज करें)'));
      await tester.pumpAndSettle();

      // Verify repository updated
      expect(repo.state.expenses.length, 1);
      expect(repo.state.expenses.first.title, 'Cook Monthly Salary');
      expect(repo.state.expenses.first.amount, 6500.0);
    });

    testWidgets('ExpenseTrackerScreen displays financial KPIs, category bars, and expense list', (tester) async {
      final repo = RentKhataRepository();
      final prop = repo.addProperty(
        name: 'Kota PG',
        address: 'Kunhari',
        city: 'Kota',
        stateName: 'Rajasthan',
        pincode: '324008',
      );

      // Record 1 expense for current month
      final now = DateTime.now();
      repo.recordExpense(
        propertyId: prop.id,
        category: ExpenseCategory.water,
        title: 'Water Tanker Kunhari',
        amount: 1500.0,
        expenseDate: now,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            rentKhataRepositoryProvider.overrideWith((ref) => repo),
          ],
          child: const MaterialApp(
            home: ExpenseTrackerScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Expense & P&L Ledger'), findsOneWidget);
      expect(find.text('Net Cash Flow (शुद्ध मुनाफा):'), findsOneWidget);
      expect(find.text('Water Tanker Kunhari'), findsOneWidget);
      expect(find.text('-₹1,500'), findsNWidgets(2));
      expect(find.text('Water Supply'), findsOneWidget);
    });
  });
}
