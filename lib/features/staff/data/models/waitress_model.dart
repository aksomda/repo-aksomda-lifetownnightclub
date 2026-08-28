import '../../domain/entities/waitress.dart';

class WaitressModel extends WaitressEntity {
  const WaitressModel({
    required super.id,
    required super.name,
    super.phone,
    required super.active,
  });

  factory WaitressModel.fromJson(Map<String, dynamic> j) => WaitressModel(
    id: '${j['id'] ?? ''}',
    name: '${j['name'] ?? ''}',
    phone: j['phone']?.toString(),
    active: j['active'] is bool ? j['active'] as bool : true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'active': active,
  };
}
