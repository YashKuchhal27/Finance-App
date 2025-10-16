import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../models/category.dart' as models;
import '../models/monthly_balance.dart';
import '../database/database_helper.dart';

class ExpenseProvider with ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  List<Transaction> _transactions = [];
  List<models.Category> _categories = [];
  MonthlyBalance? _currentMonthlyBalance;
  String _currentMonthYear = '';
  bool _isLoading = false;

  // Getters
  List<Transaction> get transactions => _transactions;
  List<models.Category> get categories => _categories;
  MonthlyBalance? get currentMonthlyBalance => _currentMonthlyBalance;
  String get currentMonthYear => _currentMonthYear;
  bool get isLoading => _isLoading;

  // Initialize the provider
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    await _loadCategories();
    await _setCurrentMonth();
    await _ensureCurrentMonthBalance();
    await _loadCurrentMonthData();

    _isLoading = false;
    notifyListeners();
  }

  // Set current month
  Future<void> _setCurrentMonth() async {
    final now = DateTime.now();
    _currentMonthYear = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  // Load categories
  Future<void> _loadCategories() async {
    _categories = await _databaseHelper.getCategories();
  }

  // Load current month data
  Future<void> _loadCurrentMonthData() async {
    _transactions = await _databaseHelper.getTransactions(_currentMonthYear);
    _currentMonthlyBalance =
        await _databaseHelper.getMonthlyBalance(_currentMonthYear);
  }

  // Ensure current month has a balance initialized with 10000 + carry-forward from previous month
  Future<void> _ensureCurrentMonthBalance() async {
    final existing = await _databaseHelper.getMonthlyBalance(_currentMonthYear);
    if (existing != null) return;

    final now = DateTime.now();
    final prev = DateTime(now.year, now.month - 1, 1);
    final prevMonthYear =
        '${prev.year}-${prev.month.toString().padLeft(2, '0')}';

    double carryForward = 0.0;
    final prevBalance = await _databaseHelper.getMonthlyBalance(prevMonthYear);
    if (prevBalance != null) {
      final prevExpenses =
          await _databaseHelper.getTotalExpenses(prevMonthYear);
      final remaining = prevBalance.initialBalance - prevExpenses;
      if (remaining > 0) carryForward = remaining;
    }

    final initial = 10000.0 + carryForward;
    final monthlyBalance = MonthlyBalance(
      monthYear: _currentMonthYear,
      initialBalance: initial,
      createdAt: DateTime.now(),
    );
    await _databaseHelper.insertMonthlyBalance(monthlyBalance);
  }

  // Switch to different month
  Future<void> switchToMonth(String monthYear) async {
    _isLoading = true;
    notifyListeners();

    _currentMonthYear = monthYear;
    await _loadCurrentMonthData();

    _isLoading = false;
    notifyListeners();
  }

  // Add transaction
  Future<bool> addTransaction(Transaction transaction) async {
    try {
      // Validate category exists
      if (!_categories.any((cat) => cat.name == transaction.category)) {
        return false;
      }

      await _databaseHelper.insertTransaction(transaction);
      await _loadCurrentMonthData();
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Update transaction
  Future<bool> updateTransaction(Transaction transaction) async {
    try {
      await _databaseHelper.updateTransaction(transaction);
      await _loadCurrentMonthData();
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Delete transaction
  Future<bool> deleteTransaction(int id) async {
    try {
      await _databaseHelper.deleteTransaction(id);
      await _loadCurrentMonthData();
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Add category
  Future<bool> addCategory(models.Category category) async {
    try {
      // Check if we can add more custom categories
      if (_getCustomCategoryCount() >= 5) {
        return false;
      }

      await _databaseHelper.insertCategory(category);
      await _loadCategories();
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Update category
  Future<bool> updateCategory(models.Category category) async {
    try {
      await _databaseHelper.updateCategory(category);
      await _loadCategories();
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Delete category
  Future<bool> deleteCategory(int id) async {
    try {
      // Check if it's a default category
      final category = _categories.firstWhere((cat) => cat.id == id);
      if (category.isDefault) {
        return false;
      }

      await _databaseHelper.deleteCategory(id);
      await _loadCategories();
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Set monthly balance
  Future<bool> setMonthlyBalance(double balance) async {
    try {
      final monthlyBalance = MonthlyBalance(
        monthYear: _currentMonthYear,
        initialBalance: balance,
        createdAt: DateTime.now(),
      );

      await _databaseHelper.insertMonthlyBalance(monthlyBalance);
      await _loadCurrentMonthData();
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Update monthly balance
  Future<bool> updateMonthlyBalance(double balance) async {
    try {
      if (_currentMonthlyBalance != null) {
        final updatedBalance = _currentMonthlyBalance!.copyWith(
          initialBalance: balance,
        );
        await _databaseHelper.updateMonthlyBalance(updatedBalance);
        await _loadCurrentMonthData();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Get current balance
  double getCurrentBalance() {
    if (_currentMonthlyBalance == null) return 0.0;
    return _currentMonthlyBalance!.initialBalance - getTotalExpenses();
  }

  // Get total expenses for current month
  double getTotalExpenses() {
    return _transactions.fold(
        0.0, (sum, transaction) => sum + transaction.amount);
  }

  // Get tiffin expenses for current month
  double getTiffinExpenses() {
    return _transactions
        .where((transaction) => transaction.isTiffin)
        .fold(0.0, (sum, transaction) => sum + transaction.amount);
  }

  // Get category expenses
  Map<String, double> getCategoryExpenses() {
    Map<String, double> categoryExpenses = {};
    for (var transaction in _transactions) {
      categoryExpenses[transaction.category] =
          (categoryExpenses[transaction.category] ?? 0.0) + transaction.amount;
    }
    return categoryExpenses;
  }

  // Get available months
  Future<List<String>> getAvailableMonths() async {
    return await _databaseHelper.getAvailableMonths();
  }

  // Helper methods
  bool _isDefaultCategory(String categoryName) {
    return _categories.any((cat) => cat.name == categoryName && cat.isDefault);
  }

  int _getCustomCategoryCount() {
    return _categories.where((cat) => !cat.isDefault).length;
  }

  // Get transactions for a specific day
  List<Transaction> getTransactionsForDay(DateTime date) {
    return _transactions.where((transaction) {
      return transaction.dateTime.year == date.year &&
          transaction.dateTime.month == date.month &&
          transaction.dateTime.day == date.day;
    }).toList();
  }

  // Get daily tiffin amount
  double getTiffinForDay(DateTime date) {
    return getTransactionsForDay(date)
        .where((transaction) => transaction.isTiffin)
        .fold(0.0, (sum, transaction) => sum + transaction.amount);
  }
}
