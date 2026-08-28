class MenuItemEntity {
  final String id;
  final String name;
  final String category; // 'boisson', 'grillade', 'plat', 'accompagnement'
  final double price;
  final bool available;

  MenuItemEntity({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.available,
  });
}
