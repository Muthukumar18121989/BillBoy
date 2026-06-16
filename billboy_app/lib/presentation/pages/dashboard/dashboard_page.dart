import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_utils.dart';
import '../../blocs/bill/bill_bloc.dart';
import '../../blocs/bill/bill_event.dart';
import '../../blocs/bill/bill_state.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../widgets/bill/bill_table.dart';
import '../../widgets/common/bb_search_bar.dart';
import '../../widgets/common/stat_card.dart';
import '../../widgets/common/warranty_alert_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<BillBloc>().add(const BillLoadEvent());
    context.read<DashboardBloc>().add(DashboardLoadEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  context.read<BillBloc>().add(const BillLoadEvent());
                  context.read<DashboardBloc>().add(DashboardRefreshEvent());
                },
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildStats()),
                    SliverToBoxAdapter(child: _buildWarrantyAlerts()),
                    SliverToBoxAdapter(child: _buildTableSection()),
                    const SliverToBoxAdapter(child: SizedBox(height: 80)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/bill/capture'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Bill',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ).animate().scale(delay: 300.ms, curve: Curves.elasticOut),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BillBoy',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      'Your bill manager',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => context.push('/notifications'),
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications_outlined, size: 26),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => context.push('/settings'),
                icon: const Icon(Icons.settings_outlined, size: 26),
              ),
            ],
          ),
          const SizedBox(height: 16),
          BBSearchBar(
            controller: _searchController,
            onChanged: (query) => context.read<BillBloc>().add(BillSearchEvent(query)),
            onFilter: () => _showFilterSheet(context),
          ),
          const SizedBox(height: 16),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1);
  }

  Widget _buildStats() {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoadedState) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'Total Products',
                        value: '${state.totalProducts}',
                        icon: Icons.inventory_2_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        title: 'Total Spend',
                        value: CurrencyUtils.formatCompact(state.totalSpend),
                        icon: Icons.currency_rupee_rounded,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'Active Warranties',
                        value: '${state.activeWarranties}',
                        icon: Icons.verified_outlined,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        title: 'Expiring Soon',
                        value: '${state.upcomingExpiries}',
                        icon: Icons.warning_amber_rounded,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
        }
        if (state is DashboardLoadingState) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildWarrantyAlerts() {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is! DashboardLoadedState || state.expiringWarranties.isEmpty) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Warranty Alerts',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...state.expiringWarranties.take(3).map(
                    (item) => WarrantyAlertCard(
                      productName: item['productName'] as String,
                      daysLeft: item['daysLeft'] as int,
                      onTap: () => context.push('/bill/${item['id']}'),
                    ),
                  ),
              const SizedBox(height: 20),
            ],
          ),
        ).animate().fadeIn(delay: 300.ms);
      },
    );
  }

  Widget _buildTableSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'All Purchases',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              BlocBuilder<BillBloc, BillState>(
                builder: (context, state) {
                  return Row(
                    children: [
                      if (state is BillLoadedState)
                        Text(
                          '${state.bills.length} items',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, size: 20),
                        onSelected: (value) {
                          if (value == 'csv') context.read<BillBloc>().add(BillExportCsvEvent());
                          if (value == 'pdf') context.read<BillBloc>().add(BillExportPdfEvent());
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'csv', child: Text('Export CSV')),
                          PopupMenuItem(value: 'pdf', child: Text('Export PDF')),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          BlocBuilder<BillBloc, BillState>(
            builder: (context, state) {
              if (state is BillLoadingState) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (state is BillLoadedState) {
                if (state.bills.isEmpty) {
                  return _buildEmptyState(context);
                }
                return BillTable(bills: state.bills);
              }
              if (state is BillSearchResultState) {
                return BillTable(bills: state.results);
              }
              if (state is BillErrorState) {
                return Center(
                  child: Text(state.message, style: const TextStyle(color: AppColors.error)),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: AppColors.textSecondaryLight.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No bills yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first bill by tapping the + button',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _FilterSheet(),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet();

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  String? _selectedCategory;
  String? _warrantyStatus;
  String _sortBy = 'purchaseDate';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Filter & Sort', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          // Sort
          Text('Sort By', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['Purchase Date', 'Amount', 'Product Name', 'Warranty End'].map((s) {
              return ChoiceChip(
                label: Text(s),
                selected: _sortBy == s,
                onSelected: (_) => setState(() => _sortBy = s),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          // Warranty Status
          Text('Warranty Status', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['Active', 'Expiring Soon', 'Expired', 'No Warranty'].map((s) {
              return ChoiceChip(
                label: Text(s),
                selected: _warrantyStatus == s,
                onSelected: (_) => setState(() => _warrantyStatus = _warrantyStatus == s ? null : s),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
