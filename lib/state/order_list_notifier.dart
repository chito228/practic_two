import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../repositories/order_repository.dart';
import '../models/order.dart';
import 'load_status.dart';
import 'page_result.dart';
import 'order_query.dart';

class OrderListNotifier extends ChangeNotifier {
  final OrderRepository _repository;

  OrderListNotifier(this._repository);

  OrderQuery _query = const OrderQuery();
  PageResult<Order> _result = PageResult.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<int> _selected = {};

  /// Токен текущего поискового запроса.
  CancelToken? _cancelToken;

  OrderQuery get query => _query;
  PageResult<Order> get result => _result;
  LoadStatus get status => _status;
  String? get error => _error;
  Set<int> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;

  Future<void> load() async {
    _cancelToken?.cancel('Новый поисковый запрос');
    _cancelToken = CancelToken();

    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();

    try {
      _result = await _repository.find(_query, cancelToken: _cancelToken);
      _status = LoadStatus.success;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
      _error = 'Не удалось загрузить список заказов: $e';
      _status = LoadStatus.error;
    } catch (e) {
      _error = 'Не удалось загрузить список заказов: $e';
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> applyQuery(OrderQuery next) async {
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
