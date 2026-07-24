import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final _ddMMMyyyy = DateFormat('dd MMM yyyy');
  static final _ddMMMyyyyHHmm = DateFormat('dd MMM yyyy, HH:mm');
  static final _yyyyMMdd = DateFormat('yyyy-MM-dd');
  static final _hhmm = DateFormat('HH:mm');
  static final _EEEEddMMM = DateFormat('EEEE, dd MMM');
  static final _MMMyyyy = DateFormat('MMM yyyy');

  static String ddMMMyyyy(DateTime date) => _ddMMMyyyy.format(date);
  static String ddMMMyyyyHHmm(DateTime date) => _ddMMMyyyyHHmm.format(date);
  static String yyyyMMdd(DateTime date) => _yyyyMMdd.format(date);
  static String hhmm(DateTime date) => _hhmm.format(date);
  static String EEEEddMMM(DateTime date) => _EEEEddMMM.format(date);
  static String MMMyyyy(DateTime date) => _MMMyyyy.format(date);

  static String relative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return ddMMMyyyy(date);
  }

  static DateTime? parseISO(String date) => DateTime.tryParse(date);

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
