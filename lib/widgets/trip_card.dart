import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../constants/colors.dart';
import 'address_timeline_tile.dart';

class TripCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  final VoidCallback onReserve;

  const TripCard({super.key, required this.trip, required this.onReserve});

  @override
  Widget build(BuildContext context) {
    final price = trip['price']?.toString();
    final time = trip['time']?.toString();
    final seats = trip['seats'];
    final rating = trip['rating'];

    return InkWell(
      onTap: onReserve,
      splashColor: AppColors.primary.withValues(alpha: 0.08),
      highlightColor: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [AppShadows.soft],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AddressTimelineTile(
              departure: trip['departure']?.toString() ?? 'Depart non renseigne',
              arrival: trip['arrival']?.toString() ?? 'Arrivee non renseignee',
              compact: true,
            ),
            const SizedBox(height: 14),
            Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                if (time != null && time.isNotEmpty) ...[
                  _InfoBadge(icon: CupertinoIcons.time, label: time),
                  const SizedBox(width: 14),
                ],
                if (seats != null) ...[
                  _InfoBadge(
                    icon: CupertinoIcons.person_2,
                    label: '$seats places',
                  ),
                  const SizedBox(width: 14),
                ],
                if (rating is num && rating > 0) ...[
                  _InfoBadge(
                    icon: CupertinoIcons.star_fill,
                    label: rating.toStringAsFixed(1),
                    iconColor: AppColors.starYellow,
                  ),
                ],
                const Spacer(),
                if (price != null && price.isNotEmpty) _PriceBadge(price: price),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceBadge extends StatelessWidget {
  final String price;

  const _PriceBadge({required this.price});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        price,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.accent,
            ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;

  const _InfoBadge({required this.icon, required this.label, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: iconColor ?? AppColors.textSecondary),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}