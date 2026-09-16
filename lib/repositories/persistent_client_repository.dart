import 'package:dio/dio.dart';

import '../models/client.dart';
import 'base_repository.dart';
import 'client_repository.dart';
import '../state/client_query.dart';
import '../state/page_result.dart';

class PersistentClientRepository extends BaseRepository<Client>
    implements ClientRepository {
  PersistentClientRepository(super.prefs, super.key);

  @override
  String get key => 'clients_v1';

  @override
  Client fromJson(Map<String, dynamic> json) {
    return Client.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(Client item) {
    return item.toJson();
  }

  @override
  List<Client> seedData() => [
    Client(
      id: 1,
      companyName: 'ООО Логист Транс',
      contactPerson: 'Иван Иванов',
      phone: '+7-999-111-22-33',
      email: 'info@logist.ru',
      address: 'г. Москва, ул. Ленина, 1',
      orderIds: [1, 2],
    ),
    Client(
      id: 2,
      companyName: 'ИП Петров',
      contactPerson: 'Петр Петров',
      phone: '+7-999-222-33-44',
      email: 'petrov@mail.ru',
      address: 'г. Санкт-Петербург, Невский пр., 10',
      orderIds: [3],
    ),
    Client(
      id: 3,
      companyName: 'ООО Грузовик',
      contactPerson: 'Сидор Сидоров',
      phone: '+7-999-333-44-55',
      email: 'gruzovik@yandex.ru',
      address: 'г. Казань, ул. Баумана, 5',
      orderIds: [4, 5],
    ),
    Client(
      id: 4,
      companyName: 'ИП Смирнов',
      contactPerson: 'Алексей Смирнов',
      phone: '+7-999-444-55-66',
      email: 'smirnov@mail.ru',
      address: null,
      orderIds: [],
    ),
  ];

  @override
  Client createCopyWithNewId(Client item, int newId) {
    return Client(
      id: newId,
      companyName: item.companyName,
      contactPerson: item.contactPerson,
      phone: item.phone,
      email: item.email,
      address: null,
      orderIds: [],
    );
  }

  @override
  Client softDeleteItem(Client item) {
    return item.copyWith(deletedAt: DateTime.now());
  }

  @override
  Client restoreItem(Client item) {
    return item.copyWith(clearDeletedAt: true);
  }

  @override
  Future<List<Client>> findAll({bool includeDeleted = false}) async {
    await Future.delayed(const Duration(milliseconds: 50));
    if (includeDeleted) return List.from(items);
    return items.where((c) => !c.isDeleted).toList();
  }

  @override
  Future<PageResult<Client>> find(
    ClientQuery query, {
    CancelToken? cancelToken,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));

    var rows = items
        .where((c) => query.includeDeleted || !c.isDeleted)
        .toList();

    if (query.search.trim().isNotEmpty) {
      final needle = query.search.trim().toLowerCase();
      rows = rows
          .where(
            (c) =>
                c.companyName.toLowerCase().contains(needle) ||
                c.contactPerson.toLowerCase().contains(needle) ||
                c.email.toLowerCase().contains(needle),
          )
          .toList();
    }

    rows.sort((a, b) {
      int result;
      switch (query.sortField) {
        case 'companyName':
          result = a.companyName.compareTo(b.companyName);
          break;
        case 'contactPerson':
          result = a.contactPerson.compareTo(b.contactPerson);
          break;
        default:
          result = a.companyName.compareTo(b.companyName);
      }
      return query.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (query.page - 1) * query.size;
    final to = (from + query.size) > total ? total : (from + query.size);
    final pageItems = from >= total ? <Client>[] : rows.sublist(from, to);

    return PageResult(
      items: pageItems,
      page: query.page,
      size: query.size,
      total: total,
    );
  }
}
