import 'package:dio/dio.dart';

import '../models/client.dart';
import '../state/client_query.dart';
import '../state/page_result.dart';

/// Интерфейс репозитория клиентов.
/// Реализация — ApiClientRepository (HTTP + Dio к PocketBase).
abstract class ClientRepository {
  Future<List<Client>> findAll({bool includeDeleted = false});
  Future<Client?> findById(String id);
  Future<PageResult<Client>> find(
    ClientQuery query, {
    CancelToken? cancelToken,
  });
  Future<Client> create(Client item);
  Future<Client> update(Client item);
  Future<void> softDelete(String id);
  Future<void> hardDelete(String id);
  Future<void> restore(String id);
  Future<int> deleteMany(List<String> ids);
}
