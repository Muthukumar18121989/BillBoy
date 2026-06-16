import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../blocs/warranty/warranty_bloc.dart';
import '../../widgets/common/warranty_alert_card.dart';

class WarrantyPage extends StatefulWidget {
  const WarrantyPage({super.key});

  @override
  State<WarrantyPage> createState() => _WarrantyPageState();
}

class _WarrantyPageState extends State<WarrantyPage> {
  int _selectedDays = 90;

  @override
  void initState() {
    super.initState();
    context.read<WarrantyBloc>().add(WarrantyLoadExpiringEvent(days: _selectedDays));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Warranty Tracker'),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.filter_list_rounded),
            onSelected: (days) {
              setState(() => _selectedDays = days);
              context.read<WarrantyBloc>().add(WarrantyLoadExpiringEvent(days: days));
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 30, child: Text('Next 30 days')),
              PopupMenuItem(value: 60, child: Text('Next 60 days')),
              PopupMenuItem(value: 90, child: Text('Next 90 days')),
              PopupMenuItem(value: 365, child: Text('Next 1 year')),
            ],
          ),
        ],
      ),
      body: BlocBuilder<WarrantyBloc, WarrantyState>(
        builder: (context, state) {
          if (state is WarrantyLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is WarrantyLoadedState) {
            if (state.expiringBills.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.verified_rounded, size: 64, color: AppColors.warrantyActive),
                    const SizedBox(height: 16),
                    Text(
                      'All warranties are healthy!',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No warranties expiring in the next ${state.days} days',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppColors.warning),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${state.expiringBills.length} warranty(ies) expiring within ${state.days} days',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.warning,
                              ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(),

                const SizedBox(height: 20),

                ...state.expiringBills.asMap().entries.map((entry) {
                  final bill = entry.value;
                  final daysLeft = AppDateUtils.daysUntilExpiry(bill.warrantyEndDate!);
                  return WarrantyAlertCard(
                    productName: bill.productName,
                    daysLeft: daysLeft,
                    onTap: () => context.push('/bill/${bill.id}'),
                  ).animate().fadeIn(delay: Duration(milliseconds: entry.key * 60)).slideX(begin: 0.1);
                }),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
