import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../repositories/client_repository.dart';
import '../models/client.dart';
import 'load_status.dart';
import 'page_result.dart';
import 'client_query.dart';

class ClientListNotifier extends ChangeNotifier {
  final ClientRepository _repository;

  ClientListNotifier(this._repository);

  ClientQuery _query = const ClientQuery();
  PageResult<Client> _result = PageResult.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<int> _selected = {};

  /// Токен текущего поискового запроса.
  /// При новом запросе отменяем предыдущий, чтобы ответы
  /// не приходили в неправильном порядке.
  CancelToken? _cancelToken;

  ClientQuery get query => _query;
  PageResult<Client> get result => _result;
  LoadStatus get status => _status;
  String? get error => _error;
  Set<int> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;

  Future<void> load() async {
    // Отменяем предыдущий запрос, если он ещё не завершился.
    _cancelToken?.cancel('Новый поисковый запрос');
    _cancelToken = CancelToken();

    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();

    try {
      _result = await _repository.find(_query, cancelToken: _cancelToken);
      _status = LoadStatus.success;
    } on DioException catch (e) {
      // Отменённый запрос — не ошибка: просто игнорируем результат.
      // Новый запрос уже в пути.
      if (CancelToken.isCancel(e)) return;
      _error = 'Не удалось загрузить список клиентов: $e';
      _status = LoadStatus.error;
    } catch (e) {
      _error = 'Не удалось загрузить список клиентов: $e';
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> applyQuery(ClientQuery next) async {
    _query = next;
    _selected.clear();
    await load();
  }

  void toggleSelection(int id) {
    if (_selected.contains(id)) {
      _selected.remove(id);
    } else {
      _selected.add(id);
    }
    notifyListeners();
  }

  Future<void> deleteSelected() async {
    await _repository.deleteMany(_selected.toList());
    _selected.clear();
    await load();
  }

  @override
  void dispose() {
    // Отменяем запрос, если нотифаер уничтожается.
    _cancelToken?.cancel('Нотифаер уничтожен');
    super.dispose();
  }
}
