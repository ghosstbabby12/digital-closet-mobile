import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Curador de Moda IA', style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: AppColors.accent),
          ],
        ),
      ),
    );
  }
}
