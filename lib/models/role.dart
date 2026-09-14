/// Роль пользователя в системе логистики.
///
/// Уровни:
/// - manager (1) — Руководитель. Аналитика, просмотр.
/// - logist  (2) — Логист. Операции: заказы, маршруты, клиенты.
/// - admin   (3) — Администратор. Управление системой.
enum Role {
  manager(1, 'Руководитель'),
  logist(2, 'Логист'),
  admin(3, 'Администратор');

  final int level;
  final String label;

  const Role(this.level, this.label);

  /// Роль из строки, пришедшей с сервера.
  /// Неизвестное значение трактуем как manager — минимальные права.
  static Role fromString(String? value) {
    switch (value) {
      case 'admin':
        return Role.admin;
      case 'logist':
        return Role.logist;
      case 'manager':
        return Role.manager;
      default:
        return Role.manager;
    }
  }

  /// Строковое представление для отправки на сервер.
  String toJson() => name;
}
