class DashboardChartModel {
  final List<HourlyStat> hourlyStats;
  final List<PaymentStat> paymentStats;
  final List<WeeklyStat> weeklyStats;

  DashboardChartModel({
    required this.hourlyStats,
    required this.paymentStats,
    required this.weeklyStats,
  });

  factory DashboardChartModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return DashboardChartModel(
      hourlyStats:
          (data['hourly_stats'] as List)
              .map((e) => HourlyStat.fromJson(e))
              .toList(),
      paymentStats:
          (data['payment_stats'] as List)
              .map((e) => PaymentStat.fromJson(e))
              .toList(),
      weeklyStats:
          (data['weekly_stats'] as List)
              .map((e) => WeeklyStat.fromJson(e))
              .toList(),
    );
  }
}

class HourlyStat {
  final String hourLabel;
  final double totalSalesVolume;
  final double salesCashFlow;
  final double collectionCashFlow;
  final double hourlyCash;
  final double hourlyCard;

  HourlyStat({
    required this.hourLabel,
    required this.totalSalesVolume,
    required this.salesCashFlow,
    required this.collectionCashFlow,
    required this.hourlyCash,
    required this.hourlyCard,
  });

  factory HourlyStat.fromJson(Map<String, dynamic> json) {
    return HourlyStat(
      hourLabel: json['hour_label'] ?? "00:00",
      // 🔥 GÜVENLİ PARSE İŞLEMİ (Çökme Önleyici)
      totalSalesVolume: _safeDouble(json['total_sales_volume']),
      salesCashFlow: _safeDouble(json['sales_cash_flow']),
      collectionCashFlow: _safeDouble(json['collection_cash_flow']),
      hourlyCash: _safeDouble(json['hourly_cash']),
      hourlyCard: _safeDouble(json['hourly_card']),
    );
  }
}

class PaymentStat {
  final String paymentMethod;
  final double totalAmount;

  PaymentStat({required this.paymentMethod, required this.totalAmount});

  factory PaymentStat.fromJson(Map<String, dynamic> json) {
    return PaymentStat(
      paymentMethod: json['payment_method'] ?? 'Bilinmeyen',
      totalAmount: _safeDouble(json['total_amount']),
    );
  }
}

class WeeklyStat {
  final String dayName;
  final String shortDate;
  final double totalSales; // 🔵
  final double salesCash; // 🟢
  final double collectionCash; // 🟠

  WeeklyStat({
    required this.dayName,
    required this.shortDate,
    required this.totalSales,
    required this.salesCash,
    required this.collectionCash,
  });

  factory WeeklyStat.fromJson(Map<String, dynamic> json) {
    return WeeklyStat(
      dayName: (json['day_name'] ?? "").toString().trim(),
      shortDate: json['short_date'] ?? "",
      totalSales: _safeDouble(json['total_sales']),
      salesCash: _safeDouble(json['sales_cash']),
      collectionCash: _safeDouble(json['collection_cash']),
    );
  }
}

// 👇 İŞTE BU FONKSİYON KURTARICI!
// Dosyanın en altında, sınıfların dışında duracak.
double _safeDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    return double.tryParse(value) ?? 0.0;
  }
  return 0.0;
}
