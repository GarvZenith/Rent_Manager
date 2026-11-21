import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum AppButtonVariant { primary, secondary, outline, danger }

/// Accessible, large touch-target button tailored for older landlords
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final AppButtonVariant variant;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.variant = AppButtonVariant.primary,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 52,
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }

    Color bgColor = AppColors.primary;
    Color fgColor = Colors.white;

    switch (variant) {
      case AppButtonVariant.primary:
        bgColor = AppColors.primary;
        fgColor = Colors.white;
        break;
      case AppButtonVariant.secondary:
        bgColor = AppColors.primaryLight;
        fgColor = AppColors.primaryDark;
        break;
      case AppButtonVariant.outline:
        bgColor = Colors.transparent;
        fgColor = AppColors.textPrimary;
        break;
      case AppButtonVariant.danger:
        bgColor = AppColors.statusOverdueLight;
        fgColor = AppColors.statusOverdue;
        break;
    }

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      elevation: variant == AppButtonVariant.outline ? 0 : 0.5,
      side: variant == AppButtonVariant.outline
          ? const BorderSide(color: AppColors.border)
          : BorderSide.none,
      minimumSize: const Size(double.infinity, 52),
    );

    if (icon != null) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: buttonStyle,
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: buttonStyle,
      child: Text(label),
    );
  }
}
