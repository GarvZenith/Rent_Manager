import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/whatsapp_message_builder.dart';

class WhatsAppLaunchResult {
  final bool isSuccess;
  final String? errorMessage;
  final Uri uri;

  const WhatsAppLaunchResult({
    required this.isSuccess,
    this.errorMessage,
    required this.uri,
  });
}

/// Service to dispatch pre-formatted WhatsApp messages to tenants
/// using native app intents with fallback to browser deep-links.
class WhatsAppLauncherService {
  /// Launches WhatsApp with the target phone number and pre-filled message
  static Future<WhatsAppLaunchResult> launchWhatsApp({
    required String rawPhoneNumber,
    required String message,
  }) async {
    final cleanPhone = WhatsAppMessageBuilder.normalizeIndianPhoneNumber(rawPhoneNumber);
    final waUri = WhatsAppMessageBuilder.buildWhatsAppUri(
      phoneNumber: cleanPhone,
      message: message,
    );

    // Native intent URI (faster on Android/iOS when WhatsApp is installed)
    final nativeUri = Uri.parse('whatsapp://send?phone=$cleanPhone&text=${Uri.encodeComponent(message)}');

    try {
      // 1. Try launching native WhatsApp app intent first
      if (await canLaunchUrl(nativeUri)) {
        final launched = await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
        if (launched) {
          return WhatsAppLaunchResult(isSuccess: true, uri: nativeUri);
        }
      }

      // 2. Fallback to https://wa.me web link
      if (await canLaunchUrl(waUri)) {
        final launched = await launchUrl(waUri, mode: LaunchMode.externalApplication);
        if (launched) {
          return WhatsAppLaunchResult(isSuccess: true, uri: waUri);
        }
      }

      // 3. Fallback: Copy message to clipboard
      await Clipboard.setData(ClipboardData(text: message));
      return WhatsAppLaunchResult(
        isSuccess: false,
        errorMessage: 'WhatsApp is not installed on this device. Message was copied to clipboard.',
        uri: waUri,
      );
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: message));
      return WhatsAppLaunchResult(
        isSuccess: false,
        errorMessage: 'Could not open WhatsApp ($e). Message copied to clipboard.',
        uri: waUri,
      );
    }
  }
}
