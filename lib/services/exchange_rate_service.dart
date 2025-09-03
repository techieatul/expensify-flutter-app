import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import '../models/models.dart';

/// Service for fetching and caching exchange rates
class ExchangeRateService {
  static const String _boxName = 'exchange_rates';
  static const String _baseUrl = 'https://api.exchangerate-api.com/v4/latest';
  
  late Box _ratesBox;
  
  /// Initialize the service
  Future<void> initialize() async {
    _ratesBox = await Hive.openBox(_boxName);
  }

  /// Get exchange rate from one currency to another
  /// Returns null if rate cannot be fetched
  Future<double?> getExchangeRate(String fromCurrency, String toCurrency, [DateTime? date]) async {
    if (fromCurrency == toCurrency) return 1.0;
    
    // Try to get cached rate first
    final cacheKey = '${fromCurrency}_${toCurrency}_${date?.toIso8601String().split('T')[0] ?? 'latest'}';
    final cachedRate = _ratesBox.get(cacheKey);
    
    if (cachedRate != null) {
      return cachedRate as double;
    }
    
    try {
      // Fetch from API
      final rate = await _fetchExchangeRate(fromCurrency, toCurrency, date);
      
      // Cache the result for 24 hours
      if (rate != null) {
        await _ratesBox.put(cacheKey, rate);
        
        // Set expiry for cache cleanup (store timestamp)
        await _ratesBox.put('${cacheKey}_timestamp', DateTime.now().millisecondsSinceEpoch);
      }
      
      return rate;
    } catch (e) {
      print('Error fetching exchange rate: $e');
      return null;
    }
  }

  /// Fetch exchange rate from API
  Future<double?> _fetchExchangeRate(String fromCurrency, String toCurrency, DateTime? date) async {
    try {
      // For historical rates, we'd need a different endpoint or service
      // For now, we'll use latest rates for all dates
      final url = '$_baseUrl/$fromCurrency';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;
        
        if (rates.containsKey(toCurrency)) {
          return (rates[toCurrency] as num).toDouble();
        }
      }
      
      return null;
    } catch (e) {
      print('API request failed: $e');
      return null;
    }
  }

  /// Convert amount from one currency to another
  Future<double?> convertAmount(double amount, String fromCurrency, String toCurrency, [DateTime? date]) async {
    final rate = await getExchangeRate(fromCurrency, toCurrency, date);
    if (rate == null) return null;
    
    return amount * rate;
  }

  /// Get multiple exchange rates at once
  Future<Map<String, double>> getMultipleRates(String baseCurrency, List<String> targetCurrencies) async {
    final rates = <String, double>{};
    
    try {
      final url = '$_baseUrl/$baseCurrency';
      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final apiRates = data['rates'] as Map<String, dynamic>;
        
        for (final currency in targetCurrencies) {
          if (apiRates.containsKey(currency)) {
            rates[currency] = (apiRates[currency] as num).toDouble();
          }
        }
      }
    } catch (e) {
      print('Error fetching multiple rates: $e');
    }
    
    return rates;
  }

  /// Clear old cached rates (older than 24 hours)
  Future<void> clearOldCache() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final keysToDelete = <String>[];
    
    for (final key in _ratesBox.keys) {
      if (key.toString().endsWith('_timestamp')) {
        final timestamp = _ratesBox.get(key) as int?;
        if (timestamp != null && now - timestamp > 24 * 60 * 60 * 1000) {
          // Remove both the timestamp and the rate
          final rateKey = key.toString().replaceAll('_timestamp', '');
          keysToDelete.addAll([key.toString(), rateKey]);
        }
      }
    }
    
    for (final key in keysToDelete) {
      await _ratesBox.delete(key);
    }
  }

  /// Check if we have internet connectivity by testing API
  Future<bool> isOnline() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/USD'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get supported currencies from the API
  Future<List<String>> getSupportedCurrencies() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/USD'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;
        return rates.keys.toList()..sort();
      }
    } catch (e) {
      print('Error fetching supported currencies: $e');
    }
    
    // Return our predefined currencies as fallback
    return Currencies.all.map((c) => c.code).toList();
  }
}
