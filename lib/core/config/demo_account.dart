/// Demo account shown on the login screen so reviewers can try the app.
/// Can be overridden at build time with
/// `--dart-define=DEMO_EMAIL=... --dart-define=DEMO_PASSWORD=...`;
/// pass empty values to hide the box.
const String demoEmail = String.fromEnvironment('DEMO_EMAIL', defaultValue: 'ghostbabby@gmail.com');
const String demoPassword = String.fromEnvironment('DEMO_PASSWORD', defaultValue: 'camila123');

bool get hasDemoAccount => demoEmail.isNotEmpty && demoPassword.isNotEmpty;
