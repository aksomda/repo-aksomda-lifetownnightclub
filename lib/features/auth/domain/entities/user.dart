class User {
  final String id;
  final String name;
  final String prename;
  final int age;
  final String email;
  final String telephone;
  final String? role;

  const User({
    required this.id,
    required this.name,
    required this.prename,
    required this.age,
    required this.email,
    required this.telephone,
    this.role,
  });
}
