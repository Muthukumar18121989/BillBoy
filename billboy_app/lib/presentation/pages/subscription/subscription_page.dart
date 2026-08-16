import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/services/purchase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/config/app_config.dart';

class SubscriptionPage extends StatelessWidget {
  final bool isLimitReached;

  const SubscriptionPage({super.key, this.isLimitReached = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade to Pro'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (isLimitReached) _buildLimitReachedBanner(context),
              const SizedBox(height: 16),
              _buildHero(context),
              const SizedBox(height: 32),
              _buildFeatureList(context),
              const SizedBox(height: 32),
              _buildPlanCards(context),
              const SizedBox(height: 16),
              _buildRestoreButton(context),
              const SizedBox(height: 24),
              _buildLegal(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLimitReachedBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline_rounded, color: AppColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'You\'ve reached the ${AppConfig.freeBillLimit}-bill limit on the Free plan. Upgrade to add unlimited bills.',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildHero(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 20),
        Text(
          'BillBoy Pro',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Unlimited bills, no ads, priority support',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
  }

  Widget _buildFeatureList(BuildContext context) {
    final features = [
      (Icons.all_inclusive_rounded, 'Unlimited bill storage'),
      (Icons.block_rounded, 'No advertisements'),
      (Icons.photo_camera_outlined, 'OCR bill scanning (coming soon)'),
      (Icons.cloud_download_outlined, 'CSV & PDF export'),
      (Icons.notifications_active_outlined, 'Smart warranty alerts'),
      (Icons.support_agent_outlined, 'Priority support'),
    ];

    return Column(
      children: features
          .map(
            (f) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(f.$1, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(f.$2, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          )
          .toList(),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildPlanCards(BuildContext context) {
    return FutureBuilder<List<ProductDetails>>(
      future: sl<PurchaseService>().loadProducts(),
      builder: (context, snapshot) {
        final products = snapshot.data ?? [];
        final monthly = products.where((p) => p.id == AppConfig.subscriptionMonthlyId).firstOrNull;
        final annual = products.where((p) => p.id == AppConfig.subscriptionAnnualId).firstOrNull;

        return Column(
          children: [
            _PlanCard(
              title: 'Monthly',
              price: monthly?.price ?? '₹299',
              period: '/month',
              product: monthly,
              isPopular: false,
            ),
            const SizedBox(height: 12),
            _PlanCard(
              title: 'Annual',
              price: annual?.price ?? '₹1,999',
              period: '/year',
              product: annual,
              isPopular: true,
              savings: 'Save 44%',
            ),
          ],
        );
      },
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildRestoreButton(BuildContext context) {
    return TextButton(
      onPressed: () async {
        await sl<PurchaseService>().restorePurchases();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Checking for previous purchases…')),
          );
        }
      },
      child: const Text('Restore Purchases'),
    );
  }

  Widget _buildLegal(BuildContext context) {
    return Text(
      'Subscriptions auto-renew unless cancelled at least 24 hours before the end of the current period. Manage or cancel in Google Play.',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondaryLight.withOpacity(0.6),
          ),
      textAlign: TextAlign.center,
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final ProductDetails? product;
  final bool isPopular;
  final String? savings;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    required this.product,
    required this.isPopular,
    this.savings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPopular ? AppColors.primary : AppColors.borderLight,
          width: isPopular ? 2 : 1,
        ),
        color: isPopular ? AppColors.primary.withOpacity(0.05) : null,
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            price,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Text(period, style: Theme.of(context).textTheme.bodySmall),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: product == null
                      ? null
                      : () async {
                          await sl<PurchaseService>().purchase(product!);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPopular ? AppColors.primary : null,
                    foregroundColor: isPopular ? Colors.white : AppColors.primary,
                  ),
                  child: const Text('Subscribe'),
                ),
              ],
            ),
          ),
          if (isPopular)
            Positioned(
              top: 0,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                ),
                child: Text(
                  savings ?? 'Best Value',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
