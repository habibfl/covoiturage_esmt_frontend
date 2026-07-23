import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../constants/colors.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool secondary;
  final IconData? icon;
  final Color? backgroundColor;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.secondary = false,
    this.icon,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;

    final child = loading
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CupertinoActivityIndicator(color: Colors.white),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          );

    return Opacity(
      opacity: disabled && !loading ? 0.6 : 1,
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: secondary
            ? OutlinedButton(
                onPressed: disabled ? null : onPressed,
                style: backgroundColor != null
                    ? OutlinedButton.styleFrom(
                        foregroundColor: backgroundColor,
                        side: BorderSide(color: backgroundColor!, width: 1.5),
                      )
                    : null,
                child: child,
              )
            : ElevatedButton(
                onPressed: disabled ? null : onPressed,
                style: backgroundColor != null
                    ? ElevatedButton.styleFrom(
                        backgroundColor: backgroundColor,
                        foregroundColor: Colors.white,
                      )
                    : null,
                child: child,
              ),
      ),
    );
  }
}

class CustomIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const CustomIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      customBorder: const CircleBorder(),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          boxShadow: [AppShadows.soft],
        ),
        child: Icon(icon, size: 20, color: AppColors.primary),
      ),
    );
  }
}