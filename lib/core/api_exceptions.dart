import 'package:dio/dio.dart';

/// Собственные исключения предметной области.
/// Виджеты и нотифаеры знают только про них — не про Dio.
sealed class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

/// Нет соединения, таймаут, сервер недоступен, заблокировано CORS.
class NetworkException extends ApiException {
  const NetworkException([
    super.message = 'Сервер недоступен. Проверьте соединение.',
  ]);
}

/// 400/401 — не аутентифицирован либо неверные учётные данные.
class UnauthorizedException extends ApiException {
  const UnauthorizedException([super.message = 'Требуется вход в систему.']);
}

/// 403 — роль не позволяет выполнить операцию.
class ForbiddenException extends ApiException {
  const ForbiddenException([
    super.message = 'Недостаточно прав для этого действия.',
  ]);
}

/// 404 — объект не найден.
class NotFoundException extends ApiException {
  const NotFoundException([super.message = 'Запись не найдена.']);
}

/// 409 — нарушено ограничение целостности.
class ConflictException extends ApiException {
  const ConflictException(super.message);
}

/// 422 — ошибки валидации по полям.
/// Ключи errors совпадают с именами полей модели,
/// это позволяет разложить их по полям формы без сопоставления.
class ValidationException extends ApiException {
  final Map<String, String> errors;
  const ValidationException(super.message, this.errors);
}

/// 5xx — ошибка на сервере.
class ServerException extends ApiException {
  const ServerException([
    super.message = 'Ошибка на сервере. Попробуйте позже.',
  ]);
}

/// Перевод типовых английских сообщений PocketBase на русский.
/// Возвращает исходную строку, если перевод не найден.
String? _translatePocketBaseMessage(String? msg) {
  if (msg == null) return null;
  switch (msg) {
    case 'Failed to authenticate.':
      return 'Неверный логин или пароль.';
    case 'The request failed because of validation errors.':
      return 'Ошибка валидации данных.';
    case 'Something went wrong while processing your request.':
      return 'Что-то пошло не так. Попробуйте позже.';
    case "The requested resource wasn't found.":
      return 'Запись не найдена.';
    case 'You are not allowed to perform this request.':
      return 'Недостаточно прав для этого действия.';
    case 'Only admins can perform this action.':
      return 'Действие доступно только администратору.';
    case 'Failed to create record.':
      return 'Не удалось создать запись.';
    case 'Failed to update record.':
      return 'Не удалось обновить запись.';
    case 'Failed to delete record.':
      return 'Не удалось удалить запись.';
    default:
      return msg;
  }
}

/// Преобразование HTTP-статуса и тела ответа в доменное исключение.
ApiException mapHttpError(int status, dynamic body) {
  final rawMessage = (body is Map && body['message'] is String)
      ? body['message'] as String
      : null;
  final message = _translatePocketBaseMessage(rawMessage);

  return switch (status) {
    400 => UnauthorizedException(
      message ?? 'Неверный запрос.',
    ),
    401 => UnauthorizedException(
      message ?? 'Требуется вход в систему.',
    ),
    403 => ForbiddenException(
      message ?? 'Недостаточно прав для этого действия.',
    ),
    404 => NotFoundException(message ?? 'Запись не найдена.'),
    409 => ConflictException(message ?? 'Операция невозможна.'),
    422 => ValidationException(
      message ?? 'Ошибка валидации',
      (body is Map && body['errors'] is Map)
          ? (body['errors'] as Map).map((k, v) => MapEntry('$k', '$v'))
          : const {},
    ),
    _ => ServerException(message ?? 'Неизвестная ошибка (код $status).'),
  };
}

/// Преобразование DioException в доменное исключение.
ApiException mapDioError(DioException e) {
  // Если исключение уже разобрал интерсептор — не разбираем повторно.
  // Без этой проверки ошибка 422 придёт как ServerException,
  // и catch (on ValidationException) никогда не сработает.
  final existing = e.error;
  if (existing is ApiException) return existing;

  return switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => const NetworkException(
      'Сервер не ответил вовремя. Проверьте соединение и попробуйте снова.',
    ),
    DioExceptionType.connectionError => const NetworkException(
      'Не удалось соединиться с сервером. '
      'Проверьте, что сервер запущен и доступен, '
      'и что соединение не блокируется.',
    ),
    DioExceptionType.badCertificate => const NetworkException(
      'Ошибка сертификата сервера.',
    ),
    DioExceptionType.cancel => const NetworkException('Запрос отменён.'),
    DioExceptionType.badResponse => mapHttpError(
      e.response?.statusCode ?? 500,
      e.response?.data,
    ),
    DioExceptionType.unknown => const NetworkException(
      'Не удалось выполнить запрос. Проверьте соединение.',
    ),
  };
}

/// Обёртка над сетевым вызовом.
/// Не выпускает наружу DioException — только ApiException.
Future<T> guard<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on DioException catch (e) {
    throw mapDioError(e);
  }
}
