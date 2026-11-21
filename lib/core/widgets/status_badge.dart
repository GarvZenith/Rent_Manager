import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum RoomPaymentStatus {
  paid,
  overdue,
  dueToday,
  vacant,
}

/// Color-coded status badge with high-contrast background and text
class StatusBadge extends StatelessWidget {
  final RoomPaymentStatus status;
  final String label;

  const StatusBadge({
    super.key,
    required this.status,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;

    switch (status) {
      case RoomPaymentStatus.paid:
        bg = AppColors.statusPaidLight;
        fg = AppColors.statusPaid;
        icon = Icons.check_circle_rounded;
        break;
      case RoomPaymentStatus.overdue:
        bg = AppColors.statusOverdueLight;
        fg = AppColors.statusOverdue;
        icon = Icons.error_rounded;
        break;
      case RoomPaymentStatus.dueToday:
        bg = AppColors.statusDueTodayLight;
        fg = AppColors.statusDueToday;
        icon = Icons.access_time_filled_rounded;
        break;
      case RoomPaymentStatus.vacant:
        bg = AppColors.statusVacantLight;
        fg = AppColors.statusVacant;
        icon = Icons.meeting_room_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
