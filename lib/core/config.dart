/// Базовый адрес API. Задаётся при сборке:
/// flutter run -d chrome --web-port=5555 \
///   --dart-define=API_BASE_URL=http://localhost:8080/api
///
/// Значение по умолчанию — локальный мок-сервер.
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080/api',
);
