import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../repositories/route_repository.dart';
import '../models/route.dart' as model;
import 'load_status.dart';
import 'page_result.dart';
import 'route_query.dart';

class RouteListNotifier extends ChangeNotifier {
  final RouteRepository _repository;

  RouteListNotifier(this._repository);

  RouteQuery _query = const RouteQuery();
  PageResult<model.Route> _result = PageResult.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<String> _selected = {};
  CancelToken? _cancelToken;

  RouteQuery get query => _query;
  PageResult<model.Route> get result => _result;
  LoadStatus get status => _status;
  String? get error => _error;
  Set<String> get selected => Set.unmodifiable(_selected);
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
      _error = 'Не удалось загрузить список маршрутов: $e';
      _status = LoadStatus.error;
    } catch (e) {
      _error = 'Не удалось загрузить список маршрутов: $e';
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> applyQuery(RouteQuery next) async {
    _query = next;
    _selected.clear();
    await load();
  }

  void toggleSelection(String id) {
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
