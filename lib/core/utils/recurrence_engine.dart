class RepeatRule {
  final String
  frequency; // 'daily', 'weekly', 'monthly', 'yearly', 'after_completion'
  final int interval; // e.g. 1, 2, 3
  final List<int> daysOfWeek; // 1 = Monday .. 7 = Sunday
  final int? afterCompletionDays;

  const RepeatRule({
    required this.frequency,
    this.interval = 1,
    this.daysOfWeek = const [],
    this.afterCompletionDays,
  });

  Map<String, dynamic> toMap() {
    return {
      'frequency': frequency,
      'interval': interval,
      'daysOfWeek': daysOfWeek,
      if (afterCompletionDays != null)
        'afterCompletionDays': afterCompletionDays,
    };
  }

  factory RepeatRule.fromMap(Map<String, dynamic> map) {
    return RepeatRule(
      frequency: map['frequency'] as String? ?? 'daily',
      interval: (map['interval'] as num?)?.toInt() ?? 1,
      daysOfWeek:
          (map['daysOfWeek'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      afterCompletionDays: (map['afterCompletionDays'] as num?)?.toInt(),
    );
  }
}

class RecurrenceEngine {
  /// Computes the next occurrence given a current due date (or completion date) and a [RepeatRule].
  static DateTime? computeNextDueDate({
    required DateTime currentDueDate,
    required RepeatRule rule,
    DateTime? completionDate,
  }) {
    final interval = rule.interval <= 0 ? 1 : rule.interval;

    switch (rule.frequency) {
      case 'after_completion':
        final base = completionDate ?? DateTime.now();
        final days = rule.afterCompletionDays ?? interval;
        return DateTime(
          base.year,
          base.month,
          base.day + days,
          currentDueDate.hour,
          currentDueDate.minute,
        );

      case 'daily':
        return DateTime(
          currentDueDate.year,
          currentDueDate.month,
          currentDueDate.day + interval,
          currentDueDate.hour,
          currentDueDate.minute,
        );

      case 'weekly':
        if (rule.daysOfWeek.isNotEmpty) {
          // Find next day in the specified days of week
          final sortedDays = List<int>.from(rule.daysOfWeek)..sort();
          for (final day in sortedDays) {
            if (day > currentDueDate.weekday) {
              final diff = day - currentDueDate.weekday;
              return DateTime(
                currentDueDate.year,
                currentDueDate.month,
                currentDueDate.day + diff,
                currentDueDate.hour,
                currentDueDate.minute,
              );
            }
          }
          // Wrap around to the first day of next interval week
          final firstDay = sortedDays.first;
          final daysToFirst =
              (7 - currentDueDate.weekday) + firstDay + (interval - 1) * 7;
          return DateTime(
            currentDueDate.year,
            currentDueDate.month,
            currentDueDate.day + daysToFirst,
            currentDueDate.hour,
            currentDueDate.minute,
          );
        } else {
          return DateTime(
            currentDueDate.year,
            currentDueDate.month,
            currentDueDate.day + (interval * 7),
            currentDueDate.hour,
            currentDueDate.minute,
          );
        }

      case 'monthly':
        final newMonth = currentDueDate.month + interval;
        final yearOffset = (newMonth - 1) ~/ 12;
        final normalizedMonth = ((newMonth - 1) % 12) + 1;
        final newYear = currentDueDate.year + yearOffset;
        final daysInTargetMonth = DateTime(newYear, normalizedMonth + 1, 0).day;
        final targetDay = currentDueDate.day > daysInTargetMonth
            ? daysInTargetMonth
            : currentDueDate.day;

        return DateTime(
          newYear,
          normalizedMonth,
          targetDay,
          currentDueDate.hour,
          currentDueDate.minute,
        );

      case 'yearly':
        final newYear = currentDueDate.year + interval;
        final daysInTargetMonth = DateTime(
          newYear,
          currentDueDate.month + 1,
          0,
        ).day;
        final targetDay = currentDueDate.day > daysInTargetMonth
            ? daysInTargetMonth
            : currentDueDate.day;

        return DateTime(
          newYear,
          currentDueDate.month,
          targetDay,
          currentDueDate.hour,
          currentDueDate.minute,
        );

      default:
        return null;
    }
  }
}
