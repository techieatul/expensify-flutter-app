import 'package:hive/hive.dart';
import '../models/models.dart';
import 'exchange_rate_service.dart';

/// Service for managing currency preferences and formatting
class CurrencyService {
  static const String _boxName = 'currency_settings';
  static const String _selectedCurrencyKey = 'selected_currency';
  
  // Singleton pattern
  static CurrencyService? _instance;
  static CurrencyService get instance {
    _instance ??= CurrencyService._internal();
    return _instance!;
  }
  
  CurrencyService._internal();
  
  late Box _settingsBox;
  Currency _currentCurrency = Currencies.usd; // Default to USD
  late ExchangeRateService _exchangeRateService;
  bool _isInitialized = false;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _settingsBox = await Hive.openBox(_boxName);
    _exchangeRateService = ExchangeRateService();
    await _exchangeRateService.initialize();
    await _loadSelectedCurrency();
    _isInitialized = true;
  }

  /// Load the selected currency from storage
  Future<void> _loadSelectedCurrency() async {
    final currencyCode = _settingsBox.get(_selectedCurrencyKey, defaultValue: 'USD') as String;
    _currentCurrency = Currencies.getByCode(currencyCode) ?? Currencies.usd;
  }

  /// Get the current selected currency
  Currency get currentCurrency => _currentCurrency;

  /// Set the selected currency
  Future<void> setCurrentCurrency(Currency currency) async {
    _currentCurrency = currency;
    await _settingsBox.put(_selectedCurrencyKey, currency.code);
  }

  /// Format an amount with the current currency
  String formatAmount(double amount) {
    return _currentCurrency.format(amount);
  }

  /// Format an amount with currency code
  String formatAmountWithCode(double amount) {
    return _currentCurrency.formatWithCode(amount);
  }

  /// Get the current currency symbol
  String get currencySymbol => _currentCurrency.symbol;

  /// Get the current currency code
  String get currencyCode => _currentCurrency.code;

  /// Get the current currency name
  String get currencyName => _currentCurrency.name;

  /// Get decimal places for current currency
  int get decimalPlaces => _currentCurrency.decimalPlaces;

  /// Get all available currencies
  List<Currency> get availableCurrencies => Currencies.all;

  /// Get popular currencies
  List<Currency> get popularCurrencies => Currencies.popular;

  /// Check if a currency is currently selected
  bool isCurrencySelected(Currency currency) {
    return _currentCurrency.code == currency.code;
  }

  /// Parse amount string to double (handles different decimal places)
  double parseAmount(String amountString) {
    final amount = double.tryParse(amountString) ?? 0.0;
    
    // Round to the appropriate decimal places for the current currency
    final multiplier = _currentCurrency.decimalPlaces == 0 ? 1 : 100;
    return (amount * multiplier).round() / multiplier;
  }

  /// Format amount for input (without currency symbol)
  String formatAmountForInput(double amount) {
    return amount.toStringAsFixed(_currentCurrency.decimalPlaces);
  }

  /// Get currency display info for UI
  Map<String, dynamic> getCurrencyDisplayInfo() {
    return {
      'symbol': _currentCurrency.symbol,
      'code': _currentCurrency.code,
      'name': _currentCurrency.name,
      'decimalPlaces': _currentCurrency.decimalPlaces,
    };
  }

  /// Convert amount from one currency to current currency
  Future<double?> convertToCurrentCurrency(double amount, String fromCurrency, [DateTime? date]) async {
    return await _exchangeRateService.convertAmount(amount, fromCurrency, _currentCurrency.code, date);
  }

  /// Convert amount from current currency to another currency
  Future<double?> convertFromCurrentCurrency(double amount, String toCurrency, [DateTime? date]) async {
    return await _exchangeRateService.convertAmount(amount, _currentCurrency.code, toCurrency, date);
  }

  /// Get exchange rate between two currencies
  Future<double?> getExchangeRate(String fromCurrency, String toCurrency, [DateTime? date]) async {
    return await _exchangeRateService.getExchangeRate(fromCurrency, toCurrency, date);
  }

  /// Format amount with conversion if needed
  Future<String> formatAmountWithConversion(double amount, String originalCurrency, [DateTime? date]) async {
    if (originalCurrency == _currentCurrency.code) {
      return formatAmount(amount);
    }

    final convertedAmount = await convertToCurrentCurrency(amount, originalCurrency, date);
    if (convertedAmount != null) {
      return '${formatAmount(convertedAmount)} (≈${Currencies.getByCode(originalCurrency)?.symbol ?? originalCurrency}${amount.toStringAsFixed(2)})';
    } else {
      // Fallback to original currency if conversion fails
      final originalCurrencyObj = Currencies.getByCode(originalCurrency);
      return '${originalCurrencyObj?.symbol ?? originalCurrency}${amount.toStringAsFixed(originalCurrencyObj?.decimalPlaces ?? 2)}';
    }
  }

  /// Check if conversion is available
  Future<bool> isConversionAvailable() async {
    return await _exchangeRateService.isOnline();
  }

  /// Dispose resources
  void dispose() {
    // Hive boxes are managed globally, no need to close here
  }
}
