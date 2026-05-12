class TunisianCalendar {
  // Fixed national holidays (MM-DD)
  static const fixedHolidays = {
    '01-01': 'New Year\'s Day',
    '03-20': 'Independence Day',
    '04-09': 'Martyrs\' Day',
    '05-01': 'Labour Day',
    '07-25': 'Republic Day',
    '08-13': 'Women\'s Day',
    '10-15': 'Evacuation Day',
  };

  // Approximate Ramadan start dates (update yearly)
  static final ramadanStarts = {
    2025: DateTime(2025, 3, 1),
    2026: DateTime(2026, 2, 18),
    2027: DateTime(2027, 2, 7),
  };

  static String? getEventForDate(DateTime date) {
    final key = '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    if (fixedHolidays.containsKey(key)) return fixedHolidays[key]!;

    // Check Ramadan (30 days from start)
    final ramadanStart = ramadanStarts[date.year];
    if (ramadanStart != null) {
      final diff = date.difference(ramadanStart).inDays;
      if (diff >= 0 && diff < 30) return 'Ramadan Day ${diff + 1}';
      if (diff == 30) return "Eid Al-Fitr";
    }
    return null;
  }

  static String getSeason(DateTime date) {
    final m = date.month;
    if (m >= 3 && m <= 5) return 'Spring';
    if (m >= 6 && m <= 8) return 'Summer';
    if (m >= 9 && m <= 11) return 'Autumn';
    return 'Winter';
  }

  static double getWeekendMultiplier(DateTime date) {
    return (date.weekday == DateTime.friday || date.weekday == DateTime.saturday)
        ? 1.35
        : 1.0;
  }
}
