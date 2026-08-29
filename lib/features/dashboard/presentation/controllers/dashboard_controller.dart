import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/usecases/get_dashboard.dart';

/// Gère l'état de chargement de la fonctionnalité Dashboard.
class DashboardController extends ChangeNotifier {
  final GetDashboard get;

  DashboardController(this.get);

  DashboardSummary? data;
  bool loading = false;
  String? error;

  /// Charge les données depuis le repository.
  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      data = await get();
    } catch (exception) {
      error = messageFrom(exception);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  String messageFrom(Object exception) {
    if (exception is AppException) return exception.message;
    return 'Une erreur inattendue est survenue. Veuillez réessayer.';
  }
}
