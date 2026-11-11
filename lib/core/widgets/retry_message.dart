import 'package:flutter/material.dart';

/// A centered message with a "Reintentar" button, for content that failed to load.
class RetryMessage extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const RetryMessage({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
