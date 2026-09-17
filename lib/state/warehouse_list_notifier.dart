import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../repositories/warehouse_repository.dart';
import '../models/warehouse.dart';
import 'load_status.dart';
import 'page_result.dart';
import 'warehouse_query.dart';

class WarehouseListNotifier extends ChangeNotifier {
  final WarehouseRepository _repository;

  WarehouseListNotifier(this._repository);

  WarehouseQuery _query = const WarehouseQuery();
  PageResult<Warehouse> _result = PageResult.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<int> _selected = {};
  CancelToken? _cancelToken;

  WarehouseQuery get query => _query;
  PageResult<Warehouse> get result => _result;
  LoadStatus get status => _status;
  String? get error => _error;
  Set<int> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;

  Future<void> load() async {
    _cancelToken?.cancel('Новый запрос');
    _cancelToken = CancelToken();

    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();

    try {
      _result = await _repository.find(_query, cancelToken: _cancelToken);
      _status = LoadStatus.success;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
      _error = 'Не удалось загрузить список складов: $e';
      _status = LoadStatus.error;
    } catch (e) {
      _error = 'Не удалось загрузить список складов: $e';
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> applyQuery(WarehouseQuery next) async {
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
    _cancelToken?.cancel('Нотифаер уничтожен');
    super.dispose();
  }
}
