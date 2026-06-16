import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_utils.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<DashboardBloc>().add(DashboardLoadEvent());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Spending'),
            Tab(text: 'Categories'),
            Tab(text: 'Warranties'),
          ],
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondaryLight,
          indicatorColor: AppColors.primary,
        ),
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is DashboardLoadedState) {
            return TabBarView(
              controller: _tabController,
              children: [
                _SpendingTab(monthlySpending: state.monthlySpending, totalSpend: state.totalSpend),
                _CategoriesTab(categoryBreakdown: state.categoryBreakdown),
                _WarrantyTab(
                  active: state.activeWarranties,
                  expired: state.expiredWarranties,
                  upcoming: state.upcomingExpiries,
                ),
              ],
            );
          }
          return const Center(child: Text('No analytics data'));
        },
      ),
    );
  }
}

class _SpendingTab extends StatelessWidget {
  final Map<String, double> monthlySpending;
  final double totalSpend;

  const _SpendingTab({required this.monthlySpending, required this.totalSpend});

  @override
  Widget build(BuildContext context) {
    final entries = monthlySpending.entries.toList();
    if (entries.isEmpty) {
      return const Center(child: Text('No spending data'));
    }

    final maxY = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Spending',
                  style: TextStyle(color: Colors.white70, fontFamily: 'Poppins', fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  CurrencyUtils.format(totalSpend),
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: 0.2),

          const SizedBox(height: 28),
          Text('Monthly Spending', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),

          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                maxY: maxY * 1.3,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.borderLight,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          CurrencyUtils.formatCompact(value),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < entries.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(entries[idx].key, style: const TextStyle(fontSize: 10)),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                barGroups: List.generate(entries.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: entries[i].value,
                        color: AppColors.primary,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ).animate().fadeIn(delay: 200.ms),
        ],
      ),
    );
  }
}

class _CategoriesTab extends StatelessWidget {
  final Map<String, double> categoryBreakdown;

  const _CategoriesTab({required this.categoryBreakdown});

  @override
  Widget build(BuildContext context) {
    if (categoryBreakdown.isEmpty) {
      return const Center(child: Text('No category data'));
    }

    final entries = categoryBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final total = entries.fold(0.0, (sum, e) => sum + e.value);
    final colors = AppColors.categoryColors;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Pie chart
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: entries.take(8).map((e) {
                  final color = colors[e.key] ?? AppColors.primary;
                  return PieChartSectionData(
                    color: color,
                    value: e.value,
                    title: '${((e.value / total) * 100).toStringAsFixed(0)}%',
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
                sectionsSpace: 3,
                centerSpaceRadius: 40,
              ),
            ),
          ).animate().fadeIn(),

          const SizedBox(height: 24),
          Text('Breakdown', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),

          ...entries.map((e) {
            final color = colors[e.key] ?? AppColors.primary;
            final pct = total > 0 ? (e.value / total) * 100 : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(e.key, style: Theme.of(context).textTheme.bodyMedium)),
                  Text(
                    '${pct.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    CurrencyUtils.formatCompact(e.value),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _WarrantyTab extends StatelessWidget {
  final int active;
  final int expired;
  final int upcoming;

  const _WarrantyTab({required this.active, required this.expired, required this.upcoming});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Donut chart
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    color: AppColors.warrantyActive,
                    value: active.toDouble(),
                    title: active > 0 ? '$active' : '',
                    radius: 60,
                    titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  PieChartSectionData(
                    color: AppColors.warrantyExpiringSoon,
                    value: upcoming.toDouble(),
                    title: upcoming > 0 ? '$upcoming' : '',
                    radius: 60,
                    titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  PieChartSectionData(
                    color: AppColors.warrantyExpired,
                    value: expired.toDouble(),
                    title: expired > 0 ? '$expired' : '',
                    radius: 60,
                    titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ],
                sectionsSpace: 3,
                centerSpaceRadius: 40,
              ),
            ),
          ).animate().fadeIn(),

          const SizedBox(height: 24),
          _LegendRow(color: AppColors.warrantyActive, label: 'Active', count: active),
          const SizedBox(height: 12),
          _LegendRow(color: AppColors.warrantyExpiringSoon, label: 'Expiring Soon (30 days)', count: upcoming),
          const SizedBox(height: 12),
          _LegendRow(color: AppColors.warrantyExpired, label: 'Expired', count: expired),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const _LegendRow({required this.color, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          Text(
            '$count products',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
