import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../models/waitress_model.dart';

class StaffRemoteDataSource {
  final Dio dio;
  StaffRemoteDataSource(this.dio);

  Future<List<WaitressModel>> getWaitresses() async {
    final d = (await dio.get(ApiConstants.staff)).data;
    final l = d is Map && d['data'] is List ? d['data'] as List : d as List;
    return l
        .whereType<Map>()
        .map((x) => WaitressModel.fromJson(Map<String, dynamic>.from(x)))
        .toList();
  }

  Future<WaitressModel> createWaitress({
    required String name,
    String? phone,
  }) async {
    final r = await dio.post(
      ApiConstants.staff,
      data: {'name': name, 'phone': phone},
    );
    return WaitressModel.fromJson(Map<String, dynamic>.from(r.data as Map));
  }

  Future<WaitressModel> updateWaitress({
    required String id,
    required String name,
    String? phone,
    required bool active,
  }) async {
    final r = await dio.patch(
      '${ApiConstants.staff}/$id',
      data: {'name': name, 'phone': phone, 'active': active},
    );
    return WaitressModel.fromJson(Map<String, dynamic>.from(r.data as Map));
  }
}
