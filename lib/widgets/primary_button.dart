import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Texto junto al indicador mientras carga (ej. "Armando tu outfit..."); sin él, solo el indicador.
  final String? loadingLabel;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.loadingLabel,
  });

  @override
  Widget build(BuildContext context) {
    final spinner = SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(strokeWidth: 2.2, color: Theme.of(context).colorScheme.onPrimary),
    );
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? (loadingLabel == null
                ? spinner
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [spinner, const SizedBox(width: 12), Text(loadingLabel!)],
                  ))
          : icon == null
          ? Text(label)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [Icon(icon, size: 20), const SizedBox(width: 8), Text(label)],
            ),
    );
  }
}
