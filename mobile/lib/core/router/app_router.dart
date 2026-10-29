import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:folia/features/auth/data/auth_providers.dart';
import 'package:folia/features/auth/presentation/login_screen.dart';
import 'package:folia/features/plants/presentation/garden_screen.dart';
import 'package:folia/features/plants/presentation/plant_form_screen.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final refresh = _AuthRefresh(repo.authChanges());
  ref.onDispose(refresh.dispose);

  return GoRouter(
    refreshListenable: refresh,
    redirect: (context, state) {
      final loggedIn = repo.currentUser != null;
      final atLogin = state.matchedLocation == '/login';
      if (!loggedIn) return atLogin ? null : '/login';
      return atLogin ? '/' : null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const GardenScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/plants/new',
        builder: (context, state) => const PlantFormScreen(),
      ),
      GoRoute(
        path: '/plants/:id/edit',
        builder: (context, state) =>
            PlantFormScreen(plantId: state.pathParameters['id']),
      ),
    ],
  );
});

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Stream<Object?> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<Object?> _sub;

  @override
  void dispose() {
    unawaited(_sub.cancel());
    super.dispose();
  }
}
