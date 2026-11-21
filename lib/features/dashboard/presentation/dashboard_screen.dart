import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/status_badge.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLang = ref.watch(languageProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ref.tr('appName'),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
            ),
            const Text(
              'Krishna Residency (Kota)',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          // Language Switcher Button (English <-> Hinglish)
          TextButton.icon(
            onPressed: () {
              ref.read(languageProvider.notifier).toggleLanguage();
            },
            icon: const Icon(Icons.language, size: 18, color: AppColors.primary),
            label: Text(
              currentLang == AppLanguage.english ? 'हिंदी / Hinglish' : 'English',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Summary Card (Total Collected vs Pending)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ref.tr('totalCollected'),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                '₹1,42,500',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.statusPaid,
                                ),
                              ),
                              const Text(
                                '18/22 Beds Paid',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 50,
                          color: AppColors.divider,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ref.tr('pendingDues'),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                '₹28,500',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.statusOverdue,
                                ),
                              ),
                              const Text(
                                '4 Beds Pending',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          ref.tr('occupancy'),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Text(
                          '22 / 24 Beds (91.6%)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quick Actions
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: ref.tr('addReading'),
                    icon: Icons.electric_meter_outlined,
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    label: ref.tr('sendReminders'),
                    icon: Icons.send_rounded,
                    variant: AppButtonVariant.secondary,
                    onPressed: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Demo Status Badges Preview
            Text(
              ref.tr('rooms'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusBadge(
                  status: RoomPaymentStatus.paid,
                  label: ref.tr('statusPaid'),
                ),
                StatusBadge(
                  status: RoomPaymentStatus.overdue,
                  label: ref.tr('statusOverdue'),
                ),
                StatusBadge(
                  status: RoomPaymentStatus.dueToday,
                  label: ref.tr('statusDueToday'),
                ),
                StatusBadge(
                  status: RoomPaymentStatus.vacant,
                  label: ref.tr('statusVacant'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
