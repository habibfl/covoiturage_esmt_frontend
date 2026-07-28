import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../constants/colors.dart';

class CustomButton extends StatefulWidget {
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
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null || widget.loading;

    final child = widget.loading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CupertinoActivityIndicator(color: AppColors.onColor),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 18),
                const SizedBox(width: 8),
              ],
              Text(widget.label),
            ],
          );

    return Listener(
      onPointerDown: disabled ? null : (_) => _setPressed(true),
      onPointerUp: disabled ? null : (_) => _setPressed(false),
      onPointerCancel: disabled ? null : (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Opacity(
          opacity: disabled && !widget.loading ? 0.6 : 1,
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: widget.secondary
                ? OutlinedButton(
                    onPressed: disabled ? null : widget.onPressed,
                    style: widget.backgroundColor != null
                        ? OutlinedButton.styleFrom(
                            foregroundColor: widget.backgroundColor,
                            side: BorderSide(
                              color: widget.backgroundColor!,
                              width: 1.5,
                            ),
                          )
                        : null,
                    child: child,
                  )
                : ElevatedButton(
                    onPressed: disabled ? null : widget.onPressed,
                    style: widget.backgroundColor != null
                        ? ElevatedButton.styleFrom(
                            backgroundColor: widget.backgroundColor,
                            foregroundColor: AppColors.onColor,
                          )
                        : null,
                    child: child,
                  ),
          ),
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