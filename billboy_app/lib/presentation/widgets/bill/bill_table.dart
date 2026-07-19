import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/entities/bill_entity.dart';

class BillTable extends StatelessWidget {
  final List<BillEntity> bills;

  const BillTable({super.key, required this.bills});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: bills.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => BillCard(bill: bills[index]),
    );
  }
}

class BillCard extends StatelessWidget {
  final BillEntity bill;

  const BillCard({super.key, required this.bill});

  Color get _statusColor {
    switch (bill.warrantyStatus) {
      case WarrantyStatus.active:
        return AppColors.warrantyActive;
      case WarrantyStatus.expiringSoon:
        return AppColors.warrantyExpiringSoon;
      case WarrantyStatus.expired:
        return AppColors.warrantyExpired;
      case WarrantyStatus.noWarranty:
        return AppColors.textSecondaryLight;
    }
  }

  String get _statusLabel {
    switch (bill.warrantyStatus) {
      case WarrantyStatus.active:
        return 'Active';
      case WarrantyStatus.expiringSoon:
        return 'Expiring';
      case WarrantyStatus.expired:
        return 'Expired';
      case WarrantyStatus.noWarranty:
        return 'No Warranty';
    }
  }

  Color get _categoryColor {
    return AppColors.categoryColors[bill.category] ?? AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/bill/${bill.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.light
                ? AppColors.borderLight
                : AppColors.borderDark,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: product name + status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _categoryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_categoryIcon, color: _categoryColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bill.productName,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _categoryColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              bill.category,
                              style: TextStyle(
                                                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: _categoryColor,
                              ),
                            ),
                          ),
                          if (bill.storeName != null) ...[
                            const SizedBox(width: 6),
                            const Text('â€¢', style: TextStyle(color: AppColors.textSecondaryLight)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                bill.storeName!,
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Warranty status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    _statusLabel,
                    style: TextStyle(
                                            fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _statusColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // Details row
            Row(
              children: [
                Expanded(
                  child: _InfoItem(
                    label: 'Purchase Date',
                    value: AppDateUtils.format(bill.purchaseDate),
                    icon: Icons.calendar_today_outlined,
                  ),
                ),
                Expanded(
                  child: _InfoItem(
                    label: 'Amount',
                    value: CurrencyUtils.format(bill.purchaseAmount),
                    icon: Icons.currency_rupee_rounded,
                  ),
                ),
                if (bill.warrantyEndDate != null)
                  Expanded(
                    child: _InfoItem(
                      label: 'Warranty End',
                      value: AppDateUtils.format(bill.warrantyEndDate!),
                      icon: Icons.shield_outlined,
                      valueColor: _statusColor,
                    ),
                  ),
              ],
            ),

            // Depreciation info
            if (bill.currentValue != null && bill.currentValue! < bill.purchaseAmount) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.trending_down_rounded, color: AppColors.warning, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Current Value: ${CurrencyUtils.format(bill.currentValue!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(-${bill.depreciationPercentage.toStringAsFixed(0)}%)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.warning,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData get _categoryIcon {
    switch (bill.category) {
      case 'Electronics':
        return Icons.devices_rounded;
      case 'Mobile Phones':
        return Icons.smartphone_rounded;
      case 'Laptops':
        return Icons.laptop_rounded;
      case 'Appliances':
        return Icons.kitchen_rounded;
      case 'Furniture':
        return Icons.chair_rounded;
      case 'Fashion':
        return Icons.checkroom_rounded;
      case 'Jewelry':
        return Icons.diamond_rounded;
      case 'Vehicles':
        return Icons.directions_car_rounded;
      case 'Insurance':
        return Icons.health_and_safety_rounded;
      case 'Healthcare':
        return Icons.medical_services_outlined;
      case 'Grocery':
        return Icons.shopping_basket_rounded;
      case 'Subscription Services':
        return Icons.subscriptions_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _InfoItem({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
          maxLines: 1,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: valueColor,
                fontWeight: FontWeight.w600,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

