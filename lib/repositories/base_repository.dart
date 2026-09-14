import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class BaseRepository<T> {
  final SharedPreferences prefs;
  final String key;
  List<T> _items = [];

  bool dataWasReset = false;

  BaseRepository(this.prefs, this.key) {
    _restore();
  }

  List<T> get items => _items;

  T fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson(T item);
  List<T> seedData();
  T createCopyWithNewId(T item, int newId);

  /// Переопределяется в подклассах. Публичный — чтобы override
  /// работал из другого файла (методы с `_` приватны в пределах файла).
  T softDeleteItem(T item);
  T restoreItem(T item);

  void _restore() {
    final raw = prefs.getString(key);
    if (raw == null) {
      _items = seedData();
      _persist();
      dataWasReset = true;
      return;
    }
    try {
      final list = jsonDecode(raw) as List;
      _items = list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Ошибка восстановления данных: $e');
      _items = seedData();
      _persist();
      dataWasReset = true;
    }
  }

  Future<void> _persist() async {
    try {
      final jsonData = jsonEncode(_items.map((e) => toJson(e)).toList());
      await prefs.setString(key, jsonData);
    } catch (e) {
      debugPrint('Ошибка сохранения: $e');
    }
  }

  int _getNextId() {
    if (_items.isEmpty) return 1;
    int maxId = 0;
    for (var item in _items) {
      try {
        final id = (item as dynamic).id;
        if (id is int && id > maxId) {
          maxId = id;
        }
      } catch (_) {
        // ignore: empty_catches
      }
    }
    return maxId + 1;
  }

  Future<List<T>> findAll() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _items.where((e) => !(e as dynamic).isDeleted).toList();
  }

  Future<List<T>> findAllWithDeleted() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return List.from(_items);
  }

  Future<T?> findById(int id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      return _items.firstWhere((e) => (e as dynamic).id == id);
    } catch (_) {
      return null;
    }
  }

  Future<T> create(T item) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final newId = _getNextId();
    final newItem = createCopyWithNewId(item, newId);
    _items.add(newItem);
    await _persist();
    return newItem;
  }

  Future<T> update(T item) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final id = (item as dynamic).id as int;
    final index = _items.indexWhere((e) => (e as dynamic).id == id);
    if (index == -1) throw StateError('Объект с id $id не найден');
    _items[index] = item;
    await _persist();
    return item;
  }

  Future<void> softDelete(int id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final index = _items.indexWhere((e) => (e as dynamic).id == id);
    if (index == -1) throw StateError('Объект с id $id не найден');
    _items[index] = softDeleteItem(_items[index]);
    await _persist();
  }

  Future<void> hardDelete(int id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _items.removeWhere((e) => (e as dynamic).id == id);
    await _persist();
  }

  Future<void> restore(int id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final index = _items.indexWhere((e) => (e as dynamic).id == id);
    if (index == -1) throw StateError('Объект с id $id не найден');
    _items[index] = restoreItem(_items[index]);
    await _persist();
  }

  Future<int> deleteMany(List<int> ids) async {
    await Future.delayed(const Duration(milliseconds: 50));
    var count = 0;
    for (final id in ids) {
      final i = _items.indexWhere(
        (e) => (e as dynamic).id == id && !(e as dynamic).isDeleted,
      );
      if (i != -1) {
        _items[i] = softDeleteItem(_items[i]);
        count++;
      }
    }
    await _persist();
    return count;
  }
}
