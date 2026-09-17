import 'role.dart';

/// Пользователь приложения.
///
/// Хранится в коллекции `users` PocketBase.
/// Помимо встроенных полей (id, email, username) коллекция
/// расширена полями `role`, `fullName` и `deleted`.
class AppUser {
  /// Идентификатор записи в PocketBase — строка из 15 символов.
  final String id;

  /// Логин. Используется для входа в PocketBase —
  /// в `identity` эндпоинта `auth-with-password`.
  final String username;

  /// ФИО. Отображается в интерфейсе.
  final String fullName;

  /// Email.
  final String email;

  /// Роль: manager / logist / admin.
  final Role role;

  /// Soft-delete: пользователь скрыт, но запись осталась.
  /// Кнопка «Скрыть» ставит true, «Восстановить» — false.
  final bool isDeleted;

  const AppUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.role,
    this.isDeleted = false,
  });

  AppUser copyWith({
    String? id,
    String? username,
    String? fullName,
    String? email,
    Role? role,
    bool? isDeleted,
  }) {
    return AppUser(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as String? ?? '',
    username: json['username'] as String? ?? '',
    fullName: json['fullName'] as String? ?? '',
    email: json['email'] as String? ?? '',
    role: Role.fromString(json['role'] as String?),
    isDeleted: json['deleted'] as bool? ?? false,
  );

  /// Для отправки в PocketBase при создании/обновлении.
  /// `id` не кладём — его генерирует сервер.
  /// `password` тоже сюда не кладём: у PocketBase это отдельные
  /// поля (`password`, `passwordConfirm`), которые передаются
  /// вручную в AuthApi.
  Map<String, dynamic> toJson() => {
    'username': username,
    'fullName': fullName,
    'email': email,
    'role': role.toJson(),
  };
}
