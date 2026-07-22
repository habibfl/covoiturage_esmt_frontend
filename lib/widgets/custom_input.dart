import 'package:flutter/material.dart';

import '../constants/colors.dart';

class CustomInput extends StatelessWidget {
  final String label;
  final String? hint;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const CustomInput({
    super.key,
    required this.label,
    required this.icon,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          onChanged: onChanged,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            hintText: hint ?? label,
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: Icon(icon, size: 20, color: AppColors.textSecondary),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 40),
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}