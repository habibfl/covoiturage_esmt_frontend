import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../constants/colors.dart';

class DriverProfileCard extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final String vehicle;
  final double rating;
  final bool framed;
  final bool compact;

  const DriverProfileCard({
    super.key,
    required this.name,
    this.avatarUrl,
    required this.vehicle,
    required this.rating,
    this.framed = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Row(
      children: [
        _DriverAvatar(name: name, size: compact ? 48 : 56),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: compact ? 15 : 16,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                vehicle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ...List.generate(
                    5,
                    (index) => Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: Icon(
                        CupertinoIcons.star_fill,
                        size: 14,
                        color: index < rating.round()
                            ? AppColors.starYellow
                            : AppColors.divider,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    rating.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    if (!framed) return content;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [AppShadows.soft],
      ),
      child: content,
    );
  }
}

class _DriverAvatar extends StatelessWidget {
  final String name;
  final double size;

  const _DriverAvatar({required this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: size > 50 ? 18 : 15,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}