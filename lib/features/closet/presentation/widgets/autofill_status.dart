import 'package:flutter/material.dart';

/// What the photo autofill is doing: analyzing, its result, or the privacy notice before it runs.
class AutofillStatus extends StatelessWidget {
  final bool analyzing;
  final String? message;

  const AutofillStatus({super.key, required this.analyzing, required this.message});

  @override
  Widget build(BuildContext context) {
    if (analyzing) {
      return const Row(
        children: [
          SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 10),
          Expanded(child: Text('Completando los datos...')),
        ],
      );
    }
    if (message != null) return Text(message!);
    return Text(
      'Para llenar los datos solos, la foto se envía a Google Gemini, y Google puede '
      'usarla para mejorar sus productos. Usa fotos de la prenda sola, sin personas.',
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}
