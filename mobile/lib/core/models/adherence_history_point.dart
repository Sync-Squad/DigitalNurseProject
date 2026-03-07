class AdherenceHistoryPoint {
  final DateTime date;
  final int takenCount;
  final int missedCount;
  final int pendingCount;

  const AdherenceHistoryPoint({
    required this.date,
    required this.takenCount,
    required this.missedCount,
    required this.pendingCount,
  });

  int get totalScheduled => takenCount + missedCount + pendingCount;

  double get adherencePercentage {
    final total = totalScheduled;
    if (total == 0) {
      return 100;
    }
    return (takenCount / total) * 100;
  }

  AdherenceHistoryPoint copyWith({
    DateTime? date,
    int? takenCount,
    int? missedCount,
    int? pendingCount,
  }) {
    return AdherenceHistoryPoint(
      date: date ?? this.date,
      takenCount: takenCount ?? this.takenCount,
      missedCount: missedCount ?? this.missedCount,
      pendingCount: pendingCount ?? this.pendingCount,
    );
  }
}
