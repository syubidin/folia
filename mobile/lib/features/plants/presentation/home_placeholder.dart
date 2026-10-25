import 'package:flutter/material.dart';

class HomePlaceholder extends StatelessWidget {
  const HomePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Folia')),
      body: Center(
        child: Text(
          'Taman Saya',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
