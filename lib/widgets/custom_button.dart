import 'package:flutter/material.dart';
import '../core/theme.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool outlined;
  final Color? color;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.outlined = false,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          );

    if (outlined) {
      return OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: color ?? AppColors.cardDark,
          side: BorderSide(color: color ?? AppColors.cardDark),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        onPressed: isLoading ? null : onPressed,
        child: child,
      );
    }

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? AppColors.cardDark,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      onPressed: isLoading ? null : onPressed,
      child: child,
    );
  }
}