import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/rent_khata_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../payment/models/payment_model.dart';
import '../models/expense_model.dart';

/// Modal dialog to record an operational property expense (maid, electricity, maintenance)
class AddExpenseDialog extends ConsumerStatefulWidget {
  const AddExpenseDialog({super.key});

  @override
  ConsumerState<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends ConsumerState<AddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  ExpenseCategory _selectedCategory = ExpenseCategory.staffSalary;
  PaymentMode _selectedPaymentMode = PaymentMode.cash;
  DateTime _expenseDate = DateTime.now();

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveExpense() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) return;

    final state = ref.read(rentKhataRepositoryProvider);
    final propertyId = state.properties.isNotEmpty ? state.properties.first.id : 'default-prop';

    ref.read(rentKhataRepositoryProvider.notifier).recordExpense(
          propertyId: propertyId,
          category: _selectedCategory,
          title: _titleController.text.trim(),
          amount: amount,
          expenseDate: _expenseDate,
          paymentMode: _selectedPaymentMode,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Expense recorded successfully!'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dialog Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.statusOverdueLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.receipt_long_rounded, color: AppColors.statusOverdue, size: 20),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Record Expense (खर्चा जोड़ें)',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // Expense Title Input
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Expense Title (खर्चे का विवरण) *',
                      hintText: 'e.g., Maid Salary, Water Tanker, Main Electricity',
                      prefixIcon: Icon(Icons.edit_note_rounded),
                    ),
                    validator: (val) =>
                        (val == null || val.trim().isEmpty) ? 'Please enter an expense title' : null,
                  ),
                  const SizedBox(height: 12),

                  // Amount Input
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount (राशि ₹) *',
                      hintText: 'e.g., 5000',
                      prefixIcon: Icon(Icons.currency_rupee_rounded),
                    ),
                    validator: (val) {
                      final n = double.tryParse(val?.trim() ?? '');
                      if (n == null || n <= 0) return 'Please enter a valid amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Category Selector Dropdown
                  const Text('Category (खर्चे का प्रकार):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<ExpenseCategory>(
                    isExpanded: true,
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.category_rounded),
                    ),
                    items: ExpenseCategory.values.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Row(
                          children: [
                            Icon(cat.icon, size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                cat.displayName,
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (cat) {
                      if (cat != null) setState(() => _selectedCategory = cat);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Payment Mode & Date Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Payment Mode:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            DropdownButtonFormField<PaymentMode>(
                              isExpanded: true,
                              initialValue: _selectedPaymentMode,
                              decoration: const InputDecoration(isDense: true),
                              items: PaymentMode.values.map((m) {
                                return DropdownMenuItem(
                                  value: m,
                                  child: Text(m.name.toUpperCase(), style: const TextStyle(fontSize: 12)),
                                );
                              }).toList(),
                              onChanged: (m) {
                                if (m != null) setState(() => _selectedPaymentMode = m);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Date:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _expenseDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (picked != null) setState(() => _expenseDate = picked);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.border),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(dateFormat.format(_expenseDate), style: const TextStyle(fontSize: 12)),
                                    const Icon(Icons.calendar_month_outlined, size: 16, color: AppColors.primary),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Notes (Optional)
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (Optional टिप्पणी)',
                      hintText: 'e.g., Paid via GPay to Ramu',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit Button
                  AppButton(
                    label: 'Save Expense (खर्चा दर्ज करें)',
                    icon: Icons.check_circle_rounded,
                    onPressed: _saveExpense,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
