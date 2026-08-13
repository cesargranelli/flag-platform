/// Configuração de ambiente do Flag Platform.
///
/// Valores injetados via `--dart-define` no build:
/// - `API_BASE_URL`: base URL da API REST (default: `http://localhost:8080`)
/// - `ENVIRONMENT`: nome do ambiente (default: `dev`)
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'dev',
  );

  const AppConfig._();
}
