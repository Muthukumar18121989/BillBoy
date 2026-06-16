import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/bill_entity.dart';
import '../../presentation/blocs/auth/auth_state.dart';
import '../../presentation/pages/analytics/analytics_page.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/auth/signup_page.dart';
import '../../presentation/pages/bill_capture/bill_capture_page.dart';
import '../../presentation/pages/bill_capture/bill_form_page.dart';
import '../../presentation/pages/bill_detail/bill_detail_page.dart';
import '../../presentation/pages/dashboard/dashboard_page.dart';
import '../../presentation/pages/main_shell.dart';
import '../../presentation/pages/search/search_page.dart';
import '../../presentation/pages/settings/settings_page.dart';
import '../../presentation/pages/splash/splash_page.dart';
import '../../presentation/pages/warranty/warranty_page.dart';

class AppRouter {
  static GoRouter router(AuthState authState) {
    final isAuthenticated = authState is AuthAuthenticatedState;

    return GoRouter(
      initialLocation: '/splash',
      redirect: (context, state) {
        final isSplash = state.fullPath == '/splash';
        final isAuthRoute = state.fullPath?.startsWith('/auth') ?? false;

        if (isSplash) return null;
        if (!isAuthenticated && !isAuthRoute) return '/auth/login';
        if (isAuthenticated && isAuthRoute) return '/home';
        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (_, __) => const SplashPage(),
        ),

        // Auth routes
        GoRoute(
          path: '/auth/login',
          builder: (_, __) => const LoginPage(),
        ),
        GoRoute(
          path: '/auth/signup',
          builder: (_, __) => const SignUpPage(),
        ),
        GoRoute(
          path: '/auth/forgot-password',
          builder: (_, __) => const _ForgotPasswordPage(),
        ),

        // Main shell with bottom nav
        ShellRoute(
          builder: (context, state, child) => MainShell(child: child),
          routes: [
            GoRoute(
              path: '/home',
              builder: (_, __) => const DashboardPage(),
            ),
            GoRoute(
              path: '/analytics',
              builder: (_, __) => const AnalyticsPage(),
            ),
            GoRoute(
              path: '/warranty',
              builder: (_, __) => const WarrantyPage(),
            ),
            GoRoute(
              path: '/search',
              builder: (_, __) => const SearchPage(),
            ),
            GoRoute(
              path: '/settings',
              builder: (_, __) => const SettingsPage(),
            ),
          ],
        ),

        // Bill routes (full screen)
        GoRoute(
          path: '/bill/capture',
          builder: (_, __) => const BillCapturePage(),
        ),
        GoRoute(
          path: '/bill/form',
          builder: (context, state) {
            final extra = state.extra;
            if (extra is OcrExtractedData) {
              return BillFormPage(ocrData: extra);
            }
            if (extra is BillEntity) {
              return BillFormPage(existingBill: extra);
            }
            return const BillFormPage();
          },
        ),
        GoRoute(
          path: '/bill/:id',
          builder: (context, state) {
            final bill = state.extra as BillEntity?;
            if (bill != null) return BillDetailPage(bill: bill);
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          },
        ),

        GoRoute(
          path: '/notifications',
          builder: (_, __) => const _NotificationsPage(),
        ),
      ],
    );
  }
}

class _ForgotPasswordPage extends StatelessWidget {
  const _ForgotPasswordPage();

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reset Password', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Enter your email and we\'ll send you a reset link',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Send Reset Link'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsPage extends StatelessWidget {
  const _NotificationsPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: index < 2
                      ? const Color(0xFFFF5252).withOpacity(0.1)
                      : const Color(0xFFFFB74D).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shield_outlined,
                  color: index < 2 ? const Color(0xFFFF5252) : const Color(0xFFFFB74D),
                ),
              ),
              title: Text(
                'Warranty expiring: Product ${index + 1}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              subtitle: Text(
                '${(index + 1) * 7} days remaining',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              trailing: Text(
                '${index + 1}d ago',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          );
        },
      ),
    );
  }
}
