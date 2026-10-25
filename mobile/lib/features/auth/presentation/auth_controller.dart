import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:folia/core/error/result.dart';
import 'package:folia/features/auth/data/auth_providers.dart';

final authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);

class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<Result<void>> signIn(String email, String password) => _run(
        () => ref
            .read(authRepositoryProvider)
            .signIn(email: email, password: password),
      );

  Future<Result<bool>> signUp(String email, String password) => _run(
        () => ref
            .read(authRepositoryProvider)
            .signUp(email: email, password: password),
      );

  Future<Result<void>> signOut() =>
      _run(() => ref.read(authRepositoryProvider).signOut());

  Future<Result<T>> _run<T>(Future<Result<T>> Function() action) async {
    state = const AsyncLoading();
    final result = await action();
    state = const AsyncData(null);
    return result;
  }
}
