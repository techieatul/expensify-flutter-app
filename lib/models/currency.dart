/// Represents a currency with its properties
class Currency {
  final String code;
  final String name;
  final String symbol;
  final int decimalPlaces;
  final String locale;

  const Currency({
    required this.code,
    required this.name,
    required this.symbol,
    this.decimalPlaces = 2,
    required this.locale,
  });

  /// Format an amount with this currency
  String format(double amount) {
    final formatted = amount.toStringAsFixed(decimalPlaces);
    return '$symbol$formatted';
  }

  /// Format an amount with currency code
  String formatWithCode(double amount) {
    final formatted = amount.toStringAsFixed(decimalPlaces);
    return '$symbol$formatted $code';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Currency &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => '$name ($code)';

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'symbol': symbol,
        'decimalPlaces': decimalPlaces,
        'locale': locale,
      };

  /// Create from JSON
  factory Currency.fromJson(Map<String, dynamic> json) => Currency(
        code: json['code'] as String,
        name: json['name'] as String,
        symbol: json['symbol'] as String,
        decimalPlaces: json['decimalPlaces'] as int? ?? 2,
        locale: json['locale'] as String,
      );
}

/// Predefined currencies
class Currencies {
  static const Currency usd = Currency(
    code: 'USD',
    name: 'US Dollar',
    symbol: '\$',
    locale: 'en_US',
  );

  static const Currency eur = Currency(
    code: 'EUR',
    name: 'Euro',
    symbol: '€',
    locale: 'en_EU',
  );

  static const Currency gbp = Currency(
    code: 'GBP',
    name: 'British Pound',
    symbol: '£',
    locale: 'en_GB',
  );

  static const Currency jpy = Currency(
    code: 'JPY',
    name: 'Japanese Yen',
    symbol: '¥',
    decimalPlaces: 0,
    locale: 'ja_JP',
  );

  static const Currency cad = Currency(
    code: 'CAD',
    name: 'Canadian Dollar',
    symbol: 'C\$',
    locale: 'en_CA',
  );

  static const Currency aud = Currency(
    code: 'AUD',
    name: 'Australian Dollar',
    symbol: 'A\$',
    locale: 'en_AU',
  );

  static const Currency chf = Currency(
    code: 'CHF',
    name: 'Swiss Franc',
    symbol: 'CHF',
    locale: 'de_CH',
  );

  static const Currency cny = Currency(
    code: 'CNY',
    name: 'Chinese Yuan',
    symbol: '¥',
    locale: 'zh_CN',
  );

  static const Currency inr = Currency(
    code: 'INR',
    name: 'Indian Rupee',
    symbol: '₹',
    locale: 'hi_IN',
  );

  static const Currency krw = Currency(
    code: 'KRW',
    name: 'South Korean Won',
    symbol: '₩',
    decimalPlaces: 0,
    locale: 'ko_KR',
  );

  static const Currency brl = Currency(
    code: 'BRL',
    name: 'Brazilian Real',
    symbol: 'R\$',
    locale: 'pt_BR',
  );

  static const Currency rub = Currency(
    code: 'RUB',
    name: 'Russian Ruble',
    symbol: '₽',
    locale: 'ru_RU',
  );

  static const Currency mxn = Currency(
    code: 'MXN',
    name: 'Mexican Peso',
    symbol: 'MX\$',
    locale: 'es_MX',
  );

  static const Currency sgd = Currency(
    code: 'SGD',
    name: 'Singapore Dollar',
    symbol: 'S\$',
    locale: 'en_SG',
  );

  static const Currency hkd = Currency(
    code: 'HKD',
    name: 'Hong Kong Dollar',
    symbol: 'HK\$',
    locale: 'en_HK',
  );

  /// List of all supported currencies
  static const List<Currency> all = [
    usd,
    eur,
    gbp,
    jpy,
    cad,
    aud,
    chf,
    cny,
    inr,
    krw,
    brl,
    rub,
    mxn,
    sgd,
    hkd,
  ];

  /// Get currency by code
  static Currency? getByCode(String code) {
    try {
      return all.firstWhere((currency) => currency.code == code);
    } catch (e) {
      return null;
    }
  }

  /// Popular currencies (for quick selection)
  static const List<Currency> popular = [
    usd,
    eur,
    gbp,
    jpy,
    cad,
    aud,
    inr,
    cny,
  ];
}
