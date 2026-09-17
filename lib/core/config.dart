/// Базовый адрес PocketBase.
///
/// Задаётся при сборке:
///   flutter run -d chrome --web-hostname 127.0.0.1 --web-port 5000 \
///     --dart-define=API_BASE_URL=http://127.0.0.1:8090
///
/// По умолчанию — локальный PocketBase.
/// ВАЖНО: без суффикса `/api` — префикс `/api/collections/...`
/// дописывается уже в репозиториях.
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8090',
);
