import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:folia/features/auth/data/supabase_auth_repository.dart';
import 'package:folia/features/auth/domain/auth_repository.dart';
import 'package:folia/features/auth/domain/auth_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => SupabaseAuthRepository(Supabase.instance.client.auth),
);

final authUserProvider = StreamProvider<AuthUser?>(
  (ref) => ref.watch(authRepositoryProvider).authChanges(),
);
