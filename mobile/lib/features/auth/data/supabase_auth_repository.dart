import 'dart:io';

import 'package:folia/core/error/result.dart';
import 'package:folia/features/auth/domain/auth_repository.dart';
import 'package:folia/features/auth/domain/auth_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

final class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._auth);

  final GoTrueClient _auth;

  AuthUser? _map(User? u) =>
      u == null ? null : AuthUser(id: u.id, email: u.email ?? '');

  @override
  AuthUser? get currentUser => _map(_auth.currentUser);

  @override
  Stream<AuthUser?> authChanges() =>
      _auth.onAuthStateChange.map((e) => _map(e.session?.user));

  @override
  Future<Result<void>> signIn({
    required String email,
    required String password,
  }) =>
      _guard(() async {
        await _auth.signInWithPassword(
          email: email.trim(),
          password: password,
        );
      });

  @override
  Future<Result<bool>> signUp({
    required String email,
    required String password,
  }) =>
      _guard(() async {
        final res = await _auth.signUp(
          email: email.trim(),
          password: password,
        );
        return res.session == null;
      });

  @override
  Future<Result<void>> signOut() => _guard(_auth.signOut);

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Ok(await action());
    } on AuthException catch (e) {
      // ignore: avoid_print
      print('Supabase AuthException: ${e.message} (Status: ${e.statusCode})');
      return Err(_mapFailure(e));
    } on SocketException catch (e) {
      // ignore: avoid_print
      print('SocketException: $e');
      return const Err(NetworkFailure());
    } catch (e, st) {
      // ignore: avoid_print
      print('Unknown Error: $e\n$st');
      return const Err(ServerFailure());
    }
  }

  Failure _mapFailure(AuthException e) => switch (e.statusCode) {
        '400' ||
        '401' =>
          const ValidationFailure('Email atau kata sandi salah'),
        '422' => const ValidationFailure(
            'Data tidak valid atau email sudah terdaftar',
          ),
        '429' => const ServerFailure(
            'Terlalu banyak percobaan, coba lagi nanti',
          ),
        _ => const ServerFailure(),
      };
}
