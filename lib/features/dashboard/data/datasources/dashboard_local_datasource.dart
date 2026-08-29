import 'dart:convert';

import 'package:hive/hive.dart';

import '../models/dashboard_summary_model.dart';

/// Persiste le résumé du tableau de bord sous forme JSON dans Hive.
class DashboardLocalDataSource {
  final Box<String> box;
  static const key = 'dashboard';

  DashboardLocalDataSource({required this.box});

  bool get hasData => getSummary() != null;

  /// Retourne le résumé en cache ou null si le cache est absent/invalide.
  DashboardSummaryModel? getSummary() {
    final raw = box.get(key);
    if (raw == null) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return DashboardSummaryModel.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  Future<void> saveSummary(DashboardSummaryModel summary) =>
      box.put(key, jsonEncode(summary.toJson()));

  Future<void> clear() => box.delete(key);
}
