import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:folia/core/network/dio_client.dart';
import 'package:folia/features/auth/presentation/auth_controller.dart';

final _serverCheckProvider = FutureProvider.autoDispose<String>((ref) async {
  final res = await ref.watch(dioProvider).get<Map<String, dynamic>>('/v1/me');
  return res.data?['user_id'] as String? ?? '-';
});

class HomePlaceholder extends ConsumerWidget {
  const HomePlaceholder({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final check = ref.watch(_serverCheckProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Folia'),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout),
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: Center(
        child: check.when(
          data: (id) =>
              Text('Server OK\nuser: $id', textAlign: TextAlign.center),
          loading: () => const CircularProgressIndicator(),
          error: (e, stack) => Text(
            e is DioException && e.response?.statusCode == 401
                ? 'Token ditolak server'
                : 'Server tidak terjangkau',
          ),
        ),
      ),
    );
  }
}
