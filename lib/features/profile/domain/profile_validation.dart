// Same rules as the server. The messages are shown in the app, so they are in Spanish.

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
final _phonePattern = RegExp(r'^\+?[0-9][0-9 ()-]{6,24}$');
const minPasswordLength = 6;

String? validateEmail(String? value) => _emailPattern.hasMatch(value?.trim() ?? '') ? null : 'Escribe un correo válido';

/// The phone is optional: empty is valid.
String? validatePhone(String? value) {
  final phone = value?.trim() ?? '';
  if (phone.isEmpty || _phonePattern.hasMatch(phone)) return null;
  return 'Usa solo números, espacios, guiones y un + inicial';
}

String? validateNewPassword(String? value) =>
    (value == null || value.length < minPasswordLength) ? 'Mínimo $minPasswordLength caracteres' : null;

String? requireCurrentPassword(String? value) =>
    (value == null || value.isEmpty) ? 'Escribe tu contraseña actual' : null;
