import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String? photoUrl;
  final bool emailVerified;
  final DateTime createdAt;
  final UserPreferences preferences;

  const UserEntity({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.photoUrl,
    required this.emailVerified,
    required this.createdAt,
    required this.preferences,
  });

  @override
  List<Object?> get props => [id, email];
}

class UserPreferences extends Equatable {
  final String currency;
  final String themeMode;
  final List<String> visibleColumns;
  final bool emailNotifications;
  final bool pushNotifications;
  final bool smsNotifications;

  const UserPreferences({
    this.currency = 'INR',
    this.themeMode = 'system',
    this.visibleColumns = const [],
    this.emailNotifications = true,
    this.pushNotifications = true,
    this.smsNotifications = false,
  });

  @override
  List<Object?> get props => [currency, themeMode, visibleColumns];
}
