import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthCheckStatusEvent extends AuthEvent {}

class AuthSignUpEvent extends AuthEvent {
  final String fullName;
  final String email;
  final String password;
  final String? phone;

  const AuthSignUpEvent({
    required this.fullName,
    required this.email,
    required this.password,
    this.phone,
  });

  @override
  List<Object?> get props => [email];
}

class AuthSignInEvent extends AuthEvent {
  final String email;
  final String password;

  const AuthSignInEvent({required this.email, required this.password});

  @override
  List<Object?> get props => [email];
}

class AuthGoogleSignInEvent extends AuthEvent {}

class AuthAppleSignInEvent extends AuthEvent {}

class AuthSignOutEvent extends AuthEvent {}

class AuthSendEmailVerificationEvent extends AuthEvent {}

class AuthForgotPasswordEvent extends AuthEvent {
  final String email;
  const AuthForgotPasswordEvent(this.email);

  @override
  List<Object?> get props => [email];
}

class AuthVerifyOtpEvent extends AuthEvent {
  final String phone;
  final String otp;
  const AuthVerifyOtpEvent(this.phone, this.otp);

  @override
  List<Object?> get props => [phone, otp];
}
