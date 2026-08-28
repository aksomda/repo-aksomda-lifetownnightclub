class WaitressEntity {
  final String id;
  final String name;
  final String? phone;
  final bool active;

  const WaitressEntity({
    required this.id,
    required this.name,
    this.phone,
    required this.active,
  });
}
