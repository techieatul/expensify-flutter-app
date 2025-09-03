import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/providers.dart';

/// Calculator-style input widget for amount entry
class CalculatorInput extends ConsumerStatefulWidget {
  final String initialValue;
  final Function(String) onValueChanged;
  final VoidCallback? onDone;

  const CalculatorInput({
    super.key,
    this.initialValue = '',
    required this.onValueChanged,
    this.onDone,
  });

  @override
  ConsumerState<CalculatorInput> createState() => _CalculatorInputState();
}

class _CalculatorInputState extends ConsumerState<CalculatorInput> {
  String _display = '0';
  String _expression = '';
  String _previousValue = '';
  String _operator = '';
  bool _waitingForOperand = false;
  bool _hasDecimal = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue.isNotEmpty) {
      _display = widget.initialValue;
      _expression = widget.initialValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Display Section
          _buildDisplay(),
          
          // Calculator Buttons
          _buildCalculatorGrid(),
        ],
      ),
    );
  }

  Widget _buildDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Expression display
          if (_expression.isNotEmpty && _expression != _display)
            Text(
              _expression,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.end,
            ),
          
          // Main display
          Text(
            '${ref.watch(currencyServiceProvider).currencySymbol}$_display',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.end,
          ),
        ],
      ),
    );
  }

  Widget _buildCalculatorGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Row 1: Clear, ±, %, ÷
          Row(
            children: [
              _buildButton('C', _clear, isOperator: true, color: Colors.red),
              _buildButton('±', _toggleSign, isOperator: true),
              _buildButton('%', () => _inputOperator('%'), isOperator: true),
              _buildButton('÷', () => _inputOperator('/'), isOperator: true),
            ],
          ),
          
          // Row 2: 7, 8, 9, ×
          Row(
            children: [
              _buildButton('7', () => _inputNumber('7')),
              _buildButton('8', () => _inputNumber('8')),
              _buildButton('9', () => _inputNumber('9')),
              _buildButton('×', () => _inputOperator('*'), isOperator: true),
            ],
          ),
          
          // Row 3: 4, 5, 6, -
          Row(
            children: [
              _buildButton('4', () => _inputNumber('4')),
              _buildButton('5', () => _inputNumber('5')),
              _buildButton('6', () => _inputNumber('6')),
              _buildButton('-', () => _inputOperator('-'), isOperator: true),
            ],
          ),
          
          // Row 4: 1, 2, 3, +
          Row(
            children: [
              _buildButton('1', () => _inputNumber('1')),
              _buildButton('2', () => _inputNumber('2')),
              _buildButton('3', () => _inputNumber('3')),
              _buildButton('+', () => _inputOperator('+'), isOperator: true),
            ],
          ),
          
          // Row 5: 0, ., =, Done
          Row(
            children: [
              _buildButton('0', () => _inputNumber('0'), flex: 2),
              _buildButton('.', _inputDecimal),
              _buildButton('=', _calculate, isOperator: true, color: Colors.blue),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Done button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _done,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 48),
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(
    String text,
    VoidCallback onPressed, {
    bool isOperator = false,
    Color? color,
    int flex = 1,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: SizedBox(
          height: 60,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: color ?? 
                (isOperator 
                  ? Theme.of(context).colorScheme.secondaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerHighest),
              foregroundColor: color != null 
                ? Colors.white
                : (isOperator 
                  ? Theme.of(context).colorScheme.onSecondaryContainer
                  : Theme.of(context).colorScheme.onSurface),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              text,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _inputNumber(String number) {
    setState(() {
      if (_waitingForOperand) {
        _display = number;
        _waitingForOperand = false;
        _hasDecimal = false;
      } else {
        _display = _display == '0' ? number : _display + number;
      }
      _updateExpression();
    });
    widget.onValueChanged(_display);
  }

  void _inputDecimal() {
    if (_hasDecimal) return;
    
    setState(() {
      if (_waitingForOperand) {
        _display = '0.';
        _waitingForOperand = false;
      } else {
        _display = _display + '.';
      }
      _hasDecimal = true;
      _updateExpression();
    });
    widget.onValueChanged(_display);
  }

  void _inputOperator(String operator) {
    if (_operator.isNotEmpty && !_waitingForOperand) {
      _calculate();
    }

    setState(() {
      _previousValue = _display;
      _operator = operator;
      _waitingForOperand = true;
      _hasDecimal = false;
      _updateExpression();
    });
  }

  void _calculate() {
    if (_operator.isEmpty || _waitingForOperand) return;

    double prev = double.tryParse(_previousValue) ?? 0;
    double current = double.tryParse(_display) ?? 0;
    double result = 0;

    switch (_operator) {
      case '+':
        result = prev + current;
        break;
      case '-':
        result = prev - current;
        break;
      case '*':
        result = prev * current;
        break;
      case '/':
        if (current != 0) {
          result = prev / current;
        } else {
          _showError('Cannot divide by zero');
          return;
        }
        break;
      case '%':
        result = prev % current;
        break;
    }

    setState(() {
      _display = _formatResult(result);
      _expression = '$_previousValue $_operator $current = $_display';
      _operator = '';
      _previousValue = '';
      _waitingForOperand = true;
      _hasDecimal = _display.contains('.');
    });
    
    widget.onValueChanged(_display);
  }

  void _clear() {
    setState(() {
      _display = '0';
      _expression = '';
      _previousValue = '';
      _operator = '';
      _waitingForOperand = false;
      _hasDecimal = false;
    });
    widget.onValueChanged('0');
  }

  void _toggleSign() {
    if (_display == '0') return;
    
    setState(() {
      if (_display.startsWith('-')) {
        _display = _display.substring(1);
      } else {
        _display = '-$_display';
      }
      _updateExpression();
    });
    widget.onValueChanged(_display);
  }

  void _updateExpression() {
    if (_operator.isNotEmpty && _previousValue.isNotEmpty) {
      _expression = '$_previousValue $_operator $_display';
    } else {
      _expression = _display;
    }
  }

  String _formatResult(double result) {
    final currencyService = ref.read(currencyServiceProvider);
    final decimalPlaces = currencyService.decimalPlaces;
    
    // Format according to currency's decimal places
    if (decimalPlaces == 0) {
      return result.round().toString();
    } else {
      return result.toStringAsFixed(decimalPlaces);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _done() {
    // Ensure we have a valid result
    if (_operator.isNotEmpty && !_waitingForOperand) {
      _calculate();
    }
    
    widget.onDone?.call();
  }
}
