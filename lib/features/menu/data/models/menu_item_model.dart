import 'package:hive/hive.dart';

import '../../domain/entities/menu_item.dart';

// Bug corrigé : la version précédente utilisait `@HiveType`/`@HiveField`
// avec `part 'menu_item_model.g.dart';`, mais ce fichier généré n'existe
// nulle part dans le projet (aucun `build_runner` n'avait jamais été
// exécuté) → la compilation échouait. On écrit l'adapter Hive à la main,
// ce qui évite toute dépendance à la génération de code.
class MenuItemModel extends HiveObject {
  final String id;
  final String name;
  final String category; // 'boisson', 'grillade', 'plat', 'accompagnement'
  final double price;
  final bool available;

  MenuItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.available,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      available: json['available'] as bool? ?? true,
    );
  }

  factory MenuItemModel.fromEntity(MenuItemEntity entity) => MenuItemModel(
        id: entity.id,
        name: entity.name,
        category: entity.category,
        price: entity.price,
        available: entity.available,
      );

  MenuItemEntity toEntity() {
    return MenuItemEntity(
      id: id,
      name: name,
      category: category,
      price: price,
      available: available,
    );
  }
}

/// TypeId Hive = 0 (unique dans toute l'application).
class MenuItemModelAdapter extends TypeAdapter<MenuItemModel> {
  @override
  final int typeId = 0;

  @override
  MenuItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MenuItemModel(
      id: fields[0] as String,
      name: fields[1] as String,
      category: fields[2] as String,
      price: fields[3] as double,
      available: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, MenuItemModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.price)
      ..writeByte(4)
      ..write(obj.available);
  }
}
