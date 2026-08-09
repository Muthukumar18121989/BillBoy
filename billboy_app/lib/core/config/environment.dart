enum AppEnvironment { development, staging, production }

class Environment {
  static const String _env = String.fromEnvironment('APP_ENV', defaultValue: 'development');

  static AppEnvironment get current {
    switch (_env) {
      case 'staging':
        return AppEnvironment.staging;
      case 'production':
        return AppEnvironment.production;
      default:
        return AppEnvironment.development;
    }
  }

  static bool get isDevelopment => current == AppEnvironment.development;
  static bool get isStaging => current == AppEnvironment.staging;
  static bool get isProduction => current == AppEnvironment.production;
}
