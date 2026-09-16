import '../models/cargo.dart';
import 'base_repository.dart';
import 'cargo_repository.dart';

class PersistentCargoRepository extends BaseRepository<Cargo>
    implements CargoRepository {
  PersistentCargoRepository(super.prefs, super.key);

  @override
  String get key => 'cargo_v1';

  @override
  Cargo fromJson(Map<String, dynamic> json) => Cargo.fromJson(json);

  @override
  Map<String, dynamic> toJson(Cargo item) => item.toJson();

  @override
  List<Cargo> seedData() => [
    Cargo(
      id: 1,
      name: 'Строительные материалы',
      description: 'Кирпич, цемент, песок',
      weightPerUnit: 50.0,
      volumePerUnit: 0.1,
      orderIds: [1, 4],
    ),
    Cargo(
      id: 2,
      name: 'Электроника',
      description: 'Смартфоны, ноутбуки',
      weightPerUnit: 0.5,
      volumePerUnit: 0.01,
      orderIds: [2, 4],
    ),
    Cargo(
      id: 3,
      name: 'Мебель',
      description: 'Столы, стулья, шкафы',
      weightPerUnit: 25.0,
      volumePerUnit: 0.5,
      orderIds: [3, 5],
    ),
  ];

  @override
  Cargo createCopyWithNewId(Cargo item, int newId) {
    return Cargo(
      id: newId,
      name: item.name,
      description: item.description,
      weightPerUnit: item.weightPerUnit,
      volumePerUnit: item.volumePerUnit,
      orderIds: [],
    );
  }

  @override
  Cargo softDeleteItem(Cargo item) {
    return item.copyWith(deletedAt: DateTime.now());
  }

  @override
  Cargo restoreItem(Cargo item) {
    return item.copyWith(clearDeletedAt: true);
  }

  @override
  Future<List<Cargo>> findAll({bool includeDeleted = false}) async {
    await Future.delayed(const Duration(milliseconds: 50));
    if (includeDeleted) return List.from(items);
    return items.where((c) => !c.isDeleted).toList();
  }
}
