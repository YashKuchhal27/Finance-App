import 'dart:async';
import 'package:sqflite/sqflite.dart' as sqlite;
import 'package:path/path.dart';
import '../models/transaction.dart' as models;
import '../models/category.dart';
import '../models/monthly_balance.dart';
import '../utils/security_helper.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static sqlite.Database? _database;

  Future<sqlite.Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<sqlite.Database> _initDatabase() async {
    String path = join(await sqlite.getDatabasesPath(), 'expense_tracker.db');
    return await sqlite.openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(sqlite.Database db, int version) async {
    // Create transactions table
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        dateTime INTEGER NOT NULL,
        isTiffin INTEGER NOT NULL DEFAULT 0,
        monthYear TEXT NOT NULL,
        receiptPath TEXT
      )
    ''');

    // Create categories table
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        isDefault INTEGER NOT NULL DEFAULT 0,
        color TEXT NOT NULL DEFAULT '#2196F3'
      )
    ''');

    // Create monthly_balances table
    await db.execute('''
      CREATE TABLE monthly_balances(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        monthYear TEXT NOT NULL UNIQUE,
        initialBalance REAL NOT NULL,
        createdAt INTEGER NOT NULL
      )
    ''');

    // Create budgets table
    await db.execute('''
      CREATE TABLE budgets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        monthYear TEXT NOT NULL UNIQUE,
        totalLimit REAL NOT NULL,
        rolloverEnabled INTEGER NOT NULL DEFAULT 1,
        createdAt INTEGER NOT NULL
      )
    ''');

    // Create recurring_transactions table
    await db.execute('''
      CREATE TABLE recurring_transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        isTiffin INTEGER NOT NULL DEFAULT 0,
        frequency TEXT NOT NULL,          -- daily | weekly | monthly
        dayOfMonth INTEGER,               -- for monthly
        weekday INTEGER,                  -- for weekly (1-7 Mon-Sun)
        nextRunAt INTEGER NOT NULL        -- ms epoch
      )
    ''');

    // Insert default categories
    await _insertDefaultCategories(db);
  }

  Future<void> _onUpgrade(
      sqlite.Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add receiptPath to transactions if not exists
      await db.execute('ALTER TABLE transactions ADD COLUMN receiptPath TEXT');
      // Create budgets table if not exists
      await db.execute('''
        CREATE TABLE IF NOT EXISTS budgets(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          monthYear TEXT NOT NULL UNIQUE,
          totalLimit REAL NOT NULL,
          rolloverEnabled INTEGER NOT NULL DEFAULT 1,
          createdAt INTEGER NOT NULL
        )
      ''');
      // Create recurring_transactions table if not exists
      await db.execute('''
        CREATE TABLE IF NOT EXISTS recurring_transactions(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          amount REAL NOT NULL,
          category TEXT NOT NULL,
          isTiffin INTEGER NOT NULL DEFAULT 0,
          frequency TEXT NOT NULL,
          dayOfMonth INTEGER,
          weekday INTEGER,
          nextRunAt INTEGER NOT NULL
        )
      ''');
    }
  }

  Future<void> _insertDefaultCategories(sqlite.Database db) async {
    final defaultCategories = [
      {'name': 'Travel', 'isDefault': 1, 'color': '#FF5722'},
      {'name': 'Food', 'isDefault': 1, 'color': '#4CAF50'},
      {'name': 'Misc', 'isDefault': 1, 'color': '#9C27B0'},
    ];

    for (var category in defaultCategories) {
      await db.insert('categories', category);
    }
  }

  // Transaction CRUD operations
  Future<int> insertTransaction(models.Transaction transaction) async {
    final db = await database;
    // Encrypt sensitive fields (name) before insert
    final map = transaction.toMap();
    final encryptedName =
        await SecurityHelper.encryptData(map['name'] as String);
    map['name'] = encryptedName;
    return await db.insert('transactions', map);
  }

  Future<List<models.Transaction>> getTransactions(String monthYear) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'monthYear = ?',
      whereArgs: [monthYear],
      orderBy: 'dateTime DESC',
    );
    // Decrypt names after fetch
    final List<Map<String, dynamic>> decrypted = [];
    for (final row in maps) {
      final copy = Map<String, dynamic>.from(row);
      final encName = copy['name'] as String;
      final decName = await SecurityHelper.decryptData(encName);
      copy['name'] = decName;
      decrypted.add(copy);
    }
    return List.generate(
        decrypted.length, (i) => models.Transaction.fromMap(decrypted[i]));
  }

  Future<List<models.Transaction>> getAllTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      orderBy: 'dateTime DESC',
    );
    final List<Map<String, dynamic>> decrypted = [];
    for (final row in maps) {
      final copy = Map<String, dynamic>.from(row);
      final encName = copy['name'] as String;
      final decName = await SecurityHelper.decryptData(encName);
      copy['name'] = decName;
      decrypted.add(copy);
    }
    return List.generate(
        decrypted.length, (i) => models.Transaction.fromMap(decrypted[i]));
  }

  Future<int> updateTransaction(models.Transaction transaction) async {
    final db = await database;
    // Encrypt name before update
    final map = transaction.toMap();
    final encryptedName =
        await SecurityHelper.encryptData(map['name'] as String);
    map['name'] = encryptedName;
    return await db.update(
      'transactions',
      map,
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Category CRUD operations
  Future<int> insertCategory(Category category) async {
    final db = await database;
    return await db.insert('categories', category.toMap());
  }

  Future<List<Category>> getCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      orderBy: 'isDefault DESC, name ASC',
    );
    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
  }

  Future<int> updateCategory(Category category) async {
    final db = await database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Monthly Balance operations
  Future<int> insertMonthlyBalance(MonthlyBalance monthlyBalance) async {
    final db = await database;
    return await db.insert('monthly_balances', monthlyBalance.toMap());
  }

  Future<MonthlyBalance?> getMonthlyBalance(String monthYear) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'monthly_balances',
      where: 'monthYear = ?',
      whereArgs: [monthYear],
    );
    if (maps.isNotEmpty) {
      return MonthlyBalance.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateMonthlyBalance(MonthlyBalance monthlyBalance) async {
    final db = await database;
    return await db.update(
      'monthly_balances',
      monthlyBalance.toMap(),
      where: 'monthYear = ?',
      whereArgs: [monthlyBalance.monthYear],
    );
  }

  // Utility methods
  Future<double> getTotalExpenses(String monthYear) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE monthYear = ?',
      [monthYear],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTiffinExpenses(String monthYear) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE monthYear = ? AND isTiffin = 1',
      [monthYear],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<Map<String, double>> getCategoryExpenses(String monthYear) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT category, SUM(amount) as total FROM transactions WHERE monthYear = ? GROUP BY category',
      [monthYear],
    );

    Map<String, double> categoryExpenses = {};
    for (var row in result) {
      categoryExpenses[row['category'] as String] =
          (row['total'] as num).toDouble();
    }
    return categoryExpenses;
  }

  Future<List<String>> getAvailableMonths() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT monthYear FROM (\n         SELECT DISTINCT monthYear FROM transactions\n         UNION\n         SELECT DISTINCT monthYear FROM monthly_balances\n       ) ORDER BY monthYear DESC',
    );
    return result.map((row) => row['monthYear'] as String).toList();
  }

  // Budgets CRUD
  Future<int> upsertBudget(Map<String, dynamic> budgetMap) async {
    final db = await database;
    return await db.insert('budgets', budgetMap,
        conflictAlgorithm: sqlite.ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getBudgetRaw(String monthYear) async {
    final db = await database;
    final res = await db.query('budgets',
        where: 'monthYear = ?', whereArgs: [monthYear], limit: 1);
    if (res.isEmpty) return null;
    return res.first;
  }

  Future<int> deleteBudget(String monthYear) async {
    final db = await database;
    return await db
        .delete('budgets', where: 'monthYear = ?', whereArgs: [monthYear]);
  }

  // Recurring transactions CRUD
  Future<int> insertRecurring(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('recurring_transactions', data);
  }

  Future<List<Map<String, dynamic>>> getRecurringAll() async {
    final db = await database;
    return await db.query('recurring_transactions');
  }

  Future<int> updateRecurring(Map<String, dynamic> data, int id) async {
    final db = await database;
    return await db.update('recurring_transactions', data,
        where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteRecurring(int id) async {
    final db = await database;
    return await db
        .delete('recurring_transactions', where: 'id = ?', whereArgs: [id]);
  }
}
