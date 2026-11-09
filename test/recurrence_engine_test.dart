import 'package:flutter_test/flutter_test.dart';
import 'package:noteon/core/utils/recurrence_engine.dart';

void main() {
  group('RecurrenceEngine Tests', () {
    test('Daily recurrence computes next day', () {
      final currentDue = DateTime(2026, 11, 10, 14, 30);
      const rule = RepeatRule(frequency: 'daily', interval: 1);

      final next = RecurrenceEngine.computeNextDueDate(
        currentDueDate: currentDue,
        rule: rule,
      );

      expect(next, equals(DateTime(2026, 11, 11, 14, 30)));
    });

    test('Daily recurrence with interval (every 3 days)', () {
      final currentDue = DateTime(2026, 11, 10, 9, 0);
      const rule = RepeatRule(frequency: 'daily', interval: 3);

      final next = RecurrenceEngine.computeNextDueDate(
        currentDueDate: currentDue,
        rule: rule,
      );

      expect(next, equals(DateTime(2026, 11, 13, 9, 0)));
    });

    test('Weekly recurrence with specific days of week (Mon & Thu)', () {
      // 2026-11-09 is a Monday (weekday 1)
      final currentDue = DateTime(2026, 11, 9, 10, 0);
      const rule = RepeatRule(
        frequency: 'weekly',
        daysOfWeek: [DateTime.monday, DateTime.thursday],
      );

      // Next after Monday should be Thursday (2026-11-12)
      final next = RecurrenceEngine.computeNextDueDate(
        currentDueDate: currentDue,
        rule: rule,
      );
      expect(next?.weekday, equals(DateTime.thursday));
      expect(next, equals(DateTime(2026, 11, 12, 10, 0)));

      // Next after Thursday should wrap to next Monday (2026-11-16)
      final wrapNext = RecurrenceEngine.computeNextDueDate(
        currentDueDate: next!,
        rule: rule,
      );
      expect(wrapNext?.weekday, equals(DateTime.monday));
      expect(wrapNext, equals(DateTime(2026, 11, 16, 10, 0)));
    });

    test(
      'Monthly recurrence with end-of-month day clamping (Jan 31 -> Feb 28)',
      () {
        final currentDue = DateTime(2026, 1, 31, 12, 0);
        const rule = RepeatRule(frequency: 'monthly', interval: 1);

        final next = RecurrenceEngine.computeNextDueDate(
          currentDueDate: currentDue,
          rule: rule,
        );

        expect(next?.year, equals(2026));
        expect(next?.month, equals(2));
        expect(next?.day, equals(28)); // clamped to last day of Feb
      },
    );

    test('After completion recurrence (3 days after task was marked done)', () {
      final currentDue = DateTime(2026, 11, 1, 10, 0);
      final completionDate = DateTime(
        2026,
        11,
        10,
        15,
        0,
      ); // Completed late on 10th
      const rule = RepeatRule(
        frequency: 'after_completion',
        afterCompletionDays: 3,
      );

      final next = RecurrenceEngine.computeNextDueDate(
        currentDueDate: currentDue,
        rule: rule,
        completionDate: completionDate,
      );

      expect(next?.day, equals(13)); // 10th + 3 days = 13th
    });
  });
}
