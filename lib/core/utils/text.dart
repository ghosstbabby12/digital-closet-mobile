/// "fiesta" → "Fiesta".
String capitalized(String text) => text.isEmpty ? text : '${text[0].toUpperCase()}${text.substring(1)}';
