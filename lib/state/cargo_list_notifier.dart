import 'package:flutter/material.dart';
import '../repositories/persistent_cargo_repository.dart';
import '../models/cargo.dart';
import 'load_status.dart';
import 'page_result.dart';

class CargoListNotifier extends ChangeNotifier {
  final PersistentCargoRepository _repository;
  CargoListNotifier(this._repository);

  List<Cargo> _items = [];
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<int> _selected = {};

  List<Cargo> get items => _items;
  LoadStatus get status => _status;
  String? get error => _error;
  Set<int> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _items = await _repository.findAll();
      _status = LoadStatus.success;
    } catch (e) {
      _error = 'Не удалось загрузить список грузов: $e';
      _status = LoadStatus.error;
    }
    notifyListeners();
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
}
