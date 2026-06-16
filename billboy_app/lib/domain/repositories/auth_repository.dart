import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> signUp({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  });

  Future<Either<Failure, UserEntity>> signIn({
    required String email,
    required String password,
  });

  Future<Either<Failure, UserEntity>> signInWithGoogle();
  Future<Either<Failure, UserEntity>> signInWithApple();

  Future<Either<Failure, void>> signOut();

  Future<Either<Failure, void>> sendEmailVerification();
  Future<Either<Failure, void>> sendPasswordResetEmail(String email);
  Future<Either<Failure, void>> verifyOtp(String phone, String otp);

  Future<Either<Failure, UserEntity?>> getCurrentUser();
  Future<Either<Failure, bool>> isAuthenticated();

  Future<Either<Failure, UserEntity>> updateProfile({
    String? fullName,
    String? phone,
    String? photoUrl,
  });

  Stream<UserEntity?> get authStateStream;
}
