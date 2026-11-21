import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/rent_khata_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../models/tenant_model.dart';
import '../models/lease_model.dart';

/// Modal dialog displaying tenant profile, KYC details, guardian info, and move-out options
class TenantProfileDialog extends ConsumerWidget {
  final TenantModel tenant;
  final LeaseModel lease;
  final String roomNumber;
  final String bedLabel;

  const TenantProfileDialog({
    super.key,
    required this.tenant,
    required this.lease,
    required this.roomNumber,
    required this.bedLabel,
  });

  void _moveOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Move-Out (कमरा खाली करें)'),
        content: Text(
          'Kya aap sach mein ${tenant.fullName} ka move-out settle karna chahte hain? Isse Room $roomNumber ka $bedLabel vacant (khali) ho jayega.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusOverdue),
            onPressed: () {
              // Free up the bed and deactivate lease via repository
              ref.read(rentKhataRepositoryProvider.notifier).settleMoveOut(leaseId: lease.id);

              Navigator.of(ctx).pop(); // Close confirm
              Navigator.of(context).pop(); // Close profile

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${tenant.fullName} moved out. $bedLabel is now vacant!'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            child: const Text('Confirm Move-Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.primaryLight,
                          child: Text(
                            tenant.fullName.isNotEmpty ? tenant.fullName[0].toUpperCase() : 'T',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tenant.fullName,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Room $roomNumber • $bedLabel',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Workplace / College
              if (tenant.workplaceOrCollege != null) ...[
                Row(
                  children: [
                    const Icon(Icons.school_outlined, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      tenant.workplaceOrCollege!,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Contact Information
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Mobile Number:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Flexible(
                          child: Text(
                            '+91 ${tenant.phone}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                    if (tenant.guardianName != null) ...[
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Father/Guardian:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Flexible(
                            child: Text(
                              tenant.guardianName!,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (tenant.guardianPhone != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Guardian Phone:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Flexible(
                            child: Text(
                              '+91 ${tenant.guardianPhone}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Financial & Deposit Status
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Monthly Agreed Rent:', style: TextStyle(fontSize: 12)),
                        Flexible(
                          child: Text(
                            CurrencyFormatter.format(lease.agreedMonthlyRent),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryDark),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Security Deposit:', style: TextStyle(fontSize: 12)),
                        Flexible(
                          child: Text(
                            '${CurrencyFormatter.format(lease.securityDepositAmount)} (${lease.isSecurityDepositPaid ? "Paid" : "Pending"})',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: lease.isSecurityDepositPaid ? AppColors.statusPaid : AppColors.statusOverdue,
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // KYC Details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ID Proof / KYC:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Flexible(
                    child: Text(
                      '${tenant.idProofType} Verified',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.statusPaid),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Move-Out Settle Button
              AppButton(
                label: 'Settle Move-Out (कमरा खाली करें)',
                variant: AppButtonVariant.danger,
                icon: Icons.logout_rounded,
                onPressed: () => _moveOut(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
