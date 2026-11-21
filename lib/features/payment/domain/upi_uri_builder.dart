import 'package:url_launcher/url_launcher.dart';

/// Builder and validator for standardized National Payments Corporation of India (NPCI)
/// UPI Intent URIs (upi://pay) and cross-platform payment bridges.
class UpiUriBuilder {
  /// Regular expression for validating standard Indian UPI Virtual Payment Addresses (VPAs)
  /// Examples: landlord@oksbi, 9829012345@paytm, sharma.pg@icici
  static final RegExp _vpaRegex = RegExp(
    r'^[a-zA-Z0-9.\-_]{2,256}@[a-zA-Z0-9]{2,64}$',
  );

  /// Validates whether a given string is a valid UPI VPA
  static bool isValidVpa(String? vpa) {
    if (vpa == null) return false;
    final trimmed = vpa.trim();
    if (trimmed.isEmpty) return false;
    return _vpaRegex.hasMatch(trimmed);
  }

  /// Constructs a standardized NPCI UPI Intent URI string
  ///
  /// Specification:
  /// `upi://pay?pa={VPA}&pn={PAYEE}&am={AMOUNT}&cu=INR&tn={NOTE}`
  static String buildUriString({
    required String upiId,
    required String payeeName,
    required double amount,
    String? transactionNote,
  }) {
    final cleanVpa = upiId.trim();
    if (!isValidVpa(cleanVpa)) {
      throw ArgumentError('Invalid UPI VPA format: "$upiId". Must be like name@bank');
    }

    if (amount <= 0) {
      throw ArgumentError('Amount must be greater than zero, got $amount');
    }

    final encodedName = Uri.encodeComponent(payeeName.trim());
    final formattedAmount = amount.toStringAsFixed(2);
    final note = transactionNote != null && transactionNote.trim().isNotEmpty
        ? Uri.encodeComponent(transactionNote.trim())
        : Uri.encodeComponent('Rent Payment');

    return 'upi://pay?pa=$cleanVpa&pn=$encodedName&am=$formattedAmount&cu=INR&tn=$note';
  }

  /// Builds a Uri object from the parameters
  static Uri buildUri({
    required String upiId,
    required String payeeName,
    required double amount,
    String? transactionNote,
  }) {
    return Uri.parse(
      buildUriString(
        upiId: upiId,
        payeeName: payeeName,
        amount: amount,
        transactionNote: transactionNote,
      ),
    );
  }

  /// Generates the cross-platform Web Bridge URL for WhatsApp CTA buttons
  /// When clicked in WhatsApp webview, it redirects to the device's default UPI app.
  static String generateWebBridgeUrl({required String invoiceToken}) {
    return 'https://rentkhata.in/pay/$invoiceToken';
  }

  /// Launches the device's UPI chooser (GPay, PhonePe, Paytm, BHIM)
  /// Returns true if intent was successfully dispatched.
  static Future<bool> launchUpi({
    required String upiId,
    required String payeeName,
    required double amount,
    String? transactionNote,
  }) async {
    final uri = buildUri(
      upiId: upiId,
      payeeName: payeeName,
      amount: amount,
      transactionNote: transactionNote,
    );

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      return launched;
    } catch (_) {
      return false;
    }
  }
}
