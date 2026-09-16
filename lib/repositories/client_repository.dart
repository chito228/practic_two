import 'package:dio/dio.dart';

import '../models/client.dart';
import '../state/client_query.dart';
import '../state/page_result.dart';

/// Интерфейс репозитория клиентов.
/// Реализации: PersistentClientRepository (localStorage)
/// и ApiClientRepository (HTTP + Dio).
abstract class ClientRepository {
  Future<List<Client>> findAll({bool includeDeleted = false});
  Future<Client?> findById(int id);
  Future<PageResult<Client>> find(
    ClientQuery query, {
    CancelToken? cancelToken,
  });
  Future<Client> create(Client item);
  Future<Client> update(Client item);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
}
