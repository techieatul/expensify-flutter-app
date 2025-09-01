# Expensify Flutter App - Development State & Context

## 📋 Current Status (Last Updated: 2024)

### ✅ **Completed Features:**
- ✅ Project setup with Flutter & Dart
- ✅ Material Design 3 theming with dark/light mode
- ✅ Riverpod state management
- ✅ Go Router navigation with shell routes
- ✅ Hive local persistence (offline-first)
- ✅ Core data models (Expense, Category, SplitPlan)
- ✅ Business logic services (ExpenseService, CategoryService, SplitService)
- ✅ Home screen with monthly expense tracking
- ✅ Add/Edit expense functionality
- ✅ Categories management
- ✅ Analysis screen with spending insights
- ✅ Split expense UI and basic functionality

### 🚧 **Current Issues:**
1. **CRITICAL: Split Date Logic Bug**
   - **Problem**: Split expenses are being created on the 1st of each month instead of preserving the original day
   - **Expected**: Aug 31 split → Aug 31, Sep 30
   - **Actual**: Aug 31 split → Aug 1, Sep 1
   - **Status**: Code changes made but not taking effect (hot reload issue?)

### 🔧 **Recent Changes Made:**
- Updated `lib/services/split_service.dart` with `_calculateSplitDate()` helper method
- Updated `lib/screens/split_expense_screen.dart` with same date calculation logic
- Enhanced preview dialog to show exact dates instead of just months
- Added proper month/year overflow handling and day adjustment for months with fewer days

### 🎯 **Next Steps:**
1. **Debug split date issue** - changes not taking effect
2. **Test hot reload vs full restart** - may need full app restart
3. **Verify date calculation logic** in actual expense creation
4. **Test edge cases** (Feb 29, month boundaries, year boundaries)

---

## 🏗️ **Architecture Overview**

### **📁 Project Structure:**
```
lib/
├── main.dart                 # App entry point, Hive initialization
├── models/                   # Data models
│   ├── expense.dart         # Expense model with JSON serialization
│   ├── category.dart        # Category model with icon mapping
│   ├── split_plan.dart      # Split plan model with distribution logic
│   └── models.dart          # Barrel export
├── screens/                  # UI screens
│   ├── home_screen.dart     # Monthly expense overview
│   ├── add_expense_screen.dart # Add/edit single expenses
│   ├── split_expense_screen.dart # Split expense across months
│   ├── analysis_screen.dart # Spending analysis & charts
│   ├── categories_screen.dart # Category management
│   ├── main_shell.dart      # Navigation shell
│   ├── splash_screen.dart   # Loading screen
│   └── screens.dart         # Barrel export
├── services/                 # Business logic
│   ├── expense_service.dart # Expense CRUD operations
│   ├── category_service.dart # Category CRUD operations
│   ├── split_service.dart   # Split expense logic
│   ├── providers.dart       # Riverpod providers
│   └── theme_provider.dart  # Theme state management
└── utils/                    # Utilities
    ├── constants.dart       # App constants & Hive box names
    ├── extensions.dart      # DateTime, double, string extensions
    ├── validators.dart      # Form validation
    ├── theme.dart          # Material 3 theme configuration
    ├── router.dart         # Go Router configuration
    └── sample_data.dart    # Development sample data
```

### **🗄️ Data Models:**

#### **Expense Model:**
```dart
class Expense {
  final String id;
  final double amount;
  final String currencyCode;
  final String categoryId;
  final DateTime date;
  final String? note;
  final String? splitPlanId;      // Links to split plan if part of split
  final bool isSplitParent;       // True if this is the original split expense
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;      // Soft delete support
}
```

#### **Category Model:**
```dart
class Category {
  final String id;
  final String name;
  final String icon;              // String name mapped to IconData
  final int color;                // Color value
  final bool isDefault;           // System vs user categories
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
}
```

#### **SplitPlan Model:**
```dart
class SplitPlan {
  final String id;
  final double totalAmount;
  final DateTime startMonth;
  final int numberOfMonths;
  final DistributionType distributionType;  // equal, custom
  final List<double>? customDistributions;
  final RoundingMode roundingMode;          // roundHalfUp, ceil, floor
  final List<String> generatedExpenseIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
}
```

### **🔄 State Management (Riverpod):**
```dart
// Service providers
final expenseServiceProvider = Provider<ExpenseService>(...);
final categoryServiceProvider = Provider<CategoryService>(...);
final splitServiceProvider = Provider<SplitService>(...);

// State providers
final expensesProvider = StateNotifierProvider<ExpensesNotifier, List<Expense>>(...);
final categoriesProvider = StateNotifierProvider<CategoriesNotifier, List<Category>>(...);
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(...);
```

### **🗃️ Data Persistence (Hive):**
```dart
// Hive boxes
const String expensesBox = 'expenses';
const String categoriesBox = 'categories';  
const String splitPlansBox = 'splitPlans';
const String settingsBox = 'settings';
```

---

## 🎨 **UI/UX Design**

### **🎯 Material Design 3:**
- **Primary Color**: `#2563EB` (Modern blue)
- **Secondary Color**: `#10B981` (Emerald green)
- **Surface Colors**: Softer grays instead of stark white
- **Dark Theme**: Deep slate colors with rich contrasts
- **Typography**: Google Fonts integration

### **📱 Navigation Structure:**
```
Shell Route (Bottom Navigation)
├── Home (/home)
├── Analysis (/analysis)  
└── Categories (/categories)

Nested Routes
├── Add Expense (/home/add-expense)
├── Edit Expense (/home/edit-expense/:id)
└── Split Expense (/home/split-expense)
```

### **🎭 Key UI Components:**
- **Expense Cards**: Swipe actions, category icons, amount formatting
- **Category Chips**: Color-coded, icon-based selection
- **Date Pickers**: Support for future dates, month navigation
- **Split Preview**: Real-time calculation display with exact dates
- **Theme Toggle**: System/Light/Dark mode switching

---

## 🔧 **Technical Implementation Details**

### **📅 Date Handling:**
```dart
// Extensions for DateTime
extension DateTimeExtensions on DateTime {
  String get displayDate => DateFormat('MMM d, yyyy').format(this);
  String get monthKey => DateFormat('yyyy-MM').format(this);
  String get monthYear => DateFormat('MMM yyyy').format(this);
  bool get isToday => isSameDay(DateTime.now());
}
```

### **💰 Currency Formatting:**
```dart
extension DoubleExtensions on double {
  String get currency => NumberFormat.currency(symbol: '\$').format(this);
  double get rounded => (this * 100).round() / 100;
}
```

### **🔄 Split Logic (CURRENT ISSUE):**
```dart
// This logic was implemented but not taking effect
DateTime _calculateSplitDate(DateTime startDate, int monthOffset) {
  final targetYear = startDate.year;
  final targetMonth = startDate.month + monthOffset;
  final targetDay = startDate.day;
  
  // Handle month overflow
  final adjustedYear = targetYear + ((targetMonth - 1) ~/ 12);
  final adjustedMonth = ((targetMonth - 1) % 12) + 1;
  
  // Handle day overflow (Feb 31 → Feb 28/29, Sep 31 → Sep 30)
  final daysInMonth = DateTime(adjustedYear, adjustedMonth + 1, 0).day;
  final adjustedDay = targetDay > daysInMonth ? daysInMonth : targetDay;
  
  return DateTime(adjustedYear, adjustedMonth, adjustedDay);
}
```

---

## 🐛 **Known Issues & Debugging**

### **🚨 Critical Issues:**

#### **1. Split Date Bug (ACTIVE)**
- **Symptom**: Split expenses created on 1st of month instead of preserving day
- **Files Modified**: 
  - `lib/services/split_service.dart`
  - `lib/screens/split_expense_screen.dart`
- **Potential Causes**:
  - Hot reload not applying changes
  - Cached state in Hive
  - Logic not being called in the right place
  - DateTime constructor issues

#### **2. Hot Reload Issues**
- **Symptom**: Code changes not taking effect with `r` command
- **Workaround**: May need full app restart (`R` or `flutter run`)

### **🔍 Debugging Steps for Split Issue:**
1. **Add debug prints** to `_calculateSplitDate()` method
2. **Verify method is being called** in `createSplitExpense()`
3. **Check Hive data** to see what dates are actually stored
4. **Test with full app restart** instead of hot reload
5. **Add logging** to expense creation process

### **🧪 Test Cases for Split Feature:**
```dart
// Test cases to verify once fixed:
Test Case 1: Aug 31 → 2 months → Aug 31, Sep 30
Test Case 2: Jan 31 → 3 months → Jan 31, Feb 28/29, Mar 31  
Test Case 3: May 15 → 4 months → May 15, Jun 15, Jul 15, Aug 15
Test Case 4: Feb 29 (leap) → 2 months → Feb 29, Mar 29
Test Case 5: Dec 31 → 2 months → Dec 31, Jan 31 (next year)
```

---

## 📚 **Development History**

### **🎯 Major Milestones:**
1. **Project Setup** - Flutter, dependencies, folder structure
2. **Firebase → Hive Migration** - Switched to local-first approach
3. **UI Theme Overhaul** - From stark white to vibrant Material 3
4. **Navigation Refactor** - Shell routes, proper back button behavior
5. **State Management** - Riverpod integration with proper invalidation
6. **Split Feature Implementation** - Complex business logic with rounding

### **🔄 Recent User Feedback:**
- ✅ "Dark mode and colors look much better now"
- ✅ "Categories and expense saving working properly"
- ✅ "Date picker allows future dates now"
- ❌ "Split dates still going to 1st of month instead of preserving day"

### **🛠️ Development Patterns:**
- **Iterative Development**: Build → Test → Fix → Repeat
- **User-Driven**: Immediate feedback and rapid iteration
- **Error-First**: Address build errors and linting issues promptly
- **State Invalidation**: Always invalidate Riverpod providers after mutations

---

## 🚀 **Next Session Action Plan**

### **🎯 Immediate Priority (Split Date Fix):**
1. **Full App Restart**: Try `flutter run` instead of hot reload
2. **Add Debug Logging**: Verify `_calculateSplitDate()` is being called
3. **Check Hive Data**: Inspect actual stored dates in database
4. **Test Edge Cases**: Verify all month/day combinations work
5. **User Acceptance Test**: Confirm fix with user testing

### **📋 Remaining Features:**
- **Unit/Widget/Integration Tests**: Comprehensive test coverage
- **App Icon & Splash**: Visual branding assets
- **Performance Optimization**: Large dataset handling
- **Error Handling**: Graceful failure recovery
- **Accessibility**: Screen reader support, keyboard navigation

### **🔧 Technical Debt:**
- **Code Documentation**: Add comprehensive inline docs
- **Type Safety**: Strengthen null safety throughout
- **Performance**: Optimize list rendering for large datasets
- **Offline Sync**: Future cloud sync preparation

---

## 💡 **Key Learnings & Notes**

### **🎯 Flutter/Dart Specific:**
- **Hot Reload Limitations**: Complex state changes may require full restart
- **Hive Persistence**: Requires proper box initialization and JSON serialization
- **Riverpod State**: Always invalidate providers after data mutations
- **Go Router**: Shell routes provide better navigation UX than simple routes

### **🎨 UI/UX Insights:**
- **Material 3**: Provides excellent theming but requires careful color selection
- **Dark Mode**: Essential for modern apps, users expect it
- **Date Handling**: Complex business logic requires extensive edge case testing
- **Form Validation**: Real-time feedback improves user experience

### **🐛 Common Pitfalls:**
- **State Not Updating**: Usually missing provider invalidation
- **Navigation Issues**: Shell routes solve most back button problems
- **Date Calculations**: Month boundaries and leap years are tricky
- **Build Errors**: Always run `flutter analyze` after major changes

---

*This document serves as a comprehensive reference for continuing development of the Expensify Flutter app. Update it as the project evolves.*
