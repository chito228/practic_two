import 'package:flutter_test/flutter_test.dart';
import 'package:project_two/validators/validators.dart';

void main() {
  group('Валидатор обязательного поля', () {
    test('пустая строка отклоняется', () {
      expect(Validators.required(''), isNotNull);
      expect(Validators.required('   '), isNotNull);
    });

    test('непустая строка принимается', () {
      expect(Validators.required('Война и мир'), isNull);
    });
  });

  group('Валидатор длины', () {
    test('maxLength отклоняет слишком длинную строку', () {
      expect(Validators.maxLength('abcdef', 3), isNotNull);
    });

    test('maxLength принимает строку в пределах лимита', () {
      expect(Validators.maxLength('ab', 3), isNull);
    });

    test('minLength отклоняет слишком короткую строку', () {
      expect(Validators.minLength('ab', 3), isNotNull);
    });

    test('minLength принимает строку достаточной длины', () {
      expect(Validators.minLength('abc', 3), isNull);
    });
  });

  group('Валидатор чисел', () {
    test('positiveNumber отклоняет ноль', () {
      expect(Validators.positiveNumber('0'), isNotNull);
    });

    test('positiveNumber отклоняет отрицательные', () {
      expect(Validators.positiveNumber('-5'), isNotNull);
    });

    test('positiveNumber принимает положительное', () {
      expect(Validators.positiveNumber('10'), isNull);
    });

    test('positiveDouble отклоняет нечисло', () {
      expect(Validators.positiveDouble('abc'), isNotNull);
    });

    test('positiveDouble принимает положительное', () {
      expect(Validators.positiveDouble('1.5'), isNull);
    });
  });

  group('Валидатор email', () {
    test('корректный email принимается', () {
      expect(Validators.email('user@example.com'), isNull);
    });

    test('некорректный email отклоняется', () {
      expect(Validators.email('not-an-email'), isNotNull);
    });

    test('пустой email принимается (необязательное поле)', () {
      expect(Validators.email(''), isNull);
    });
  });

  group('Валидатор телефона', () {
    test('корректный телефон принимается', () {
      expect(Validators.phone('+7-999-111-22-33'), isNull);
    });

    test('телефон с буквами отклоняется', () {
      expect(Validators.phone('+7-abc'), isNotNull);
    });
  });
}
