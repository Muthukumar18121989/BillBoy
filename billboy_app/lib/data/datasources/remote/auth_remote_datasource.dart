import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/errors/exceptions.dart';
import '../../../domain/entities/user_entity.dart';

abstract class AuthRemoteDataSource {
  Future<UserEntity> signUp({required String fullName, required String email, required String password, String? phone});
  Future<UserEntity> signIn({required String email, required String password});
  Future<UserEntity> signInWithGoogle();
  Future<UserEntity> signInWithApple();
  Future<void> signOut();
  Future<void> sendEmailVerification();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> verifyOtp(String phone, String otp);
  Future<UserEntity?> getCurrentUser();
  Future<UserEntity> updateProfile({String? fullName, String? phone, String? photoUrl});
  Stream<UserEntity?> get authStateStream;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final _googleSignIn = GoogleSignIn();

  AuthRemoteDataSourceImpl(this._auth, this._firestore);

  CollectionReference get _users => _firestore.collection('users');

  @override
  Future<UserEntity> signUp({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user?.updateDisplayName(fullName);

      final user = UserEntity(
        id: credential.user!.uid,
        fullName: fullName,
        email: email,
        phone: phone,
        emailVerified: false,
        createdAt: DateTime.now(),
        preferences: const UserPreferences(),
      );

      await _users.doc(user.id).set(_userToMap(user));
      await credential.user?.sendEmailVerification();
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    }
  }

  @override
  Future<UserEntity> signIn({required String email, required String password}) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return await _getUserFromFirestore(credential.user!.uid);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    }
  }

  @override
  Future<UserEntity> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw AuthException('Google sign in cancelled');

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user!;

      final existing = await _users.doc(firebaseUser.uid).get();
      if (!existing.exists) {
        final user = UserEntity(
          id: firebaseUser.uid,
          fullName: firebaseUser.displayName ?? googleUser.displayName ?? '',
          email: firebaseUser.email ?? '',
          photoUrl: firebaseUser.photoURL,
          emailVerified: true,
          createdAt: DateTime.now(),
          preferences: const UserPreferences(),
        );
        await _users.doc(user.id).set(_userToMap(user));
        return user;
      }
      return await _getUserFromFirestore(firebaseUser.uid);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    }
  }

  @override
  Future<UserEntity> signInWithApple() async {
    // Apple Sign In implementation requires sign_in_with_apple package
    throw AuthException('Apple Sign In not configured');
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  @override
  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    }
  }

  @override
  Future<void> verifyOtp(String phone, String otp) async {
    // OTP verification implementation
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;
    return await _getUserFromFirestore(firebaseUser.uid);
  }

  @override
  Future<UserEntity> updateProfile({String? fullName, String? phone, String? photoUrl}) async {
    final user = _auth.currentUser;
    if (user == null) throw AuthException('Not authenticated');

    if (fullName != null) await user.updateDisplayName(fullName);
    if (photoUrl != null) await user.updatePhotoURL(photoUrl);

    await _users.doc(user.uid).update({
      if (fullName != null) 'fullName': fullName,
      if (phone != null) 'phone': phone,
      if (photoUrl != null) 'photoUrl': photoUrl,
    });

    return await _getUserFromFirestore(user.uid);
  }

  @override
  Stream<UserEntity?> get authStateStream {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      try {
        return await _getUserFromFirestore(user.uid);
      } catch (_) {
        return null;
      }
    });
  }

  Future<UserEntity> _getUserFromFirestore(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) throw AuthException('User profile not found');
    final data = doc.data() as Map<String, dynamic>;

    return UserEntity(
      id: uid,
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String?,
      photoUrl: data['photoUrl'] as String?,
      emailVerified: _auth.currentUser?.emailVerified ?? false,
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      preferences: const UserPreferences(),
    );
  }

  Map<String, dynamic> _userToMap(UserEntity user) {
    return {
      'fullName': user.fullName,
      'email': user.email,
      'phone': user.phone,
      'photoUrl': user.photoUrl,
      'createdAt': user.createdAt,
    };
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found': return 'No user found with this email';
      case 'wrong-password': return 'Incorrect password';
      case 'email-already-in-use': return 'Email is already registered';
      case 'weak-password': return 'Password is too weak';
      case 'invalid-email': return 'Invalid email address';
      case 'user-disabled': return 'This account has been disabled';
      case 'too-many-requests': return 'Too many attempts. Please try again later';
      default: return 'Authentication failed. Please try again';
    }
  }
}
