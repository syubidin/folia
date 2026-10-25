import 'package:folia/core/error/result.dart';
import 'package:folia/features/auth/domain/auth_user.dart';

abstract interface class AuthRepository {
  AuthUser? get currentUser;
  Stream<AuthUser?> authChanges();
  Future<Result<void>> signIn({
    required String email,
    required String password,
  });
  Future<Result<bool>> signUp({
    required String email,
    required String password,
  });
  Future<Result<void>> signOut();
}
