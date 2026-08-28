import 'package:flutter/foundation.dart';

import '../../domain/entities/waitress.dart';
import '../../domain/repositories/staff_repository.dart';

class StaffController extends ChangeNotifier {
  final StaffRepository repository;

  StaffController({required this.repository});

  List<WaitressEntity> waitresses = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadWaitresses() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      waitresses = await repository.getWaitresses();
    } catch (_) {
      errorMessage = 'Impossible de charger les serveuses.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addWaitress(String name, String? phone) async {
    try {
      final created = await repository.createWaitress(name: name, phone: phone);
      waitresses = [...waitresses, created];
      notifyListeners();
      return true;
    } catch (_) {
      errorMessage = 'Impossible d\'ajouter la serveuse.';
      notifyListeners();
      return false;
    }
  }
}
