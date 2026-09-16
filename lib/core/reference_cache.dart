/// Простейший кэш справочников в памяти.
/// Живёт, пока открыта вкладка.
class ReferenceCache {
  final Map<String, Object> _cache = {};

  /// Вернуть значение из кэша или загрузить через [loader].
  Future<T> load<T>(String key, Future<T> Function() loader) async {
    final cached = _cache[key];
    if (cached != null) return cached as T;
    final value = await loader();
    _cache[key] = value as Object;
    return value;
  }

  /// Сбросить один справочник — например, после создания клиента,
  /// чтобы в следующий раз список пришёл свежим.
  void invalidate(String key) => _cache.remove(key);

  /// Сбросить всё — используется при выходе из системы или по кнопке.
  void invalidateAll() => _cache.clear();
}
