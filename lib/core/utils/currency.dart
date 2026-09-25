import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _ngn = NumberFormat.currency(
    locale: 'en_NG',
    symbol: '₦',
    decimalDigits: 2,
  );

  static String format(double value) => _ngn.format(value);
}
