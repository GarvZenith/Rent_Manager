import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/rent_khata_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../invoice/models/invoice_model.dart';
import '../../meter/models/meter_reading_model.dart';
import '../../room/models/room_model.dart';
import '../../tenant/models/tenant_model.dart';
import '../domain/whatsapp_message_builder.dart';
import '../services/whatsapp_launcher_service.dart';

/// Interactive modal sheet to preview, switch templates/languages,
/// and dispatch 1-tap WhatsApp rent bills to tenants.
class SendReminderSheet extends ConsumerStatefulWidget {
  final InvoiceModel invoice;
  final TenantModel tenant;
  final RoomModel room;
  final MeterReadingModel? meterReading;

  const SendReminderSheet({
    super.key,
    required this.invoice,
    required this.tenant,
    required this.room,
    this.meterReading,
  });

  @override
  ConsumerState<SendReminderSheet> createState() => _SendReminderSheetState();
}

class _SendReminderSheetState extends ConsumerState<SendReminderSheet> {
  late WhatsAppTemplateType _selectedTemplate;
  WhatsAppLanguage _selectedLanguage = WhatsAppLanguage.hinglish;
  late TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    // Default template based on invoice status
    if (widget.invoice.status == InvoiceStatus.overdue ||
        (widget.invoice.balanceDue > 0 && DateTime.now().isAfter(widget.invoice.dueDate))) {
      _selectedTemplate = WhatsAppTemplateType.overdueNotice;
    } else {
      _selectedTemplate = WhatsAppTemplateType.monthlyBill;
    }

    _messageController = TextEditingController();
    _refreshMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _refreshMessage() {
    final state = ref.read(rentKhataRepositoryProvider);
    final property = state.properties.isNotEmpty ? state.properties.first : null;

    String text;
    switch (_selectedTemplate) {
      case WhatsAppTemplateType.monthlyBill:
        text = WhatsAppMessageBuilder.buildMonthlyRentBill(
          tenant: widget.tenant,
          room: widget.room,
          invoice: widget.invoice,
          meterReading: widget.meterReading,
          activeRoommatesCount: widget.room.occupiedBedCount,
          propertyName: property?.name,
          upiVpa: property?.upiVpa,
          upiPayeeName: property?.upiAccountName,
          language: _selectedLanguage,
        );
        break;
      case WhatsAppTemplateType.gentleReminder:
        text = WhatsAppMessageBuilder.buildGentleReminder(
          tenant: widget.tenant,
          room: widget.room,
          invoice: widget.invoice,
          propertyName: property?.name,
          upiVpa: property?.upiVpa,
          upiPayeeName: property?.upiAccountName,
          language: _selectedLanguage,
        );
        break;
      case WhatsAppTemplateType.overdueNotice:
        text = WhatsAppMessageBuilder.buildOverdueNotice(
          tenant: widget.tenant,
          room: widget.room,
          invoice: widget.invoice,
          propertyName: property?.name,
          upiVpa: property?.upiVpa,
          upiPayeeName: property?.upiAccountName,
          language: _selectedLanguage,
        );
        break;
      case WhatsAppTemplateType.paymentReceipt:
        text = WhatsAppMessageBuilder.buildMonthlyRentBill(
          tenant: widget.tenant,
          room: widget.room,
          invoice: widget.invoice,
          language: _selectedLanguage,
        );
        break;
    }

    setState(() {
      _messageController.text = text;
    });
  }

  void _sendWhatsApp() async {
    final result = await WhatsAppLauncherService.launchWhatsApp(
      rawPhoneNumber: widget.tenant.phone,
      message: _messageController.text,
    );

    if (mounted) {
      if (result.isSuccess) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WhatsApp launched with message!'),
            backgroundColor: AppColors.statusPaid,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Message copied to clipboard!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF16A34A), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Send WhatsApp Bill',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                          Text(
                            '${widget.tenant.fullName} • Room ${widget.room.roomNumber}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
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
          const Divider(height: 16),

          // Template Selector Chips
          const Text(
            'Message Type (मैसेज का प्रकार):',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTemplateChip(
                  label: 'Monthly Bill (बिल)',
                  type: WhatsAppTemplateType.monthlyBill,
                ),
                const SizedBox(width: 8),
                _buildTemplateChip(
                  label: 'Gentle Reminder (याद दिलाना)',
                  type: WhatsAppTemplateType.gentleReminder,
                ),
                const SizedBox(width: 8),
                _buildTemplateChip(
                  label: 'Overdue Notice (बकाया)',
                  type: WhatsAppTemplateType.overdueNotice,
                  color: AppColors.statusOverdue,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Language Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Language (भाषा):',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
              SegmentedButton<WhatsAppLanguage>(
                segments: const [
                  ButtonSegment(
                    value: WhatsAppLanguage.hinglish,
                    label: Text('Hinglish', style: TextStyle(fontSize: 11)),
                  ),
                  ButtonSegment(
                    value: WhatsAppLanguage.english,
                    label: Text('English', style: TextStyle(fontSize: 11)),
                  ),
                ],
                selected: {_selectedLanguage},
                onSelectionChanged: (set) {
                  setState(() {
                    _selectedLanguage = set.first;
                    _refreshMessage();
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Message Preview Text Area
          const Text(
            'Live Message Preview (एडिट भी कर सकते हैं):',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),

          Flexible(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4), // WhatsApp light green
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: TextField(
                controller: _messageController,
                maxLines: null,
                style: const TextStyle(fontSize: 12, height: 1.4, fontFamily: 'monospace'),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Send Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: const Color(0xFF16A34A), // WhatsApp Green
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.send_rounded),
            label: Text(
              '⚡ Open WhatsApp & Send to ${widget.tenant.phone}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            onPressed: _sendWhatsApp,
          ),
          const SizedBox(height: 8),

          // Copy Button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              side: const BorderSide(color: AppColors.border),
            ),
            icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.textSecondary),
            label: const Text(
              'Copy Message Text to Clipboard',
              style: TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            ),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _messageController.text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Message copied to clipboard!'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateChip({
    required String label,
    required WhatsAppTemplateType type,
    Color? color,
  }) {
    final isSelected = _selectedTemplate == type;
    final activeColor = color ?? AppColors.primary;

    return FilterChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : AppColors.textPrimary,
      ),
      selectedColor: activeColor,
      backgroundColor: AppColors.background,
      checkmarkColor: Colors.white,
      onSelected: (val) {
        if (val) {
          setState(() {
            _selectedTemplate = type;
            _refreshMessage();
          });
        }
      },
    );
  }
}
