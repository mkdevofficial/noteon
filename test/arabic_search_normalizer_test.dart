import 'package:flutter_test/flutter_test.dart';
import 'package:noteon/core/utils/arabic_search_normalizer.dart';

void main() {
  group('ArabicSearchNormalizer Tests', () {
    test('Strips Arabic diacritics / tashkeel', () {
      const input = 'مُلاحَظَاتٌ سَرِيعَةٌ';
      final normalized = ArabicSearchNormalizer.normalize(input);
      expect(normalized, equals('ملاحظات سريعه'));
    });

    test('Unifies Alef variations', () {
      const alefs = 'أحمد إبراهيم آمنة ٱمرأة';
      final normalized = ArabicSearchNormalizer.normalize(alefs);
      expect(normalized, equals('احمد ابراهيم امنه امراه'));
    });

    test('Unifies Taa Marbuta to Haa', () {
      const input = 'مكتبة الجامعة';
      final normalized = ArabicSearchNormalizer.normalize(input);
      expect(normalized, equals('مكتبه الجامعه'));
    });

    test('Unifies Alif Maqsura and Hamza on Yaa', () {
      const input = 'منى شاطئ مصطفى';
      final normalized = ArabicSearchNormalizer.normalize(input);
      expect(normalized, equals('مني شاطي مصطفي'));
    });

    test('Search matching works case-insensitively and across tashkeel', () {
      const noteTitle = 'مُهِمَّة تَطْوِير التَّطْبِيقِ السَّحَابِي';
      expect(ArabicSearchNormalizer.matches(noteTitle, 'تطوير'), isTrue);
      expect(ArabicSearchNormalizer.matches(noteTitle, 'السحابي'), isTrue);
      expect(ArabicSearchNormalizer.matches(noteTitle, 'مهمه'), isTrue);
    });

    test('English search normalization and multiple token AND matching', () {
      const text = 'Finish the quarterly sprint report for mobile';
      expect(ArabicSearchNormalizer.matches(text, 'sprint report'), isTrue);
      expect(ArabicSearchNormalizer.matches(text, 'MOBILE FINISH'), isTrue);
      expect(
        ArabicSearchNormalizer.matches(text, 'backend nonexisting'),
        isFalse,
      );
    });
  });
}
