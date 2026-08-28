import '../../domain/entities/dashboard_summary.dart';

class DashboardSummaryModel extends DashboardSummary {
  const DashboardSummaryModel({
    required super.products,
    required super.orders,
    required super.lowStocks,
    required super.staff,
    required super.revenue,
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> j) =>
      DashboardSummaryModel(
        products: (j['products'] as num?)?.toInt() ?? 0,
        orders: (j['orders'] as num?)?.toInt() ?? 0,
        lowStocks: (j['low_stocks'] as num?)?.toInt() ?? 0,
        staff: (j['staff'] as num?)?.toInt() ?? 0,
        revenue: (j['revenue'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {
    'products': products,
    'orders': orders,
    'low_stocks': lowStocks,
    'staff': staff,
    'revenue': revenue,
  };
}
