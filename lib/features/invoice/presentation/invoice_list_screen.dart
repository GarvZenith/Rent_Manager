import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/rent_khata_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/status_badge.dart';
import '../models/invoice_model.dart';
import 'invoice_detail_screen.dart';

enum InvoiceFilter { all, pending, paid }

/// Screen listing all property invoices with search, filters, and batch generation
class InvoiceListScreen extends ConsumerStatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  ConsumerState<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends ConsumerState<InvoiceListScreen> {
  String _searchQuery = '';
  InvoiceFilter _selectedFilter = InvoiceFilter.all;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rentKhataRepositoryProvider);

    final tenantMap = {for (final t in state.tenants) t.id: t};
    final roomMap = {for (final r in state.rooms) r.id: r};

    // Filter invoices based on status and search query
    final filteredInvoices = state.invoices.where((inv) {
      // Status filter
      if (_selectedFilter == InvoiceFilter.pending) {
        if (inv.isFullyPaid || inv.status == InvoiceStatus.paid) return false;
      } else if (_selectedFilter == InvoiceFilter.paid) {
        if (!inv.isFullyPaid && inv.status != InvoiceStatus.paid) return false;
      }

      // Search query filter (Tenant Name, Room Number, Invoice Number)
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final tenant = tenantMap[inv.tenantId];
        final room = roomMap[inv.roomId];

        final matchTenant = tenant != null && tenant.fullName.toLowerCase().contains(q);
        final matchRoom = room != null && room.roomNumber.toLowerCase().contains(q);
        final matchInvoice = inv.invoiceNumber.toLowerCase().contains(q);

        return matchTenant || matchRoom || matchInvoice;
      }

      return true;
    }).toList();

    // Sort by most recent issue date / year / month descending
    filteredInvoices.sort((a, b) {
      final yearComp = b.billingYear.compareTo(a.billingYear);
      if (yearComp != 0) return yearComp;
      final monthComp = b.billingMonth.compareTo(a.billingMonth);
      if (monthComp != 0) return monthComp;
      return b.issueDate.compareTo(a.issueDate);
    });

    // Totals calculations
    final totalBilled = state.invoices.fold<double>(0.0, (s, i) => s + i.totalAmount);
    final totalCollected = state.invoices.fold<double>(0.0, (s, i) => s + i.amountPaid);
    final totalPending = state.invoices.fold<double>(0.0, (s, i) => s + i.balanceDue);

    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rent Bills & Invoices',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            Text(
              'किराया चालान और बिल प्रबंधन',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Generate Monthly Invoices',
            icon: const Icon(Icons.playlist_add_check_rounded, color: AppColors.primary),
            onPressed: () => _showBatchGenerateDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // KPI Summary Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.primaryLight.withValues(alpha: 0.3),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Billed', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.format(totalBilled),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 30, color: AppColors.border),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Collected', style: TextStyle(fontSize: 11, color: AppColors.statusPaid)),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.format(totalCollected),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.statusPaid),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 30, color: AppColors.border),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pending Due', style: TextStyle(fontSize: 11, color: AppColors.statusOverdue)),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.format(totalPending),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.statusOverdue),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Search & Filter Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search tenant, room, or invoice #...',
                prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
          ),

          // Status Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip('All Invoices (${state.invoices.length})', InvoiceFilter.all),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Pending / Overdue (${state.invoices.where((i) => i.balanceDue > 0).length})',
                  InvoiceFilter.pending,
                  activeColor: AppColors.statusOverdue,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Fully Paid (${state.invoices.where((i) => i.isFullyPaid).length})',
                  InvoiceFilter.paid,
                  activeColor: AppColors.statusPaid,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Invoices List
          Expanded(
            child: filteredInvoices.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          const Text(
                            'No invoices found matching your criteria.',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Tap "Generate Bills" to create monthly rent invoices for active rooms.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          AppButton(
                            label: '⚡ Auto-Generate Monthly Bills',
                            icon: Icons.auto_awesome_rounded,
                            onPressed: () => _showBatchGenerateDialog(context),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredInvoices.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final invoice = filteredInvoices[i];
                      final tenant = tenantMap[invoice.tenantId];
                      final room = roomMap[invoice.roomId];
                      final monthName = DateFormat('MMMM yyyy').format(
                        DateTime(invoice.billingYear, invoice.billingMonth),
                      );

                      return Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (ctx) => InvoiceDetailScreen(invoiceId: invoice.id),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top row: Tenant name + Status Badge
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryLight,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'Room ${room?.roomNumber ?? "?"}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              tenant?.fullName ?? 'Tenant',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    StatusBadge(
                                      status: _getBadgeStatus(invoice),
                                      label: _getBadgeLabel(invoice),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Middle Row: Month + Invoice #
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      monthName,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                    Text(
                                      invoice.invoiceNumber,
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                                const Divider(height: 16),

                                // Bottom Row: Amounts and Due Date
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Due: ${dateFormat.format(invoice.dueDate)}',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        ),
                                        if (invoice.electricityCharges > 0)
                                          Text(
                                            '⚡ Electricity: ${CurrencyFormatter.format(invoice.electricityCharges)}',
                                            style: const TextStyle(fontSize: 11, color: AppColors.primary),
                                          ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          CurrencyFormatter.format(invoice.totalAmount),
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                        ),
                                        if (invoice.balanceDue > 0)
                                          Text(
                                            'Due: ${CurrencyFormatter.format(invoice.balanceDue)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.statusOverdue,
                                            ),
                                          )
                                        else
                                          const Text(
                                            '✓ Settled',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.statusPaid,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBatchGenerateDialog(context),
        icon: const Icon(Icons.receipt_long_rounded),
        label: const Text('Generate Bills'),
      ),
    );
  }

  Widget _buildFilterChip(String label, InvoiceFilter filter, {Color? activeColor}) {
    final isSelected = _selectedFilter == filter;
    final color = activeColor ?? AppColors.primary;

    return FilterChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : AppColors.textPrimary,
      ),
      selectedColor: color,
      backgroundColor: AppColors.background,
      checkmarkColor: Colors.white,
      onSelected: (val) {
        if (val) setState(() => _selectedFilter = filter);
      },
    );
  }

  RoomPaymentStatus _getBadgeStatus(InvoiceModel invoice) {
    if (invoice.status == InvoiceStatus.paid || invoice.isFullyPaid) {
      return RoomPaymentStatus.paid;
    }
    if (invoice.status == InvoiceStatus.overdue ||
        (invoice.balanceDue > 0 && DateTime.now().isAfter(invoice.dueDate))) {
      return RoomPaymentStatus.overdue;
    }
    return RoomPaymentStatus.dueToday;
  }

  String _getBadgeLabel(InvoiceModel invoice) {
    if (invoice.status == InvoiceStatus.paid || invoice.isFullyPaid) {
      return 'Paid';
    }
    if (invoice.status == InvoiceStatus.overdue ||
        (invoice.balanceDue > 0 && DateTime.now().isAfter(invoice.dueDate))) {
      return 'Overdue';
    }
    return 'Due';
  }

  void _showBatchGenerateDialog(BuildContext context) {
    final now = DateTime.now();
    int selectedMonth = now.month;
    int selectedYear = now.year;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final monthDisplay = DateFormat('MMMM yyyy').format(DateTime(selectedYear, selectedMonth));
          final state = ref.read(rentKhataRepositoryProvider);
          final activeLeases = state.leases.where((l) => l.isActive).toList();

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Auto-Generate Rent Bills', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sabhi active tenants ke liye monthly rent bills automatic generate karein.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Billing Month:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(
                        monthDisplay,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.primaryDark),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '• Active Rooms to Bill: ${activeLeases.length}\n• Mid-month move-ins get pro-rata calculations\n• Sub-meter electricity split automatically',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.bolt, size: 16),
                label: const Text('Generate Now'),
                onPressed: () {
                  final newInvoices = ref
                      .read(rentKhataRepositoryProvider.notifier)
                      .generateBatchMonthlyInvoices(
                        month: selectedMonth,
                        year: selectedYear,
                      );
                  Navigator.of(dialogCtx).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        newInvoices.isEmpty
                            ? 'All active rooms already have bills for $monthDisplay.'
                            : 'Generated ${newInvoices.length} invoices successfully for $monthDisplay!',
                      ),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
