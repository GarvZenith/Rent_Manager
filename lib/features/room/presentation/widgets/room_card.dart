import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../invoice/models/invoice_model.dart';
import '../../models/room_model.dart';
import '../../models/bed_model.dart';

/// Interactive room card displaying occupancy, meter units, and financial status
class RoomCard extends StatelessWidget {
  final RoomModel room;
  final InvoiceModel? latestInvoice;
  final VoidCallback? onAddReading;
  final VoidCallback? onRecordPayment;
  final VoidCallback? onSendReminder;
  final void Function(BedModel bed)? onBedTap;

  const RoomCard({
    super.key,
    required this.room,
    this.latestInvoice,
    this.onAddReading,
    this.onRecordPayment,
    this.onSendReminder,
    this.onBedTap,
  });

  RoomPaymentStatus get _status {
    if (room.beds.isEmpty || room.beds.every((b) => !b.isOccupied)) {
      return RoomPaymentStatus.vacant;
    }
    if (latestInvoice == null) {
      return RoomPaymentStatus.vacant;
    }
    switch (latestInvoice!.status) {
      case InvoiceStatus.paid:
        return RoomPaymentStatus.paid;
      case InvoiceStatus.overdue:
        return RoomPaymentStatus.overdue;
      case InvoiceStatus.partiallyPaid:
      case InvoiceStatus.pending:
        return RoomPaymentStatus.dueToday;
      case InvoiceStatus.cancelled:
        return RoomPaymentStatus.vacant;
    }
  }

  String get _statusLabel {
    switch (_status) {
      case RoomPaymentStatus.paid:
        return 'Paid (जमा)';
      case RoomPaymentStatus.overdue:
        return 'Overdue (बाकी)';
      case RoomPaymentStatus.dueToday:
        return 'Due (देना है)';
      case RoomPaymentStatus.vacant:
        return 'Vacant (खाली)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.8,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar: Room # & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.meeting_room_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Room ${room.roomNumber}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Floor ${room.floorNumber} • ${_getSharingTitle(room.sharingType)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                StatusBadge(status: _status, label: _statusLabel),
              ],
            ),
            const Divider(height: 20),

            // Middle: Rent Amount & Sub-meter Units
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Base Rent / Bed',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    Text(
                      CurrencyFormatter.format(room.baseRentPerBed),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Meter Reading',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.flash_on_rounded, size: 14, color: AppColors.primary),
                        Text(
                          '${room.currentMeterReading.toStringAsFixed(0)} Units',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Beds Occupancy Indicators (Clickable to view Tenant Profile or Onboard)
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: room.beds.map((bed) {
                final isOcc = bed.isOccupied;
                return InkWell(
                  onTap: () => onBedTap?.call(bed),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isOcc ? AppColors.statusPaidLight : AppColors.statusVacantLight,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isOcc ? AppColors.statusPaid.withValues(alpha: 0.3) : AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isOcc ? Icons.person_rounded : Icons.person_add_alt_1_rounded,
                          size: 13,
                          color: isOcc ? AppColors.statusPaid : AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${bed.bedLabel}: ${isOcc ? "Tenant Active" : "+ Add Tenant"}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isOcc ? AppColors.statusPaid : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onAddReading,
                    icon: const Icon(Icons.electric_meter_rounded, size: 16),
                    label: const Text('Meter', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      minimumSize: const Size(0, 38),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRecordPayment,
                    icon: const Icon(Icons.currency_rupee_rounded, size: 16),
                    label: const Text('Settle', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      minimumSize: const Size(0, 38),
                    ),
                  ),
                ),
                if (_status != RoomPaymentStatus.paid && _status != RoomPaymentStatus.vacant) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onSendReminder,
                      icon: const Icon(Icons.send_rounded, size: 15),
                      label: const Text('Remind', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        minimumSize: const Size(0, 38),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getSharingTitle(RoomSharingType type) {
    switch (type) {
      case RoomSharingType.single:
        return 'Single Bed';
      case RoomSharingType.doubleSharing:
        return 'Double Sharing (2 Beds)';
      case RoomSharingType.tripleSharing:
        return 'Triple Sharing (3 Beds)';
      case RoomSharingType.fourPlus:
        return '4+ Sharing';
      case RoomSharingType.fullFlat:
        return 'Full Flat';
    }
  }
}
