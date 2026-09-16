import 'package:flutter_test/flutter_test.dart';
import 'package:project_two/models/client.dart';
import 'package:project_two/models/order.dart';
import 'package:project_two/models/role.dart';

void main() {
  group('Разбор модели Client', () {
    test('отсутствующие поля не приводят к исключению', () {
      final client = Client.fromJson({'id': 1});
      expect(client.companyName, '');
      expect(client.contactPerson, '');
      expect(client.orderIds, isEmpty);
      expect(client.address, isNull);
    });

    test('полный JSON разбирается корректно', () {
      final client = Client.fromJson({
        'id': 5,
        'companyName': 'ООО Тест',
        'contactPerson': 'Иван',
        'phone': '+7-999-000-00-00',
        'email': 'test@test.ru',
        'address': 'Москва',
        'orderIds': [1, 2, 3],
      });
      expect(client.id, 5);
      expect(client.companyName, 'ООО Тест');
      expect(client.orderIds, [1, 2, 3]);
    });
  });

  group('Разбор модели Order', () {
    test('отсутствующие поля не приводят к исключению', () {
      final order = Order.fromJson({'id': 1});
      expect(order.orderNumber, '');
      expect(order.cargoIds, isEmpty);
      expect(order.status, 'in_transit');
    });
  });

  group('Разграничение прав Role', () {
    test('admin имеет уровень выше logist', () {
      expect(Role.admin.level > Role.logist.level, isTrue);
    });

    test('logist имеет уровень выше manager', () {
      expect(Role.logist.level > Role.manager.level, isTrue);
    });

    test('fromString корректно разбирает роли', () {
      expect(Role.fromString('admin'), Role.admin);
      expect(Role.fromString('logist'), Role.logist);
      expect(Role.fromString('manager'), Role.manager);
    });

    test('неизвестная роль трактуется как manager', () {
      expect(Role.fromString('unknown'), Role.manager);
      expect(Role.fromString(null), Role.manager);
    });

    test('toJson возвращает имя роли', () {
      expect(Role.admin.toJson(), 'admin');
      expect(Role.logist.toJson(), 'logist');
    });
  });
}
