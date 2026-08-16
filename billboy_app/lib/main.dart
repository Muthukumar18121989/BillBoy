import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/di/injection_container.dart' as di;
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/auth/auth_event.dart';
import 'presentation/blocs/auth/auth_state.dart';
import 'presentation/blocs/bill/bill_bloc.dart';
import 'presentation/blocs/dashboard/dashboard_bloc.dart';
import 'presentation/blocs/subscription/subscription_bloc.dart';
import 'presentation/blocs/warranty/warranty_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase credentials injected at build time via --dart-define.
  // Never hardcode API keys in source. For local dev, use:
  //   flutter run --dart-define=FIREBASE_API_KEY=... --dart-define=FIREBASE_APP_ID=...
  // CI/CD injects these via GitHub Actions secrets.
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
      appId: String.fromEnvironment('FIREBASE_APP_ID'),
      messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: '851190240105'),
      projectId: String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: 'billboy-1ff2c'),
      storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: 'billboy-1ff2c.firebasestorage.app'),
    ),
  );
  // Crashlytics — catch Flutter framework errors
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  // Catch async errors outside Flutter framework
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  // Disable Crashlytics in debug mode so errors surface in console
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);

  // Analytics
  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(!kDebugMode);

  await Hive.initFlutter();
  await di.init();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const BillBoyApp());
}

class BillBoyApp extends StatelessWidget {
  const BillBoyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<AuthBloc>()..add(AuthCheckStatusEvent())),
        BlocProvider(create: (_) => di.sl<BillBloc>()),
        BlocProvider(create: (_) => di.sl<DashboardBloc>()),
        BlocProvider(create: (_) => di.sl<WarrantyBloc>()),
        BlocProvider(create: (_) => di.sl<SubscriptionBloc>()),
      ],
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          return MaterialApp.router(
            title: 'BillBoy',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            routerConfig: AppRouter.router(authState),
          );
        },
      ),
    );
  }
}
