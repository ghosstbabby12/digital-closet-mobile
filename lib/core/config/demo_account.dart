/// Demo account shown on the login screen so reviewers can try the app.
/// Set at build time so the password never lands in git:
/// `flutter build apk --dart-define=DEMO_EMAIL=... --dart-define=DEMO_PASSWORD=...`
const String demoEmail = String.fromEnvironment('DEMO_EMAIL');
const String demoPassword = String.fromEnvironment('DEMO_PASSWORD');

bool get hasDemoAccount => demoEmail.isNotEmpty && demoPassword.isNotEmpty;
