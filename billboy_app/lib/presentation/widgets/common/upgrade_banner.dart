import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../blocs/subscription/subscription_bloc.dart';
import '../../blocs/subscription/subscription_state.dart';
import '../../../domain/entities/subscription_entity.dart';
import '../../../core/config/app_config.dart';

class UpgradeBanner extends StatelessWidget {
  const UpgradeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SubscriptionBloc, SubscriptionState>(
      builder: (context, state) {
        if (state is! SubscriptionLoadedState) return const SizedBox.shrink();

        final sub = state.subscription;

        // Pro users: no banner
        if (sub.isPro) return const SizedBox.shrink();

        // Trial active: show days-remaining banner
        if (sub.isTrialActive) {
          final days = sub.trialDaysRemaining ?? 0;
          return _TrialBanner(daysRemaining: days);
        }

        // Free user: show bill count progress if approaching limit
        return const _FreeUpgradeBanner();
      },
    );
  }
}

class _TrialBanner extends StatelessWidget {
  final int daysRemaining;
  const _TrialBanner({required this.daysRemaining});

  @override
  Widget build(BuildContext context) {
    final isUrgent = daysRemaining <= 2;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isUrgent ? AppColors.warning.withOpacity(0.15) : AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUrgent ? AppColors.warning : AppColors.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isUrgent ? Icons.timer_outlined : Icons.star_border_rounded,
            color: isUrgent ? AppColors.warning : AppColors.primary,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              daysRemaining == 0
                  ? 'Your trial ends today — upgrade to keep Pro access'
                  : 'Pro trial: $daysRemaining ${daysRemaining == 1 ? 'day' : 'days'} remaining',
              style: TextStyle(
                fontSize: 13,
                color: isUrgent ? AppColors.warning : AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () => context.push('/subscription'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Upgrade', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _FreeUpgradeBanner extends StatelessWidget {
  const _FreeUpgradeBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.08), AppColors.accent.withOpacity(0.08)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium_outlined, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Upgrade to Pro — unlimited bills, no ads',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            onPressed: () => context.push('/subscription'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('See Plans', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
