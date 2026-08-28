import 'dart:convert';

import 'package:hive/hive.dart';

import '../models/dashboard_summary_model.dart';

/// Cache local du résumé du dashboard (JSON encodé dans une Box Hive),
/// utilisé comme repli quand l'API est injoignable (mode hors-ligne).
class DashboardLocalDataSource {
  final Box<String> box;
  static const key = 'dashboard';

  DashboardLocalDataSource({required this.box});

  bool get hasData => box.get(key) != null;

  DashboardSummaryModel? getSummary() {
    final raw = box.get(key);
    if (raw == null) return null;
    return DashboardSummaryModel.fromJson(
      Map<String, dynamic>.from(jsonDecode(raw) as Map),
    );
  }

  Future<void> saveSummary(DashboardSummaryModel summary) =>
      box.put(key, jsonEncode(summary.toJson()));

  Future<void> clear() => box.delete(key);
}
