import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../models/category.dart' as models;
import '../models/monthly_balance.dart';
import '../database/database_helper.dart';
import '../models/budget.dart';
import '../models/recurring_transaction.dart';
import '../models/shared_budget.dart';
import '../models/rule.dart';
import '../services/sync_service.dart';
import '../services/ml_service.dart';

class ExpenseProvider with ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  List<Transaction> _transactions = [];
  List<models.Category> _categories = [];
  MonthlyBalance? _currentMonthlyBalance;
  String _currentMonthYear = '';
  bool _isLoading = false;
  Budget? _currentBudget;
  List<RecurringTransaction> _recurringTransactions = [];
  List<SharedBudget> _sharedBudgets = [];
  List<Rule> _rules = [];
  List<ActivityFeedItem> _activityFeed = [];

  // Getters
  List<Transaction> get transactions => _transactions;
  List<models.Category> get categories => _categories;
  MonthlyBalance? get currentMonthlyBalance => _currentMonthlyBalance;
  String get currentMonthYear => _currentMonthYear;
  bool get isLoading => _isLoading;
  Budget? get currentBudget => _currentBudget;
  List<RecurringTransaction> get recurringTransactions =>
      _recurringTransactions;
  List<SharedBudget> get sharedBudgets => _sharedBudgets;
  List<Rule> get rules => _rules;
  List<ActivityFeedItem> get activityFeed => _activityFeed;

  // Initialize the provider
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    await _loadCategories();
    await _setCurrentMonth();
    await _ensureCurrentMonthBalance();
    await _loadCurrentMonthData();
    await _loadBudget();
    await _loadRecurringTransactions();
    await _processRecurringTransactions();
    await _loadSharedBudgets();
    await _loadRules();
    await _loadActivityFeed();
    await _syncWithCloud();

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

  Future<void> _loadBudget() async {
    final raw = await _databaseHelper.getBudgetRaw(_currentMonthYear);
    if (raw != null) {
      _currentBudget = Budget.fromMap(raw);
    } else {
      _currentBudget = null;
    }
  }

  Future<void> _loadRecurringTransactions() async {
    final rawList = await _databaseHelper.getRecurringAll();
    _recurringTransactions =
        rawList.map((map) => RecurringTransaction.fromMap(map)).toList();
  }

  Future<void> _processRecurringTransactions() async {
    final now = DateTime.now();
    final currentMonthYear =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';

    for (final recurring in _recurringTransactions) {
      if (recurring.nextRunAt.isBefore(now) ||
          recurring.nextRunAt.isAtSameMomentAs(now)) {
        // Create transaction for this month
        final transaction = Transaction(
          name: recurring.name,
          amount: recurring.amount,
          category: recurring.category,
          dateTime: recurring.nextRunAt,
          isTiffin: recurring.isTiffin,
          monthYear: currentMonthYear,
        );

        await addTransaction(transaction);

        // Update next run date
        final updatedRecurring =
            recurring.copyWith(nextRunAt: recurring.calculateNextRun());
        await _databaseHelper.updateRecurring(
            updatedRecurring.toMap(), recurring.id!);
      }
    }

    // Reload recurring transactions to get updated next run dates
    await _loadRecurringTransactions();
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
    await _loadBudget();
    await _loadRecurringTransactions();

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

  // Budgets API
  Future<void> upsertBudget(
      {required double totalLimit, bool rolloverEnabled = true}) async {
    final budget = Budget(
      monthYear: _currentMonthYear,
      totalLimit: totalLimit,
      rolloverEnabled: rolloverEnabled,
      createdAt: DateTime.now(),
    );
    await _databaseHelper.upsertBudget(budget.toMap());
    await _loadBudget();
    notifyListeners();
  }

  double getSafeToSpend() {
    final totalLimit = _currentBudget?.totalLimit;
    if (totalLimit == null) return getCurrentBalance();
    final remainingBudget = totalLimit - getTotalExpenses();
    // Safe-to-spend is the min of cash balance and remaining budget
    final cash = getCurrentBalance();
    return remainingBudget < cash ? remainingBudget : cash;
  }

  bool isBudgetAlertThreshold(double thresholdPercent) {
    if (_currentBudget == null || _currentBudget!.totalLimit <= 0) return false;
    final used = getTotalExpenses() / _currentBudget!.totalLimit * 100.0;
    return used >= thresholdPercent;
  }

  // Budget management methods
  Future<bool> insertBudget(Budget budget) async {
    try {
      await _databaseHelper.insertBudget(budget);
      await _loadBudget();
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  double getRemainingBudget() {
    if (_currentBudget == null) return 0.0;
    return _currentBudget!.totalLimit - getTotalExpenses();
  }

  // Recurring transactions API
  Future<bool> addRecurringTransaction(RecurringTransaction recurring) async {
    try {
      await _databaseHelper.insertRecurring(recurring.toMap());
      await _loadRecurringTransactions();
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateRecurringTransaction(
      RecurringTransaction recurring) async {
    try {
      await _databaseHelper.updateRecurring(recurring.toMap(), recurring.id!);
      await _loadRecurringTransactions();
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteRecurringTransaction(int id) async {
    try {
      await _databaseHelper.deleteRecurring(id);
      await _loadRecurringTransactions();
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Phase 2: Cloud Sync, Shared Budgets, Rules, ML
  Future<void> _loadSharedBudgets() async {
    _sharedBudgets = await _databaseHelper.getSharedBudgets();
  }

  Future<void> _loadRules() async {
    _rules = await _databaseHelper.getRules();
    RuleEngine.loadRules(_rules);
  }

  Future<void> _loadActivityFeed() async {
    // Load activity feed for current month's shared budgets
    _activityFeed = [];
    for (final budget in _sharedBudgets) {
      if (budget.monthYear == _currentMonthYear) {
        final feed =
            await _databaseHelper.getActivityFeed(budget.id.toString());
        _activityFeed.addAll(feed);
      }
    }
    _activityFeed.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> _syncWithCloud() async {
    if (await SyncService.isSyncNeeded()) {
      try {
        // Sync to cloud
        await SyncService.syncToCloud(
          transactions: _transactions,
          categories: _categories,
          monthlyBalances:
              _currentMonthlyBalance != null ? [_currentMonthlyBalance!] : [],
          budgets: _currentBudget != null ? [_currentBudget!] : [],
          recurringTransactions: _recurringTransactions,
        );

        // Sync from cloud
        final cloudData = await SyncService.syncFromCloud();
        if (cloudData != null) {
          // Apply cloud data with conflict resolution
          await _applyCloudData(cloudData);
        }
      } catch (e) {
        // Sync failed, continue with local data
      }
    }
  }

  Future<void> _applyCloudData(Map<String, dynamic> cloudData) async {
    // This would merge cloud data with local data
    // For now, just reload local data
    await _loadCurrentMonthData();
    await _loadBudget();
    await _loadRecurringTransactions();
  }

  // ML Auto-categorization
  String suggestCategory(Transaction transaction) {
    return MLService.suggestCategory(transaction, _categories);
  }

  List<Anomaly> detectAnomalies() {
    return MLService.detectAnomalies(_transactions);
  }

  MonthlyInsights generateMonthlyInsights() {
    final previousMonth = DateTime.now().subtract(const Duration(days: 30));
    final previousMonthYear =
        '${previousMonth.year}-${previousMonth.month.toString().padLeft(2, '0')}';
    final previousTransactions =
        _transactions.where((t) => t.monthYear == previousMonthYear).toList();

    return MLService.generateMonthlyInsights(
      _transactions,
      _currentMonthlyBalance?.initialBalance ?? 0.0,
      previousTransactions,
    );
  }

  // Rules Engine
  Future<bool> addRule(Rule rule) async {
    try {
      await _databaseHelper.insertRule(rule);
      await _loadRules();
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateRule(Rule rule) async {
    try {
      await _databaseHelper.updateRule(rule);
      await _loadRules();
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteRule(int id) async {
    try {
      await _databaseHelper.deleteRule(id);
      await _loadRules();
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Apply rules to a transaction before adding
  Transaction applyRules(Transaction transaction) {
    final transactionData = transaction.toMap();
    final processedData = RuleEngine.processTransaction(transactionData);
    return Transaction.fromMap(processedData);
  }

  // Shared Budgets
  Future<bool> createSharedBudget({
    required String name,
    required double totalLimit,
    required String ownerId,
    required List<String> memberIds,
  }) async {
    try {
      final sharedBudget = SharedBudget(
        name: name,
        monthYear: _currentMonthYear,
        totalLimit: totalLimit,
        ownerId: ownerId,
        memberIds: memberIds,
        roles: {ownerId: 'owner'}..addAll(
            Map.fromEntries(memberIds.map((id) => MapEntry(id, 'member')))),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _databaseHelper.insertSharedBudget(sharedBudget);
      await _loadSharedBudgets();
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addActivityFeedItem({
    required String sharedBudgetId,
    required String userId,
    required String action,
    required String description,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      final item = ActivityFeedItem(
        sharedBudgetId: sharedBudgetId,
        userId: userId,
        action: action,
        description: description,
        metadata: metadata,
        timestamp: DateTime.now(),
      );

      await _databaseHelper.insertActivityFeedItem(item);
      await _loadActivityFeed();
      notifyListeners();
      return true;
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
