class TableEntity {
  final String id;
  final int number;
  final String status;

  const TableEntity({
    required this.id,
    required this.number,
    required this.status,
  });

  bool get isAvailable => status == 'available';
}
