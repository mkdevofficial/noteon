import 'package:flutter_test/flutter_test.dart';
import 'package:noteon/core/utils/natural_language_parser.dart';

void main() {
  group('NaturalLanguageParser Tests', () {
    final refDate = DateTime(2026, 11, 10, 10, 0); // Tuesday 10:00 AM

    test('Parses standard English prompt: Call Ahmed tomorrow 5pm !high #work', () {
      final res = NaturalLanguageParser.parse(
        'Call Ahmed tomorrow 5pm !high #work',
        referenceDate: refDate,
      );

      expect(res.title, equals('Call Ahmed'));
      expect(res.priority, equals('high'));
      expect(res.labels, contains('work'));
      expect(res.hasTime, isTrue);
      expect(res.dueAt?.year, equals(2026));
      expect(res.dueAt?.month, equals(11));
      expect(res.dueAt?.day, equals(11)); // Tomorrow is 11th
      expect(res.dueAt?.hour, equals(17)); // 5pm
      expect(res.dueAt?.minute, equals(0));
    });

    test('Parses Arabic prompt: الاتصال بأحمد غداً 5 مساءً !عاجل #عمل', () {
      final res = NaturalLanguageParser.parse(
        'الاتصال بأحمد غداً 5 مساءً !عاجل #عمل',
        referenceDate: refDate,
      );

      expect(res.title, equals('الاتصال بأحمد'));
      expect(res.priority, equals('urgent'));
      expect(res.labels, contains('عمل'));
      expect(res.hasTime, isTrue);
      expect(res.dueAt?.year, equals(2026));
      expect(res.dueAt?.month, equals(11));
      expect(res.dueAt?.day, equals(11)); // غداً
      expect(res.dueAt?.hour, equals(17));
    });

    test('Parses multiple labels and priority variations', () {
      final res = NaturalLanguageParser.parse(
        'Write quarterly report #finance #q4 #audit !urgent',
        referenceDate: refDate,
      );

      expect(res.title, equals('Write quarterly report'));
      expect(res.priority, equals('urgent'));
      expect(res.labels, containsAll(['finance', 'q4', 'audit']));
    });

    test('Handles weekday resolution: Friday 10am', () {
      final res = NaturalLanguageParser.parse(
        'Team sync Friday 10am',
        referenceDate: refDate, // Tuesday Nov 10
      );

      expect(res.title, equals('Team sync'));
      expect(res.hasTime, isTrue);
      expect(res.dueAt?.weekday, equals(DateTime.friday));
      expect(res.dueAt?.hour, equals(10));
    });
  });
}
