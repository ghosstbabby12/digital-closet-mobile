import 'package:flutter/material.dart';

import 'package:closet_ai/core/network/api_exception.dart';

const _unexpectedError = 'Ocurrió un error inesperado. Intenta de nuevo.';

/// Shows the server's message for API errors and a generic one for anything else.
void showErrorSnackBar(BuildContext context, Object error) {
  final message = error is ApiException ? error.message : _unexpectedError;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
