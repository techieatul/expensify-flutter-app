# 🐛 Split Date Issue - Debug Guide

## 🚨 **Current Problem**
Split expenses are being created on the **1st of each month** instead of **preserving the original day**.

**Example:**
- User creates split on **Aug 31** for 2 months
- **Expected**: Aug 31, Sep 30 
- **Actual**: Aug 1, Sep 1

## 🔍 **Investigation Steps**

### **1. Verify Code Changes Applied**
The following files were modified but changes may not be taking effect:

#### **File: `lib/services/split_service.dart`**
- Added `_calculateSplitDate()` helper method
- Updated `createSplitExpense()` to use new date logic
- **Line ~30**: Should call `_calculateSplitDate(splitPlan.startMonth, i)`

#### **File: `lib/screens/split_expense_screen.dart`**  
- Added same `_calculateSplitDate()` helper method
- Updated preview dialog to show exact dates
- **Line ~448**: Should call `_calculateSplitDate(_startDate, index)`

### **2. Debug Commands to Run**

```bash
# Full app restart (not hot reload)
flutter run -d emulator-5554

# Check for any build errors
flutter analyze

# Clear build cache if needed
flutter clean
flutter pub get
```

### **3. Add Debug Logging**

Add these debug prints to verify the logic:

#### **In `lib/services/split_service.dart`:**
```dart
DateTime _calculateSplitDate(DateTime startDate, int monthOffset) {
  print('🔍 DEBUG: Calculating split date');
  print('   Start Date: ${startDate.toString()}');
  print('   Month Offset: $monthOffset');
  
  final targetYear = startDate.year;
  final targetMonth = startDate.month + monthOffset;
  final targetDay = startDate.day;
  
  print('   Target: $targetYear-$targetMonth-$targetDay');
  
  // Handle month overflow
  final adjustedYear = targetYear + ((targetMonth - 1) ~/ 12);
  final adjustedMonth = ((targetMonth - 1) % 12) + 1;
  
  // Handle day overflow
  final daysInMonth = DateTime(adjustedYear, adjustedMonth + 1, 0).day;
  final adjustedDay = targetDay > daysInMonth ? daysInMonth : targetDay;
  
  final result = DateTime(adjustedYear, adjustedMonth, adjustedDay);
  print('   Final Date: ${result.toString()}');
  
  return result;
}
```

#### **In `createSplitExpense()` method:**
```dart
for (int i = 0; i < splitAmounts.length; i++) {
  print('🔍 DEBUG: Creating expense $i');
  final monthDate = _calculateSplitDate(splitPlan.startMonth, i);
  print('   Using date: ${monthDate.toString()}');
  
  final expense = await _expenseService.addExpense(
    amount: splitAmounts[i],
    categoryId: categoryId,
    categoryName: categoryName,
    date: monthDate,  // ← Verify this is using monthDate, not something else
    note: note,
    splitPlanId: splitPlan.id,
    isSplitParent: false,
  );
  
  print('   Created expense: ${expense.id} on ${expense.date}');
}
```

### **4. Check Hive Data**

Add debug method to inspect what's actually stored:

```dart
// In HomeScreen or debug area
void _debugSplitData() {
  final expensesBox = Hive.box('expenses');
  print('🔍 DEBUG: All expenses in Hive:');
  
  for (var key in expensesBox.keys) {
    final expenseData = expensesBox.get(key);
    if (expenseData['splitPlanId'] != null) {
      print('   Split Expense: ${expenseData['date']} - \$${expenseData['amount']}');
    }
  }
}
```

### **5. Potential Root Causes**

#### **A. Hot Reload Issue**
- **Problem**: Flutter hot reload not applying complex logic changes
- **Solution**: Full restart with `flutter run -d emulator-5554`

#### **B. Wrong Date Being Used**
- **Problem**: `addExpense()` might be using a different date parameter
- **Check**: Verify `ExpenseService.addExpense()` method signature
- **Look for**: Any default date logic that overrides the passed date

#### **C. DateTime Constructor Issue**
- **Problem**: `DateTime()` constructor behaving unexpectedly
- **Test**: Try using `DateTime.utc()` instead
- **Check**: Time zone issues affecting date creation

#### **D. Cached State**
- **Problem**: Old split plans or expenses cached in Hive
- **Solution**: Clear app data or add logic to delete old test splits

### **6. Test Cases to Verify Fix**

Once debugging is complete, test these scenarios:

```dart
// Test Case 1: Month end dates
Aug 31 → 2 months → Should be: Aug 31, Sep 30

// Test Case 2: February edge case  
Jan 31 → 2 months → Should be: Jan 31, Feb 28 (or 29)

// Test Case 3: Mid-month dates
May 15 → 3 months → Should be: May 15, Jun 15, Jul 15

// Test Case 4: Year boundary
Dec 31 → 2 months → Should be: Dec 31, Jan 31 (next year)
```

### **7. Quick Verification Steps**

1. **Create a split expense** on any date other than the 1st
2. **Check the preview dialog** - does it show correct dates?
3. **Save the split** and check home screen
4. **Navigate to different months** to verify expenses appear on correct dates
5. **Check debug console** for any error messages

## 🎯 **Expected Resolution**

After applying the debug steps and fixes:
- Split expenses should appear on the **same day of month** as the original
- Edge cases (Feb 31 → Feb 28) should be handled gracefully  
- Preview dialog should show exact dates, not just months
- Debug logs should confirm correct date calculations

## 📝 **Next Steps After Fix**

1. **Remove debug logging** once confirmed working
2. **Add unit tests** for date calculation edge cases
3. **Update user documentation** with split feature details
4. **Test thoroughly** with various date scenarios

---

*Use this guide to systematically debug and resolve the split date issue.*
