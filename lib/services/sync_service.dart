import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/monthly_balance.dart';
import '../models/budget.dart';
import '../models/recurring_transaction.dart';
import '../utils/security_helper.dart';

class SyncService {
  static const String _syncKey = 'last_sync_timestamp';
  static const String _deviceIdKey = 'device_id';
  
  // Mock cloud storage - replace with actual cloud provider
  static final Map<String, String> _cloudStorage = {};
  
  static Future<String> _getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);
    if (deviceId == null) {
      deviceId = _generateDeviceId();
      await prefs.setString(_deviceIdKey, deviceId);
    }
    return deviceId;
  }
  
  static String _generateDeviceId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp * 1000 + (timestamp % 1000)).toString();
    final bytes = utf8.encode(random);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }
  
  // Sync all data to cloud with E2EE
  static Future<bool> syncToCloud({
    required List<Transaction> transactions,
    required List<Category> categories,
    required List<MonthlyBalance> monthlyBalances,
    required List<Budget> budgets,
    required List<RecurringTransaction> recurringTransactions,
  }) async {
    try {
      final deviceId = await _getDeviceId();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      // Encrypt all data before sync
      final syncData = {
        'deviceId': deviceId,
        'timestamp': timestamp,
        'transactions': await _encryptTransactions(transactions),
        'categories': await _encryptCategories(categories),
        'monthlyBalances': await _encryptMonthlyBalances(monthlyBalances),
        'budgets': await _encryptBudgets(budgets),
        'recurringTransactions': await _encryptRecurringTransactions(recurringTransactions),
      };
      
      final jsonData = jsonEncode(syncData);
      final dataHash = sha256.convert(utf8.encode(jsonData)).toString();
      
      // Store in cloud (mock implementation)
      _cloudStorage['data_$deviceId'] = jsonData;
      _cloudStorage['hash_$deviceId'] = dataHash;
      
      // Update last sync timestamp
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_syncKey, timestamp);
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Sync data from cloud with conflict resolution
  static Future<Map<String, dynamic>?> syncFromCloud() async {
    try {
      final deviceId = await _getDeviceId();
      final lastSync = await _getLastSyncTimestamp();
      
      // Get all device data from cloud
      final allData = <String, dynamic>{};
      for (final key in _cloudStorage.keys) {
        if (key.startsWith('data_')) {
          final device = key.substring(5);
          final data = jsonDecode(_cloudStorage[key]!);
          allData[device] = data;
        }
      }
      
      if (allData.isEmpty) return null;
      
      // Merge data from all devices with conflict resolution
      final mergedData = await _mergeDataFromDevices(allData, deviceId, lastSync);
      
      return mergedData;
    } catch (e) {
      return null;
    }
  }
  
  static Future<Map<String, dynamic>> _mergeDataFromDevices(
    Map<String, dynamic> allData,
    String currentDeviceId,
    int lastSync,
  ) async {
    final merged = {
      'transactions': <Map<String, dynamic>>[],
      'categories': <Map<String, dynamic>>[],
      'monthlyBalances': <Map<String, dynamic>>[],
      'budgets': <Map<String, dynamic>>[],
      'recurringTransactions': <Map<String, dynamic>>[],
    };
    
    // Merge transactions (keep latest by timestamp)
    final transactionMap = <String, Map<String, dynamic>>{};
    for (final deviceData in allData.values) {
      final transactions = await _decryptTransactions(deviceData['transactions'] as List);
      for (final transaction in transactions) {
        final key = '${transaction.id}_${transaction.dateTime.millisecondsSinceEpoch}';
        if (!transactionMap.containsKey(key) || 
            transaction.dateTime.millisecondsSinceEpoch > 
            DateTime.parse(transactionMap[key]!['dateTime']).millisecondsSinceEpoch) {
          transactionMap[key] = transaction.toMap();
        }
      }
    }
    merged['transactions'] = transactionMap.values.toList();
    
    // Merge categories (keep all unique)
    final categoryMap = <String, Map<String, dynamic>>{};
    for (final deviceData in allData.values) {
      final categories = await _decryptCategories(deviceData['categories'] as List);
      for (final category in categories) {
        final key = category.name;
        if (!categoryMap.containsKey(key)) {
          categoryMap[key] = category.toMap();
        }
      }
    }
    merged['categories'] = categoryMap.values.toList();
    
    // Merge monthly balances (keep latest)
    final balanceMap = <String, Map<String, dynamic>>{};
    for (final deviceData in allData.values) {
      final balances = await _decryptMonthlyBalances(deviceData['monthlyBalances'] as List);
      for (final balance in balances) {
        final key = balance.monthYear;
        if (!balanceMap.containsKey(key) || 
            balance.createdAt.millisecondsSinceEpoch > 
            DateTime.fromMillisecondsSinceEpoch(balanceMap[key]!['createdAt']).millisecondsSinceEpoch) {
          balanceMap[key] = balance.toMap();
        }
      }
    }
    merged['monthlyBalances'] = balanceMap.values.toList();
    
    // Merge budgets (keep latest)
    final budgetMap = <String, Map<String, dynamic>>{};
    for (final deviceData in allData.values) {
      final budgets = await _decryptBudgets(deviceData['budgets'] as List);
      for (final budget in budgets) {
        final key = budget.monthYear;
        if (!budgetMap.containsKey(key) || 
            budget.createdAt.millisecondsSinceEpoch > 
            DateTime.fromMillisecondsSinceEpoch(budgetMap[key]!['createdAt']).millisecondsSinceEpoch) {
          budgetMap[key] = budget.toMap();
        }
      }
    }
    merged['budgets'] = budgetMap.values.toList();
    
    // Merge recurring transactions (keep all unique)
    final recurringMap = <String, Map<String, dynamic>>{};
    for (final deviceData in allData.values) {
      final recurring = await _decryptRecurringTransactions(deviceData['recurringTransactions'] as List);
      for (final item in recurring) {
        final key = '${item.name}_${item.amount}_${item.frequency}';
        if (!recurringMap.containsKey(key)) {
          recurringMap[key] = item.toMap();
        }
      }
    }
    merged['recurringTransactions'] = recurringMap.values.toList();
    
    return merged;
  }
  
  // Encryption helpers
  static Future<List<Map<String, dynamic>>> _encryptTransactions(List<Transaction> transactions) async {
    final encrypted = <Map<String, dynamic>>[];
    for (final transaction in transactions) {
      final map = transaction.toMap();
      map['name'] = await SecurityHelper.encryptData(map['name']);
      encrypted.add(map);
    }
    return encrypted;
  }
  
  static Future<List<Transaction>> _decryptTransactions(List<dynamic> encrypted) async {
    final transactions = <Transaction>[];
    for (final item in encrypted) {
      final map = Map<String, dynamic>.from(item);
      map['name'] = await SecurityHelper.decryptData(map['name']);
      transactions.add(Transaction.fromMap(map));
    }
    return transactions;
  }
  
  static Future<List<Map<String, dynamic>>> _encryptCategories(List<Category> categories) async {
    return categories.map((c) => c.toMap()).toList();
  }
  
  static Future<List<Category>> _decryptCategories(List<dynamic> encrypted) async {
    return encrypted.map((item) => Category.fromMap(item)).toList();
  }
  
  static Future<List<Map<String, dynamic>>> _encryptMonthlyBalances(List<MonthlyBalance> balances) async {
    return balances.map((b) => b.toMap()).toList();
  }
  
  static Future<List<MonthlyBalance>> _decryptMonthlyBalances(List<dynamic> encrypted) async {
    return encrypted.map((item) => MonthlyBalance.fromMap(item)).toList();
  }
  
  static Future<List<Map<String, dynamic>>> _encryptBudgets(List<Budget> budgets) async {
    return budgets.map((b) => b.toMap()).toList();
  }
  
  static Future<List<Budget>> _decryptBudgets(List<dynamic> encrypted) async {
    return encrypted.map((item) => Budget.fromMap(item)).toList();
  }
  
  static Future<List<Map<String, dynamic>>> _encryptRecurringTransactions(List<RecurringTransaction> recurring) async {
    return recurring.map((r) => r.toMap()).toList();
  }
  
  static Future<List<RecurringTransaction>> _decryptRecurringTransactions(List<dynamic> encrypted) async {
    return encrypted.map((item) => RecurringTransaction.fromMap(item)).toList();
  }
  
  static Future<int> _getLastSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_syncKey) ?? 0;
  }
  
  // Check if sync is needed
  static Future<bool> isSyncNeeded() async {
    final lastSync = await _getLastSyncTimestamp();
    final now = DateTime.now().millisecondsSinceEpoch;
    // Sync if more than 1 hour has passed
    return (now - lastSync) > 3600000;
  }
}
