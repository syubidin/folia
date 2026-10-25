import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:folia/features/auth/data/supabase_auth_repository.dart';
import 'package:folia/features/auth/domain/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => SupabaseAuthRepository(Supabase.instance.client.auth),
);
