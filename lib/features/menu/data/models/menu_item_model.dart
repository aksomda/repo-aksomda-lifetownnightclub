import '../../domain/entities/menu_item.dart';

class MenuItemModel extends MenuItemEntity {
  const MenuItemModel({
    required super.id,
    required super.name,
    required super.category,
    required super.price,
    required super.available,
  });
  factory MenuItemModel.fromJson(Map<String, dynamic> j) => MenuItemModel(
    id: '${j['id'] ?? ''}',
    name: '${j['name'] ?? ''}',
    category: '${j['category'] ?? 'boisson'}',
    price: (j['price'] as num?)?.toDouble() ?? 0,
    available: j['available'] is bool ? j['available'] as bool : true,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'price': price,
    'available': available,
  };
}
