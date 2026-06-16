import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/depreciation_calculator.dart';
import '../../../domain/entities/bill_entity.dart';
import '../../blocs/bill/bill_bloc.dart';
import '../../blocs/bill/bill_event.dart';
import '../../blocs/bill/bill_state.dart';
import '../../widgets/common/bb_snackbar.dart';

class BillDetailPage extends StatelessWidget {
  final BillEntity bill;

  const BillDetailPage({super.key, required this.bill});

  @override
  Widget build(BuildContext context) {
    return BlocListener<BillBloc, BillState>(
      listener: (context, state) {
        if (state is BillDeletedState) {
          BBSnackbar.showSuccess(context, 'Bill deleted');
          context.go('/home');
        } else if (state is BillErrorState) {
          BBSnackbar.showError(context, state.message);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bill Details'),
          actions: [
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () => Share.share('${bill.productName} - ${CurrencyUtils.format(bill.purchaseAmount)}'),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push('/bill/form', extra: bill),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') _confirmDelete(context);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
              ],
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProductHeader(context),
              const SizedBox(height: 20),
              _buildBillInfo(context),
              const SizedBox(height: 20),
              _buildWarrantyInfo(context),
              const SizedBox(height: 20),
              _buildDepreciationInfo(context),
              if (bill.attachmentUrls.isNotEmpty) ...[
                const SizedBox(height: 20),
                _buildAttachments(context),
              ],
              if (bill.notes != null) ...[
                const SizedBox(height: 20),
                _buildNotes(context),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductHeader(BuildContext context) {
    final categoryColor = AppColors.categoryColors[bill.category] ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [categoryColor.withOpacity(0.15), categoryColor.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: categoryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(bill.productName, style: Theme.of(context).textTheme.headlineSmall),
              ),
              _WarrantyBadge(status: bill.warrantyStatus),
            ],
          ),
          const SizedBox(height: 8),
          if (bill.brandName != null || bill.modelNumber != null)
            Text(
              [bill.brandName, bill.modelNumber].where((e) => e != null).join(' • '),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryLight),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              _ValueChip(
                label: 'Paid',
                value: CurrencyUtils.format(bill.purchaseAmount),
                color: AppColors.primary,
              ),
              const SizedBox(width: 12),
              if (bill.currentValue != null)
                _ValueChip(
                  label: 'Now Worth',
                  value: CurrencyUtils.format(bill.currentValue!),
                  color: AppColors.warning,
                ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildBillInfo(BuildContext context) {
    return _Section(
      title: 'Bill Information',
      icon: Icons.receipt_outlined,
      children: [
        _DetailRow('Purchase Date', AppDateUtils.format(bill.purchaseDate)),
        if (bill.billNumber != null) _DetailRow('Bill Number', bill.billNumber!),
        if (bill.storeName != null) _DetailRow('Store', bill.storeName!),
        if (bill.storeAddress != null) _DetailRow('Address', bill.storeAddress!),
        if (bill.gstNumber != null) _DetailRow('GST Number', bill.gstNumber!),
        _DetailRow('Category', bill.category),
        if (bill.serialNumber != null) _DetailRow('Serial Number', bill.serialNumber!),
        if (bill.imeiNumber != null) _DetailRow('IMEI', bill.imeiNumber!),
        if (bill.taxAmount != null) _DetailRow('Tax Amount', CurrencyUtils.format(bill.taxAmount!)),
      ],
    );
  }

  Widget _buildWarrantyInfo(BuildContext context) {
    if (!bill.hasWarranty) {
      return _Section(
        title: 'Warranty',
        icon: Icons.shield_outlined,
        children: const [_DetailRow('Status', 'No Warranty')],
      );
    }

    final daysLeft = bill.daysUntilWarrantyExpiry;
    final statusColor = bill.warrantyStatus == WarrantyStatus.active
        ? AppColors.warrantyActive
        : bill.warrantyStatus == WarrantyStatus.expiringSoon
            ? AppColors.warrantyExpiringSoon
            : AppColors.warrantyExpired;

    return _Section(
      title: 'Warranty Information',
      icon: Icons.shield_outlined,
      children: [
        _DetailRow('Warranty Period', '${bill.warrantyMonths} months'),
        _DetailRow('Start Date', AppDateUtils.format(bill.purchaseDate)),
        if (bill.warrantyEndDate != null)
          _DetailRow('End Date', AppDateUtils.format(bill.warrantyEndDate!)),
        if (daysLeft != null)
          _DetailRow(
            'Days Remaining',
            daysLeft > 0 ? '$daysLeft days' : 'Expired',
            valueColor: statusColor,
          ),
      ],
    );
  }

  Widget _buildDepreciationInfo(BuildContext context) {
    if (bill.currentValue == null) return const SizedBox.shrink();

    return _Section(
      title: 'Depreciation',
      icon: Icons.trending_down_rounded,
      children: [
        _DetailRow('Original Price', CurrencyUtils.format(bill.purchaseAmount)),
        _DetailRow('Current Value', CurrencyUtils.format(bill.currentValue!), valueColor: AppColors.warning),
        _DetailRow('Value Loss', CurrencyUtils.format(bill.valueLoss), valueColor: AppColors.error),
        _DetailRow('Depreciation', '${bill.depreciationPercentage.toStringAsFixed(1)}%'),
      ],
    );
  }

  Widget _buildAttachments(BuildContext context) {
    return _Section(
      title: 'Attachments',
      icon: Icons.attach_file_rounded,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: bill.attachmentUrls.map((url) {
            return GestureDetector(
              onTap: () => _viewImage(context, url),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.primary.withOpacity(0.1),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: const Icon(Icons.image_rounded, color: AppColors.primary, size: 32),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNotes(BuildContext context) {
    return _Section(
      title: 'Notes',
      icon: Icons.note_outlined,
      children: [
        Text(bill.notes!, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  void _viewImage(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Receipt')),
          body: PhotoView(imageProvider: NetworkImage(url)),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Bill'),
        content: const Text('Are you sure you want to delete this bill? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<BillBloc>().add(BillDeleteEvent(bill.id));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _Section({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: valueColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarrantyBadge extends StatelessWidget {
  final WarrantyStatus status;

  const _WarrantyBadge({required this.status});

  Color get _color {
    switch (status) {
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

  String get _label {
    switch (status) {
      case WarrantyStatus.active:
        return 'Active';
      case WarrantyStatus.expiringSoon:
        return 'Expiring Soon';
      case WarrantyStatus.expired:
        return 'Expired';
      case WarrantyStatus.noWarranty:
        return 'No Warranty';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _color,
        ),
      ),
    );
  }
}

class _ValueChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ValueChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
