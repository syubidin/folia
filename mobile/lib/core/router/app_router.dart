import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:folia/features/plants/presentation/home_placeholder.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePlaceholder(),
      ),
    ],
  );
});
