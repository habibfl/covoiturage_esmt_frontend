import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../constants/colors.dart';

class AddressTimelineTile extends StatelessWidget {
  final String departure;
  final String arrival;
  final bool compact;

  const AddressTimelineTile({
    super.key,
    required this.departure,
    required this.arrival,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          child: Column(
            children: [
              _DeparturePoint(color: AppColors.primary),
              SizedBox(
                height: compact ? 24 : 32,
                child: CustomPaint(
                  painter: DashedLinePainter(color: AppColors.divider),
                  size: Size(2, compact ? 24 : 32),
                ),
              ),
              _ArrivalPoint(color: AppColors.primary),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AddressBlock(
                title: departure,
                subtitle: 'Point de depart',
                compact: compact,
              ),
              SizedBox(height: compact ? 14 : 18),
              _AddressBlock(
                title: arrival,
                subtitle: 'Destination',
                compact: compact,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DeparturePoint extends StatelessWidget {
  final Color color;

  const _DeparturePoint({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: const Icon(
        CupertinoIcons.arrow_down,
        size: 14,
        color: Colors.white,
      ),
    );
  }
}

class _ArrivalPoint extends StatelessWidget {
  final Color color;

  const _ArrivalPoint({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Icon(CupertinoIcons.location_solid, size: 13, color: color),
    );
  }
}

class _AddressBlock extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool compact;

  const _AddressBlock({
    required this.title,
    required this.subtitle,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 2),
        Text(
          title,
          maxLines: compact ? 1 : 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: compact ? 14 : 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
        ),
      ],
    );
  }
}

class DashedLinePainter extends CustomPainter {
  final Color color;
  final double dashHeight;
  final double dashSpace;

  const DashedLinePainter({
    required this.color,
    this.dashHeight = 4,
    this.dashSpace = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    double startY = 0;
    final centerX = size.width / 2;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(centerX, startY),
        Offset(centerX, (startY + dashHeight).clamp(0, size.height)),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant DashedLinePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.dashHeight != dashHeight ||
        oldDelegate.dashSpace != dashSpace;
  }
}