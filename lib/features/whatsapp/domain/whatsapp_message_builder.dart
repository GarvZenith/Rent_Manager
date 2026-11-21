import 'package:intl/intl.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../invoice/models/invoice_model.dart';
import '../../meter/models/meter_reading_model.dart';
import '../../payment/domain/upi_uri_builder.dart';
import '../../payment/models/payment_model.dart';
import '../../room/models/room_model.dart';
import '../../tenant/models/tenant_model.dart';

enum WhatsAppTemplateType {
  monthlyBill,
  gentleReminder,
  overdueNotice,
  paymentReceipt,
}

enum WhatsAppLanguage {
  hinglish,
  english,
}

/// Domain engine for composing polite, dispute-free WhatsApp rent notifications
/// with itemized math breakdowns, NPCI UPI payment links, and localized templates.
class WhatsAppMessageBuilder {
  /// Normalizes Indian phone numbers into international E.164 format without '+' or special characters
  /// Example: '9829012345' -> '919829012345'
  /// Example: '+91 98290-12345' -> '919829012345'
  /// Example: '09829012345' -> '919829012345'
  static String normalizeIndianPhoneNumber(String rawPhone) {
    // Strip everything except digits
    var digits = rawPhone.replaceAll(RegExp(r'\D'), '');

    // Strip leading 0 if present (e.g. trunk prefix)
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    // If 10 digits, prepend India country code 91
    if (digits.length == 10) {
      return '91$digits';
    }

    // If 12 digits and already starts with 91, keep it
    if (digits.length == 12 && digits.startsWith('91')) {
      return digits;
    }

    return digits;
  }

  /// Constructs standard WhatsApp web and intent URIs with properly UTF-8 percent-encoded text
  static Uri buildWhatsAppUri({
    required String phoneNumber,
    required String message,
  }) {
    final cleanPhone = normalizeIndianPhoneNumber(phoneNumber);
    final encodedMessage = Uri.encodeComponent(message);
    return Uri.parse('https://wa.me/$cleanPhone?text=$encodedMessage');
  }

  /// Builds a monthly rent bill message with complete itemized breakdown and UPI pay link
  static String buildMonthlyRentBill({
    required TenantModel tenant,
    required RoomModel room,
    required InvoiceModel invoice,
    MeterReadingModel? meterReading,
    int activeRoommatesCount = 1,
    String? propertyName,
    String? upiVpa,
    String? upiPayeeName,
    WhatsAppLanguage language = WhatsAppLanguage.hinglish,
  }) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final monthName = DateFormat('MMMM yyyy').format(
      DateTime(invoice.billingYear, invoice.billingMonth),
    );
    final propTitle = propertyName ?? 'RentKhata';
    final sb = StringBuffer();

    // Generate UPI deep-link if VPA is provided
    String? upiLink;
    if (upiVpa != null && upiVpa.isNotEmpty) {
      try {
        upiLink = UpiUriBuilder.buildUriString(
          upiId: upiVpa,
          payeeName: upiPayeeName ?? propTitle,
          amount: invoice.balanceDue > 0 ? invoice.balanceDue : invoice.totalAmount,
          transactionNote: 'Rent-Room${room.roomNumber}-${invoice.billingMonth}',
        );
      } catch (_) {}
    }

    if (language == WhatsAppLanguage.hinglish) {
      sb.writeln('🏠 *$propTitle - Rent Bill*');
      sb.writeln('Namaste *${tenant.fullName}* ji! 🙏');
      sb.writeln('');
      sb.writeln('Aapke Room *${room.roomNumber}* ka *$monthName* ka rent bill taiyaar hai:');
      sb.writeln('-----------------------------------');
      sb.writeln('🔹 *Base Rent:* ${CurrencyFormatter.format(invoice.baseRent)}');

      if (invoice.electricityCharges > 0) {
        if (meterReading != null) {
          final units = meterReading.unitsConsumed.toStringAsFixed(0);
          final prev = meterReading.previousReading.toStringAsFixed(0);
          final curr = meterReading.currentReading.toStringAsFixed(0);
          final rate = meterReading.ratePerUnit.toStringAsFixed(0);
          sb.writeln('🔹 *Electricity:* ${CurrencyFormatter.format(invoice.electricityCharges)}');
          sb.writeln('   _(Dial: $prev ➔ $curr = $units Units @ ₹$rate/unit)_');
          if (activeRoommatesCount > 1) {
            sb.writeln('   _(Split among $activeRoommatesCount roommates)_');
          }
        } else {
          sb.writeln('🔹 *Electricity:* ${CurrencyFormatter.format(invoice.electricityCharges)}');
        }
      }

      if (invoice.maintenanceCharges > 0) {
        sb.writeln('🔹 *Maintenance:* ${CurrencyFormatter.format(invoice.maintenanceCharges)}');
      }
      if (invoice.foodMessCharges > 0) {
        sb.writeln('🔹 *Food / Mess:* ${CurrencyFormatter.format(invoice.foodMessCharges)}');
      }
      if (invoice.otherCharges > 0) {
        sb.writeln('🔹 *Pichla Bakaya (Arrears):* ${CurrencyFormatter.format(invoice.otherCharges)}');
      }
      if (invoice.lateFee > 0) {
        sb.writeln('🔹 *Late Fee:* ${CurrencyFormatter.format(invoice.lateFee)}');
      }
      if (invoice.discountAmount > 0) {
        sb.writeln('🔹 *Discount / Chhoot:* -${CurrencyFormatter.format(invoice.discountAmount)}');
      }

      sb.writeln('-----------------------------------');
      sb.writeln('💰 *Total Due Amount:* *${CurrencyFormatter.format(invoice.balanceDue > 0 ? invoice.balanceDue : invoice.totalAmount)}*');
      sb.writeln('📅 *Due Date:* ${dateFormat.format(invoice.dueDate)}');
      sb.writeln('📄 *Invoice #:* ${invoice.invoiceNumber}');
      sb.writeln('-----------------------------------');

      if (upiLink != null) {
        sb.writeln('⚡ *Pay instantly via UPI (0% Fee):*');
        sb.writeln(upiLink);
        sb.writeln('_(Google Pay / PhonePe / Paytm / BHIM me direct khulega)_');
        sb.writeln('');
      }

      sb.writeln('Kirpya due date se pehle payment karein. Payment hote hi digital receipt mil jayegi. Dhanyawad!');
    } else {
      // English Template
      sb.writeln('🏠 *$propTitle - Monthly Rent Invoice*');
      sb.writeln('Dear *${tenant.fullName}*,');
      sb.writeln('');
      sb.writeln('Your rent invoice for Room *${room.roomNumber}* ($monthName) has been generated:');
      sb.writeln('-----------------------------------');
      sb.writeln('• Base Rent: ${CurrencyFormatter.format(invoice.baseRent)}');

      if (invoice.electricityCharges > 0) {
        if (meterReading != null) {
          final units = meterReading.unitsConsumed.toStringAsFixed(0);
          final prev = meterReading.previousReading.toStringAsFixed(0);
          final curr = meterReading.currentReading.toStringAsFixed(0);
          final rate = meterReading.ratePerUnit.toStringAsFixed(0);
          sb.writeln('• Electricity: ${CurrencyFormatter.format(invoice.electricityCharges)}');
          sb.writeln('  ($prev ➔ $curr = $units Units @ ₹$rate/unit)');
          if (activeRoommatesCount > 1) {
            sb.writeln('  (Shared among $activeRoommatesCount occupants)');
          }
        } else {
          sb.writeln('• Electricity: ${CurrencyFormatter.format(invoice.electricityCharges)}');
        }
      }

      if (invoice.maintenanceCharges > 0) {
        sb.writeln('• Maintenance: ${CurrencyFormatter.format(invoice.maintenanceCharges)}');
      }
      if (invoice.foodMessCharges > 0) {
        sb.writeln('• Mess / Meals: ${CurrencyFormatter.format(invoice.foodMessCharges)}');
      }
      if (invoice.otherCharges > 0) {
        sb.writeln('• Previous Arrears: ${CurrencyFormatter.format(invoice.otherCharges)}');
      }
      if (invoice.lateFee > 0) {
        sb.writeln('• Late Fee: ${CurrencyFormatter.format(invoice.lateFee)}');
      }
      if (invoice.discountAmount > 0) {
        sb.writeln('• Concession: -${CurrencyFormatter.format(invoice.discountAmount)}');
      }

      sb.writeln('-----------------------------------');
      sb.writeln('💰 *Total Payable:* *${CurrencyFormatter.format(invoice.balanceDue > 0 ? invoice.balanceDue : invoice.totalAmount)}*');
      sb.writeln('📅 *Due Date:* ${dateFormat.format(invoice.dueDate)}');
      sb.writeln('📄 *Invoice Ref:* ${invoice.invoiceNumber}');
      sb.writeln('-----------------------------------');

      if (upiLink != null) {
        sb.writeln('⚡ *Pay online via UPI:*');
        sb.writeln(upiLink);
        sb.writeln('');
      }

      sb.writeln('Please settle before the due date to avoid late charges. Thank you!');
    }

    return sb.toString();
  }

  /// Builds a gentle payment reminder message
  static String buildGentleReminder({
    required TenantModel tenant,
    required RoomModel room,
    required InvoiceModel invoice,
    String? propertyName,
    String? upiVpa,
    String? upiPayeeName,
    WhatsAppLanguage language = WhatsAppLanguage.hinglish,
  }) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final propTitle = propertyName ?? 'RentKhata';
    final amountDue = invoice.balanceDue > 0 ? invoice.balanceDue : invoice.totalAmount;

    String? upiLink;
    if (upiVpa != null && upiVpa.isNotEmpty) {
      try {
        upiLink = UpiUriBuilder.buildUriString(
          upiId: upiVpa,
          payeeName: upiPayeeName ?? propTitle,
          amount: amountDue,
          transactionNote: 'Rent-Room${room.roomNumber}',
        );
      } catch (_) {}
    }

    final sb = StringBuffer();
    if (language == WhatsAppLanguage.hinglish) {
      sb.writeln('⏰ *Gentle Rent Reminder - $propTitle*');
      sb.writeln('Namaste *${tenant.fullName}* ji! 🙏');
      sb.writeln('');
      sb.writeln('Aapke Room *${room.roomNumber}* ka monthly rent *${CurrencyFormatter.format(amountDue)}* due hai.');
      sb.writeln('📅 *Due Date:* ${dateFormat.format(invoice.dueDate)}');
      sb.writeln('');
      sb.writeln('Agar aapne payment kar diya hai toh kirpya confirmation ya screenshot bhej dein. Agar bacha hai toh niche diye link se pay kar sakte hain:');
      if (upiLink != null) {
        sb.writeln('');
        sb.writeln('⚡ *UPI Pay Link:* $upiLink');
      }
      sb.writeln('');
      sb.writeln('Shukriya!');
    } else {
      sb.writeln('⏰ *Rent Reminder - $propTitle*');
      sb.writeln('Dear *${tenant.fullName}*,');
      sb.writeln('');
      sb.writeln('This is a gentle reminder that your rent of *${CurrencyFormatter.format(amountDue)}* for Room *${room.roomNumber}* is due on *${dateFormat.format(invoice.dueDate)}*.');
      sb.writeln('');
      sb.writeln('If already paid, please ignore this message. Otherwise, kindly settle via the UPI link below:');
      if (upiLink != null) {
        sb.writeln('');
        sb.writeln('⚡ *UPI Pay Link:* $upiLink');
      }
      sb.writeln('');
      sb.writeln('Thank you!');
    }

    return sb.toString();
  }

  /// Builds an overdue rent notice
  static String buildOverdueNotice({
    required TenantModel tenant,
    required RoomModel room,
    required InvoiceModel invoice,
    String? propertyName,
    String? upiVpa,
    String? upiPayeeName,
    WhatsAppLanguage language = WhatsAppLanguage.hinglish,
  }) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final propTitle = propertyName ?? 'RentKhata';
    final amountDue = invoice.balanceDue > 0 ? invoice.balanceDue : invoice.totalAmount;

    String? upiLink;
    if (upiVpa != null && upiVpa.isNotEmpty) {
      try {
        upiLink = UpiUriBuilder.buildUriString(
          upiId: upiVpa,
          payeeName: upiPayeeName ?? propTitle,
          amount: amountDue,
          transactionNote: 'Overdue-Room${room.roomNumber}',
        );
      } catch (_) {}
    }

    final sb = StringBuffer();
    if (language == WhatsAppLanguage.hinglish) {
      sb.writeln('⚠️ *Overdue Rent Notice - $propTitle*');
      sb.writeln('Namaste *${tenant.fullName}* ji,');
      sb.writeln('');
      sb.writeln('Aapke Room *${room.roomNumber}* ka rent bill due date (${dateFormat.format(invoice.dueDate)}) tak jama nahi hua hai.');
      sb.writeln('💰 *Pending Amount:* *${CurrencyFormatter.format(amountDue)}*');
      sb.writeln('📄 *Invoice #:* ${invoice.invoiceNumber}');
      sb.writeln('');
      sb.writeln('Kirpya asuvidha aur late fee se bachne ke liye aaj hi payment clear karein:');
      if (upiLink != null) {
        sb.writeln('');
        sb.writeln('⚡ *Pay via UPI:* $upiLink');
      }
      sb.writeln('');
      sb.writeln('Kisi bhi issue ke liye turant landlord se sampark karein.');
    } else {
      sb.writeln('⚠️ *Overdue Rent Notice - $propTitle*');
      sb.writeln('Dear *${tenant.fullName}*,');
      sb.writeln('');
      sb.writeln('Your rent for Room *${room.roomNumber}* is past due (Due Date: ${dateFormat.format(invoice.dueDate)}).');
      sb.writeln('💰 *Total Overdue Balance:* *${CurrencyFormatter.format(amountDue)}*');
      sb.writeln('📄 *Invoice #:* ${invoice.invoiceNumber}');
      sb.writeln('');
      sb.writeln('Please settle the outstanding balance today to avoid late fees:');
      if (upiLink != null) {
        sb.writeln('');
        sb.writeln('⚡ *Pay via UPI:* $upiLink');
      }
      sb.writeln('');
      sb.writeln('Please contact the landlord immediately if you have any questions.');
    }

    return sb.toString();
  }

  /// Builds an instant payment confirmation & digital receipt message
  static String buildPaymentReceiptConfirmation({
    required TenantModel tenant,
    required RoomModel room,
    required PaymentModel payment,
    required double remainingBalance,
    String? propertyName,
    WhatsAppLanguage language = WhatsAppLanguage.hinglish,
  }) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final propTitle = propertyName ?? 'RentKhata';
    final sb = StringBuffer();

    if (language == WhatsAppLanguage.hinglish) {
      sb.writeln('🧾 *Payment Receipt - $propTitle*');
      sb.writeln('Namaste *${tenant.fullName}* ji! 🙏');
      sb.writeln('');
      sb.writeln('Aapka payment safaltapoorvak receive ho gaya hai. Dhanyawad!');
      sb.writeln('-----------------------------------');
      sb.writeln('💵 *Amount Received:* *${CurrencyFormatter.format(payment.amount)}*');
      sb.writeln('🧾 *Receipt #:* ${payment.receiptNumber}');
      sb.writeln('🚪 *Room:* ${room.roomNumber}');
      sb.writeln('💳 *Mode:* ${payment.paymentMode.name.toUpperCase()}');
      if (payment.transactionRef != null) {
        sb.writeln('🔢 *Ref / UTR:* ${payment.transactionRef}');
      }
      sb.writeln('📅 *Date & Time:* ${dateFormat.format(payment.paymentDate)}');
      sb.writeln('-----------------------------------');
      if (remainingBalance > 0) {
        sb.writeln('📌 *Remaining Balance:* ${CurrencyFormatter.format(remainingBalance)}');
      } else {
        sb.writeln('✅ *All Dues Settled (₹0 Balance)*');
      }
      sb.writeln('-----------------------------------');
      sb.writeln('Yeh message aapki digital payment receipt ke roop me maanya hai.');
    } else {
      sb.writeln('🧾 *Official Payment Receipt - $propTitle*');
      sb.writeln('Dear *${tenant.fullName}*,');
      sb.writeln('');
      sb.writeln('Thank you! Your payment has been received and verified.');
      sb.writeln('-----------------------------------');
      sb.writeln('💵 *Amount Received:* *${CurrencyFormatter.format(payment.amount)}*');
      sb.writeln('🧾 *Receipt Number:* ${payment.receiptNumber}');
      sb.writeln('🚪 *Room Number:* ${room.roomNumber}');
      sb.writeln('💳 *Payment Mode:* ${payment.paymentMode.name.toUpperCase()}');
      if (payment.transactionRef != null) {
        sb.writeln('🔢 *Transaction UTR:* ${payment.transactionRef}');
      }
      sb.writeln('📅 *Date:* ${dateFormat.format(payment.paymentDate)}');
      sb.writeln('-----------------------------------');
      if (remainingBalance > 0) {
        sb.writeln('📌 *Outstanding Balance:* ${CurrencyFormatter.format(remainingBalance)}');
      } else {
        sb.writeln('✅ *Fully Settled (Nil Balance)*');
      }
      sb.writeln('-----------------------------------');
      sb.writeln('This confirmation serves as your digital payment acknowledgment.');
    }

    return sb.toString();
  }
}
