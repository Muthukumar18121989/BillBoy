import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(AuthInitialState()) {
    on<AuthCheckStatusEvent>(_onCheckStatus);
    on<AuthSignUpEvent>(_onSignUp);
    on<AuthSignInEvent>(_onSignIn);
    on<AuthGoogleSignInEvent>(_onGoogleSignIn);
    on<AuthAppleSignInEvent>(_onAppleSignIn);
    on<AuthSignOutEvent>(_onSignOut);
    on<AuthSendEmailVerificationEvent>(_onSendEmailVerification);
    on<AuthForgotPasswordEvent>(_onForgotPassword);
    on<AuthVerifyOtpEvent>(_onVerifyOtp);
  }

  Future<void> _onCheckStatus(AuthCheckStatusEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoadingState());
    final result = await _authRepository.getCurrentUser();
    result.fold(
      (failure) => emit(AuthUnauthenticatedState()),
      (user) => user != null
          ? emit(AuthAuthenticatedState(user))
          : emit(AuthUnauthenticatedState()),
    );
  }

  Future<void> _onSignUp(AuthSignUpEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoadingState());
    final result = await _authRepository.signUp(
      fullName: event.fullName,
      email: event.email,
      password: event.password,
      phone: event.phone,
    );
    result.fold(
      (failure) => emit(AuthErrorState(failure.message)),
      (user) => emit(AuthAuthenticatedState(user)),
    );
  }

  Future<void> _onSignIn(AuthSignInEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoadingState());
    final result = await _authRepository.signIn(
      email: event.email,
      password: event.password,
    );
    result.fold(
      (failure) => emit(AuthErrorState(failure.message)),
      (user) => emit(AuthAuthenticatedState(user)),
    );
  }

  Future<void> _onGoogleSignIn(AuthGoogleSignInEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoadingState());
    final result = await _authRepository.signInWithGoogle();
    result.fold(
      (failure) => emit(AuthErrorState(failure.message)),
      (user) => emit(AuthAuthenticatedState(user)),
    );
  }

  Future<void> _onAppleSignIn(AuthAppleSignInEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoadingState());
    final result = await _authRepository.signInWithApple();
    result.fold(
      (failure) => emit(AuthErrorState(failure.message)),
      (user) => emit(AuthAuthenticatedState(user)),
    );
  }

  Future<void> _onSignOut(AuthSignOutEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoadingState());
    final result = await _authRepository.signOut();
    result.fold(
      (failure) => emit(AuthErrorState(failure.message)),
      (_) => emit(AuthUnauthenticatedState()),
    );
  }

  Future<void> _onSendEmailVerification(
    AuthSendEmailVerificationEvent event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _authRepository.sendEmailVerification();
    result.fold(
      (failure) => emit(AuthErrorState(failure.message)),
      (_) => emit(AuthEmailVerificationSentState()),
    );
  }

  Future<void> _onForgotPassword(AuthForgotPasswordEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoadingState());
    final result = await _authRepository.sendPasswordResetEmail(event.email);
    result.fold(
      (failure) => emit(AuthErrorState(failure.message)),
      (_) => emit(AuthPasswordResetSentState()),
    );
  }

  Future<void> _onVerifyOtp(AuthVerifyOtpEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoadingState());
    final result = await _authRepository.verifyOtp(event.phone, event.otp);
    result.fold(
      (failure) => emit(AuthErrorState(failure.message)),
      (_) => emit(AuthOtpVerifiedState()),
    );
  }
}
