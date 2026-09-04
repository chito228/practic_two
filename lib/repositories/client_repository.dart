import '../models/client.dart';
import '../state/client_query.dart';
import '../state/page_result.dart';

abstract interface class ClientRepository {
  Future<PageResult<Client>> find(ClientQuery query);
  Future<Client?> findById(int id);
  Future<List<Client>> findAll();
  Future<Client> create(Client client);
  Future<Client> update(Client client);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
}
