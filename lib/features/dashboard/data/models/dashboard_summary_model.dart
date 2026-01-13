class DashboardSummaryModel {
  final Turnover turnover;
  final DebtGiven debtGiven;
  final Inventory inventory;
  final Financial financial;
  final Appointments appointments;

  DashboardSummaryModel({
    required this.turnover,
    required this.debtGiven,
    required this.inventory,
    required this.financial,
    required this.appointments,
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    final data = json['data']; // Backend 'data' key'i içinde gönderiyor
    return DashboardSummaryModel(
      turnover: Turnover.fromJson(data['turnover']),
      debtGiven: DebtGiven.fromJson(data['debt_given']),
      inventory: Inventory.fromJson(data['inventory']),
      financial: Financial.fromJson(data['financial']),
      appointments: Appointments.fromJson(data['appointments']),
    );
  }
}

class Turnover {
  final double totalTurnover;
  final double totalCash;
  final double totalCard;

  Turnover({
    required this.totalTurnover,
    required this.totalCash,
    required this.totalCard,
  });

  factory Turnover.fromJson(Map<String, dynamic> json) {
    return Turnover(
      totalTurnover: double.parse(json['total_turnover'].toString()),
      totalCash: double.parse(json['total_cash'].toString()),
      totalCard: double.parse(json['total_card'].toString()),
    );
  }
}

class DebtGiven {
  final double totalDebtGiven;
  final int count;

  DebtGiven({required this.totalDebtGiven, required this.count});

  factory DebtGiven.fromJson(Map<String, dynamic> json) {
    return DebtGiven(
      totalDebtGiven: double.parse(json['total_debt_given'].toString()),
      count: int.parse(json['debt_transaction_count'].toString()),
    );
  }
}

class Inventory {
  final int criticalCount;

  Inventory({required this.criticalCount});

  factory Inventory.fromJson(Map<String, dynamic> json) {
    return Inventory(
      criticalCount: int.parse(json['critical_count'].toString()),
    );
  }
}

class Financial {
  final double inflationGain;
  final double totalReceivable;

  Financial({required this.inflationGain, required this.totalReceivable});

  factory Financial.fromJson(Map<String, dynamic> json) {
    return Financial(
      inflationGain: double.parse(json['inflation_gain'].toString()),
      totalReceivable: double.parse(json['total_receivable'].toString()),
    );
  }
}

class Appointments {
  final int todayCount;

  Appointments({required this.todayCount});

  factory Appointments.fromJson(Map<String, dynamic> json) {
    return Appointments(todayCount: int.parse(json['today_count'].toString()));
  }
}
