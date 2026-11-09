class ParsedTaskInput {
  final String title;
  final DateTime? dueAt;
  final bool hasTime;
  final String priority; // 'none', 'low', 'medium', 'high', 'urgent'
  final List<String> labels;

  const ParsedTaskInput({
    required this.title,
    this.dueAt,
    this.hasTime = false,
    this.priority = 'none',
    this.labels = const [],
  });

  @override
  String toString() =>
      'ParsedTaskInput(title: "$title", dueAt: $dueAt, hasTime: $hasTime, priority: $priority, labels: $labels)';
}

class NaturalLanguageParser {
  /// Parses natural language task strings in English and Arabic.
  /// Example: "Call Ahmed tomorrow 5pm !high #work"
  /// Example: "الاتصال بأحمد غداً 5 مساءً !عاجل #عمل"
  static ParsedTaskInput parse(String input, {DateTime? referenceDate}) {
    final now = referenceDate ?? DateTime.now();
    var workingText = input.trim();
    if (workingText.isEmpty) {
      return const ParsedTaskInput(title: '');
    }

    final labels = <String>[];
    String priority = 'none';
    DateTime? dueDate;
    int? hour;
    int? minute;
    bool hasExplicitTime = false;

    // 1. Extract and remove labels (#tag)
    final tagRegex = RegExp(r'#([^\s#]+)');
    for (final match in tagRegex.allMatches(workingText)) {
      final tag = match.group(1);
      if (tag != null && tag.isNotEmpty) {
        labels.add(tag);
      }
    }
    workingText = workingText.replaceAll(tagRegex, ' ');

    // 2. Extract and remove priority (!high, !urgent, !عاجل, etc.)
    final priorityRegex = RegExp(
      r'!(urgent|high|medium|med|low|عاجل|مرتفع|عالي|متوسط|منخفض)',
      caseSensitive: false,
    );
    final priorityMatch = priorityRegex.firstMatch(workingText);
    if (priorityMatch != null) {
      final pStr = priorityMatch.group(1)!.toLowerCase();
      if (pStr == 'urgent' || pStr == 'عاجل') {
        priority = 'urgent';
      } else if (pStr == 'high' || pStr == 'مرتفع' || pStr == 'عالي') {
        priority = 'high';
      } else if (pStr == 'medium' || pStr == 'med' || pStr == 'متوسط') {
        priority = 'medium';
      } else if (pStr == 'low' || pStr == 'منخفض') {
        priority = 'low';
      }
      workingText = workingText.replaceAll(priorityRegex, ' ');
    }

    // 3. Extract time (e.g. 5pm, 5:30pm, 17:00, 5 مساءً, 9 صباحاً)
    final timeEnRegex = RegExp(
      r'\b(\d{1,2})(?::(\d{2}))?\s*(am|pm)\b',
      caseSensitive: false,
    );
    final time24Regex = RegExp(r'\b([01]?\d|2[0-3]):([0-5]\d)\b');
    final timeArRegex = RegExp(
      r'(\d{1,2})(?::(\d{2}))?\s*(مساءً|مساء|صباحاً|صباح|م|ص)',
      caseSensitive: false,
    );

    final arTimeMatch = timeArRegex.firstMatch(workingText);
    if (arTimeMatch != null) {
      var h = int.parse(arTimeMatch.group(1)!);
      final m = arTimeMatch.group(2) != null
          ? int.parse(arTimeMatch.group(2)!)
          : 0;
      final period = arTimeMatch.group(3)!;
      final isPm = period.contains('مساء') || period == 'م';
      if (isPm && h < 12) h += 12;
      if (!isPm && h == 12) h = 0;
      hour = h;
      minute = m;
      hasExplicitTime = true;
      workingText = workingText.replaceRange(
        arTimeMatch.start,
        arTimeMatch.end,
        ' ',
      );
    } else {
      final enTimeMatch = timeEnRegex.firstMatch(workingText);
      if (enTimeMatch != null) {
        var h = int.parse(enTimeMatch.group(1)!);
        final m = enTimeMatch.group(2) != null
            ? int.parse(enTimeMatch.group(2)!)
            : 0;
        final period = enTimeMatch.group(3)!.toLowerCase();
        if (period == 'pm' && h < 12) h += 12;
        if (period == 'am' && h == 12) h = 0;
        hour = h;
        minute = m;
        hasExplicitTime = true;
        workingText = workingText.replaceRange(
          enTimeMatch.start,
          enTimeMatch.end,
          ' ',
        );
      } else {
        final match24 = time24Regex.firstMatch(workingText);
        if (match24 != null) {
          hour = int.parse(match24.group(1)!);
          minute = int.parse(match24.group(2)!);
          hasExplicitTime = true;
          workingText = workingText.replaceRange(
            match24.start,
            match24.end,
            ' ',
          );
        }
      }
    }

    // 4. Extract relative date keywords (English & Arabic)
    final dateKeywords = [
      {
        'keyword': RegExp(
          r'(?:^|\s)(today|اليوم)(?:$|\s)',
          caseSensitive: false,
        ),
        'days': 0,
      },
      {
        'keyword': RegExp(
          r'(?:^|\s)(tomorrow|غداً|غدا)(?:$|\s)',
          caseSensitive: false,
        ),
        'days': 1,
      },
      {
        'keyword': RegExp(
          r'(?:^|\s)(بعد غد|after tomorrow)(?:$|\s)',
          caseSensitive: false,
        ),
        'days': 2,
      },
      {
        'keyword': RegExp(
          r'(?:^|\s)(next week|الأسبوع القادم|الاسبوع القادم)(?:$|\s)',
          caseSensitive: false,
        ),
        'days': 7,
      },
    ];

    for (final dk in dateKeywords) {
      final reg = dk['keyword'] as RegExp;
      if (reg.hasMatch(workingText)) {
        final daysToAdd = dk['days'] as int;
        final targetDate = now.add(Duration(days: daysToAdd));
        dueDate = DateTime(targetDate.year, targetDate.month, targetDate.day);
        workingText = workingText.replaceAll(reg, ' ');
        break;
      }
    }

    // Check weekday names (Monday..Sunday, الأحد..السبت)
    if (dueDate == null) {
      final weekdayMap = {
        'monday': DateTime.monday,
        'mon': DateTime.monday,
        'الإثنين': DateTime.monday,
        'الاثنين': DateTime.monday,
        'tuesday': DateTime.tuesday,
        'tue': DateTime.tuesday,
        'الثلاثاء': DateTime.tuesday,
        'wednesday': DateTime.wednesday,
        'wed': DateTime.wednesday,
        'الأربعاء': DateTime.wednesday,
        'الاربعاء': DateTime.wednesday,
        'thursday': DateTime.thursday,
        'thu': DateTime.thursday,
        'الخميس': DateTime.thursday,
        'friday': DateTime.friday,
        'fri': DateTime.friday,
        'الجمعة': DateTime.friday,
        'saturday': DateTime.saturday,
        'sat': DateTime.saturday,
        'السبت': DateTime.saturday,
        'sunday': DateTime.sunday,
        'sun': DateTime.sunday,
        'الأحد': DateTime.sunday,
        'الاحد': DateTime.sunday,
      };

      for (final entry in weekdayMap.entries) {
        final reg = RegExp(
          r'(?:^|\s)' + RegExp.escape(entry.key) + r'(?:$|\s)',
          caseSensitive: false,
        );
        if (reg.hasMatch(workingText)) {
          final targetWeekday = entry.value;
          var daysToAdd = (targetWeekday - now.weekday) % 7;
          if (daysToAdd <= 0) daysToAdd += 7;
          final targetDate = now.add(Duration(days: daysToAdd));
          dueDate = DateTime(targetDate.year, targetDate.month, targetDate.day);
          workingText = workingText.replaceAll(reg, ' ');
          break;
        }
      }
    }

    // If explicit time was found but no date was specified, default to today (or tomorrow if time already passed)
    if (hasExplicitTime) {
      if (dueDate == null) {
        final candidate = DateTime(
          now.year,
          now.month,
          now.day,
          hour!,
          minute!,
        );
        if (candidate.isBefore(now)) {
          final tomorrow = now.add(const Duration(days: 1));
          dueDate = DateTime(
            tomorrow.year,
            tomorrow.month,
            tomorrow.day,
            hour,
            minute,
          );
        } else {
          dueDate = candidate;
        }
      } else {
        dueDate = DateTime(
          dueDate.year,
          dueDate.month,
          dueDate.day,
          hour!,
          minute!,
        );
      }
    }

    // Clean remaining title
    final cleanTitle = workingText.replaceAll(RegExp(r'\s+'), ' ').trim();

    return ParsedTaskInput(
      title: cleanTitle.isEmpty ? input.trim() : cleanTitle,
      dueAt: dueDate,
      hasTime: hasExplicitTime,
      priority: priority,
      labels: labels,
    );
  }
}
