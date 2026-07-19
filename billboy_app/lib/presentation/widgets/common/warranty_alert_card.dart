import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class WarrantyAlertCard extends StatelessWidget {
  final String productName;
  final int daysLeft;
  final VoidCallback? onTap;

  const WarrantyAlertCard({
    super.key,
    required this.productName,
    required this.daysLeft,
    this.onTap,
  });

  Color get _color {
    if (daysLeft <= 7) return AppColors.error;
    if (daysLeft <= 30) return AppColors.warning;
    return AppColors.info;
  }

  String get _urgency {
    if (daysLeft <= 7) return 'Critical';
    if (daysLeft <= 30) return 'Soon';
    return 'Upcoming';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.shield_outlined, color: _color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Warranty expires in $daysLeft days',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: _color),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _urgency,
                style: TextStyle(
                                    fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

