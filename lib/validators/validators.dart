class Validators {
  static String? required(String? value, [String fieldName = 'Поле']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName обязательно для заполнения';
    }
    return null;
  }

  static String? maxLength(String? value, int max, [String fieldName = 'Поле']) {
    if (value != null && value.trim().isNotEmpty && value.length > max) {
      return '$fieldName не может быть длиннее $max символов';
    }
    return null;
  }

  static String? minLength(String? value, int min, [String fieldName = 'Поле']) {
    if (value != null && value.trim().isNotEmpty && value.length < min) {
      return '$fieldName должно быть не короче $min символов';
    }
    return null;
  }

  static String? minMaxNumber(int? value, int min, int max, [String fieldName = 'Поле']) {
    if (value != null && (value < min || value > max)) {
      return '$fieldName должно быть от $min до $max';
    }
    return null;
  }

  static String? positiveNumber(String? value, [String fieldName = 'Количество']) {
    if (value == null || value.trim().isEmpty) return null;
    final num = int.tryParse(value);
    if (num == null || num <= 0) {
      return '$fieldName должно быть положительным числом';
    }
    return null;
  }

  static String? positiveDouble(String? value, [String fieldName = 'Значение']) {
    if (value == null || value.trim().isEmpty) return null;
    final num = double.tryParse(value);
    if (num == null || num <= 0) {
      return '$fieldName должно быть положительным числом';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Введите корректный email';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (!RegExp(r'^[\+\d\s\-\(\)]+$').hasMatch(value.trim())) {
      return 'Введите корректный номер телефона';
    }
    return null;
  }

  static String? unique<T>(
    String? value,
    List<T> items,
    String Function(T) getField,
    int? currentId,
    String fieldName,
  ) {
    if (value == null || value.trim().isEmpty) return null;
    final exists = items.any((item) {
      final id = (item as dynamic).id as int;
      return getField(item).toLowerCase() == value.trim().toLowerCase() &&
          (currentId == null || id != currentId);
    });
    if (exists) {
      return '$fieldName с таким значением уже существует';
    }
    return null;
  }
}
