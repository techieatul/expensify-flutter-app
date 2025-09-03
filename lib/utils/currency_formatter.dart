import '../services/currency_service.dart';

/// Utility class for formatting currency amounts
class CurrencyFormatter {
  final CurrencyService _currencyService;

  CurrencyFormatter(this._currencyService);

  /// Format amount with current currency
  String formatAmount(double amount) {
    return _currencyService.formatAmount(amount);
  }

  /// Format amount with currency code
  String formatAmountWithCode(double amount) {
    return _currencyService.formatAmountWithCode(amount);
  }

  /// Get current currency symbol
  String get currencySymbol => _currencyService.currencySymbol;

  /// Get current currency code
  String get currencyCode => _currencyService.currencyCode;

  /// Format amount for input (without currency symbol)
  String formatAmountForInput(double amount) {
    return _currencyService.formatAmountForInput(amount);
  }
}
