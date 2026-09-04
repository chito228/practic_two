import '../models/client.dart';
import '../state/client_query.dart';
import '../state/page_result.dart';
import 'client_repository.dart';

class InMemoryClientRepository implements ClientRepository {
  final List<Client> _clients = [
    Client(
      id: 1,
      name: 'ООО Логист Транс',
      contactPerson: 'Иван Иванов',
      phone: '+7-999-111-22-33',
      orderIds: [1, 2, 5],
    ),
    Client(
      id: 2,
      name: 'ИП Петров',
      contactPerson: 'Петр Петров',
      phone: '+7-999-222-33-44',
      orderIds: [3, 7],
    ),
    Client(
      id: 3,
      name: 'ООО Грузовик',
      contactPerson: 'Сидор Сидоров',
      phone: '+7-999-333-44-55',
      orderIds: [4, 8, 10, 12],
    ),
    Client(
      id: 4,
      name: 'ИП Смирнов',
      contactPerson: 'Алексей Смирнов',
      phone: '+7-999-444-55-66',
      orderIds: [6, 9],
    ),
    Client(
      id: 5,
      name: 'ООО ТрансЛогистик',
      contactPerson: 'Дмитрий Дмитриев',
      phone: '+7-999-555-66-77',
      orderIds: [11, 15, 18],
    ),
    Client(
      id: 6,
      name: 'ИП Козлов',
      contactPerson: 'Сергей Козлов',
      phone: '+7-999-666-77-88',
      orderIds: [13, 16],
    ),
    Client(
      id: 7,
      name: 'ООО СкладСервис',
      contactPerson: 'Андрей Андреев',
      phone: '+7-999-777-88-99',
      orderIds: [14, 17, 19, 20],
    ),
    Client(
      id: 8,
      name: 'ИП Новиков',
      contactPerson: 'Николай Новиков',
      phone: '+7-999-888-99-00',
      orderIds: [],
    ),
  ];

  int _nextId = 9;

  @override
  Future<PageResult<Client>> find(ClientQuery q) async {
    await Future.delayed(const Duration(milliseconds: 250));

    var rows = _clients.where((c) => q.includeDeleted || !c.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows.where((c) =>
        c.name.toLowerCase().contains(needle) ||
        c.contactPerson.toLowerCase().contains(needle)
      ).toList();
    }

    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'name' => a.name.compareTo(b.name),
        'contactPerson' => a.contactPerson.compareTo(b.contactPerson),
        _ => a.name.compareTo(b.name),
      };
      return q.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Client>[] : rows.sublist(from, to);

    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Client?> findById(int id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      return _clients.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Client>> findAll() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _clients.where((c) => !c.isDeleted).toList();
  }

  @override
  Future<Client> create(Client client) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final newClient = Client(
      id: _nextId++,
      name: client.name,
      contactPerson: client.contactPerson,
      phone: client.phone,
      orderIds: client.orderIds,
    );
    _clients.add(newClient);
    return newClient;
  }

  @override
  Future<Client> update(Client client) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final i = _clients.indexWhere((c) => c.id == client.id);
    if (i == -1) throw StateError('Клиент ${client.id} не найден');
    _clients[i] = client;
    return client;
  }

  @override
  Future<void> softDelete(int id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final i = _clients.indexWhere((c) => c.id == id);
    if (i == -1) throw StateError('Клиент $id не найден');
    _clients[i] = _clients[i].copyWith(deletedAt: DateTime.now());
  }

  @override
  Future<void> hardDelete(int id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _clients.removeWhere((c) => c.id == id);
  }

  @override
  Future<void> restore(int id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final i = _clients.indexWhere((c) => c.id == id);
    if (i == -1) throw StateError('Клиент $id не найден');
    _clients[i] = _clients[i].copyWith(clearDeletedAt: true);
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    await Future.delayed(const Duration(milliseconds: 50));
    var count = 0;
    for (final id in ids) {
      final i = _clients.indexWhere((c) => c.id == id && !c.isDeleted);
      if (i != -1) {
        _clients[i] = _clients[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    return count;
  }
}
