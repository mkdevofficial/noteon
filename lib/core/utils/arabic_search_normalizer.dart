class ArabicSearchNormalizer {
  static final RegExp _diacriticsRegex = RegExp(
    r'[\u064B-\u0652\u0653-\u065F\u0670\u0640]',
  );

  /// Normalizes Arabic and Latin strings for reliable client-side search.
  /// - Strips diacritics / tashkeel and tatweel
  /// - Unifies alef forms (أ, إ, آ, ٱ -> ا)
  /// - Unifies taa marbuta (ة -> ه)
  /// - Unifies alif maqsura and yaa forms (ى, ئ -> ي)
  /// - Unifies waw with hamza (ؤ -> و)
  /// - Converts to lower case
  /// - Normalizes consecutive whitespace
  static String normalize(String text) {
    if (text.isEmpty) return '';

    String result = text.toLowerCase();

    // Strip Arabic diacritics (harakat/tashkeel) and tatweel
    result = result.replaceAll(_diacriticsRegex, '');

    // Unify Alefs
    result = result
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ٱ', 'ا');

    // Unify Taa Marbuta -> Haa
    result = result.replaceAll('ة', 'ه');

    // Unify Alif Maqsura / Yaa / Hamza on Yaa -> Yaa
    result = result.replaceAll('ى', 'ي').replaceAll('ئ', 'ي');

    // Unify Waw with Hamza -> Waw
    result = result.replaceAll('ؤ', 'و');

    // Persian/Urdu variants normalization
    result = result.replaceAll('ك', 'ك').replaceAll('ک', 'ك');

    // Collapse multiple whitespaces
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();

    return result;
  }

  /// Checks if [query] matches [target] using normalized comparison.
  static bool matches(String target, String query) {
    if (query.trim().isEmpty) return true;
    final normalizedTarget = normalize(target);
    final normalizedQuery = normalize(query);

    // If query has multiple tokens, all must match (AND matching)
    final tokens = normalizedQuery.split(' ');
    for (final token in tokens) {
      if (token.isNotEmpty && !normalizedTarget.contains(token)) {
        return false;
      }
    }
    return true;
  }
}
