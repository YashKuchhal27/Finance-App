import '../models/transaction.dart';
import '../models/category.dart';

class MLService {
  // Simple ML-based categorization using pattern matching and frequency analysis
  static final Map<String, Map<String, double>> _categoryPatterns = {
    'Food': {
      'restaurant': 0.9,
      'cafe': 0.8,
      'coffee': 0.7,
      'pizza': 0.8,
      'burger': 0.8,
      'food': 0.6,
      'lunch': 0.7,
      'dinner': 0.7,
      'breakfast': 0.7,
      'tiffin': 0.9,
      'meal': 0.6,
      'starbucks': 0.8,
      'mcdonalds': 0.8,
      'kfc': 0.8,
      'dominos': 0.8,
    },
    'Travel': {
      'uber': 0.9,
      'ola': 0.9,
      'taxi': 0.8,
      'metro': 0.7,
      'bus': 0.7,
      'train': 0.7,
      'flight': 0.9,
      'fuel': 0.8,
      'petrol': 0.8,
      'parking': 0.6,
      'toll': 0.7,
      'travel': 0.6,
      'transport': 0.6,
    },
    'Misc': {
      'shopping': 0.6,
      'store': 0.5,
      'market': 0.5,
      'pharmacy': 0.7,
      'medical': 0.7,
      'hospital': 0.8,
      'clinic': 0.7,
      'medicine': 0.7,
      'entertainment': 0.6,
      'movie': 0.7,
      'cinema': 0.7,
      'game': 0.6,
      'subscription': 0.5,
      'netflix': 0.8,
      'spotify': 0.8,
    },
  };

  // Suggest category for a transaction
  static String suggestCategory(Transaction transaction, List<Category> availableCategories) {
    final merchant = transaction.name.toLowerCase();
    final amount = transaction.amount;
    
    // Calculate confidence scores for each category
    final scores = <String, double>{};
    
    for (final category in availableCategories) {
      scores[category.name] = _calculateCategoryScore(merchant, amount, category.name);
    }
    
    // Find the category with highest score
    if (scores.isEmpty) return 'Misc';
    
    final bestCategory = scores.entries
        .reduce((a, b) => a.value > b.value ? a : b);
    
    // Only suggest if confidence is above threshold
    return bestCategory.value > 0.3 ? bestCategory.key : 'Misc';
  }

  // Calculate confidence score for a category
  static double _calculateCategoryScore(String merchant, double amount, String category) {
    final patterns = _categoryPatterns[category] ?? {};
    double score = 0.0;
    
    // Pattern matching score
    for (final entry in patterns.entries) {
      if (merchant.contains(entry.key)) {
        score += entry.value;
      }
    }
    
    // Amount-based adjustments
    if (category == 'Food') {
      if (amount < 50) score += 0.2; // Small amounts often food
      if (amount > 1000) score -= 0.1; // Large amounts less likely food
    } else if (category == 'Travel') {
      if (amount > 100) score += 0.1; // Travel often costs more
    }
    
    // Normalize score
    return (score / patterns.length).clamp(0.0, 1.0);
  }

  // Detect anomalies in spending patterns
  static List<Anomaly> detectAnomalies(List<Transaction> transactions) {
    final anomalies = <Anomaly>[];
    
    if (transactions.length < 3) return anomalies;
    
    // Calculate daily spending patterns
    final dailySpending = <DateTime, double>{};
    for (final transaction in transactions) {
      final day = DateTime(transaction.dateTime.year, transaction.dateTime.month, transaction.dateTime.day);
      dailySpending[day] = (dailySpending[day] ?? 0.0) + transaction.amount;
    }
    
    // Find spending spikes
    final amounts = dailySpending.values.toList()..sort();
    if (amounts.length >= 3) {
      final q3 = amounts[(amounts.length * 0.75).floor()];
      final iqr = q3 - amounts[(amounts.length * 0.25).floor()];
      final threshold = q3 + (1.5 * iqr);
      
      for (final entry in dailySpending.entries) {
        if (entry.value > threshold) {
          anomalies.add(Anomaly(
            type: 'spending_spike',
            description: 'Unusual high spending on ${entry.key.day}/${entry.key.month}',
            severity: entry.value > threshold * 2 ? 'high' : 'medium',
            amount: entry.value,
            date: entry.key,
          ));
        }
      }
    }
    
    // Find unusual merchants
    final merchantCounts = <String, int>{};
    for (final transaction in transactions) {
      merchantCounts[transaction.name] = (merchantCounts[transaction.name] ?? 0) + 1;
    }
    
    final totalTransactions = transactions.length;
    for (final entry in merchantCounts.entries) {
      if (entry.value == 1 && totalTransactions > 10) {
        // Single transaction from a merchant (might be unusual)
        final transaction = transactions.firstWhere((t) => t.name == entry.key);
        if (transaction.amount > 500) { // Only flag if amount is significant
          anomalies.add(Anomaly(
            type: 'unusual_merchant',
            description: 'Single large transaction from ${entry.key}',
            severity: 'low',
            amount: transaction.amount,
            date: transaction.dateTime,
          ));
        }
      }
    }
    
    return anomalies;
  }

  // Generate monthly insights
  static MonthlyInsights generateMonthlyInsights(
    List<Transaction> transactions,
    double initialBalance,
    List<Transaction> previousMonthTransactions,
  ) {
    final totalSpent = transactions.fold(0.0, (sum, t) => sum + t.amount);
    final remainingBalance = initialBalance - totalSpent;
    
    // Category breakdown
    final categorySpending = <String, double>{};
    for (final transaction in transactions) {
      categorySpending[transaction.category] = 
          (categorySpending[transaction.category] ?? 0.0) + transaction.amount;
    }
    
    // Top spending category
    final topCategory = categorySpending.entries.isNotEmpty
        ? categorySpending.entries.reduce((a, b) => a.value > b.value ? a : b)
        : null;
    
    // Compare with previous month
    final previousTotal = previousMonthTransactions.fold(0.0, (sum, t) => sum + t.amount);
    final spendingChange = previousTotal > 0 ? ((totalSpent - previousTotal) / previousTotal) * 100 : 0.0;
    
    // Daily average
    final daysInMonth = DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day;
    final dailyAverage = totalSpent / daysInMonth;
    
    // Tiffin analysis
    final tiffinTransactions = transactions.where((t) => t.isTiffin).toList();
    final tiffinSpent = tiffinTransactions.fold(0.0, (sum, t) => sum + t.amount);
    final tiffinDays = tiffinTransactions.map((t) => 
        DateTime(t.dateTime.year, t.dateTime.month, t.dateTime.day)).toSet().length;
    
    return MonthlyInsights(
      totalSpent: totalSpent,
      remainingBalance: remainingBalance,
      topCategory: topCategory?.key,
      topCategoryAmount: topCategory?.value ?? 0.0,
      spendingChange: spendingChange,
      dailyAverage: dailyAverage,
      tiffinSpent: tiffinSpent,
      tiffinDays: tiffinDays,
      transactionCount: transactions.length,
      categoryBreakdown: categorySpending,
    );
  }
}

class Anomaly {
  final String type;
  final String description;
  final String severity; // low, medium, high
  final double amount;
  final DateTime date;

  Anomaly({
    required this.type,
    required this.description,
    required this.severity,
    required this.amount,
    required this.date,
  });
}

class MonthlyInsights {
  final double totalSpent;
  final double remainingBalance;
  final String? topCategory;
  final double topCategoryAmount;
  final double spendingChange;
  final double dailyAverage;
  final double tiffinSpent;
  final int tiffinDays;
  final int transactionCount;
  final Map<String, double> categoryBreakdown;

  MonthlyInsights({
    required this.totalSpent,
    required this.remainingBalance,
    required this.topCategory,
    required this.topCategoryAmount,
    required this.spendingChange,
    required this.dailyAverage,
    required this.tiffinSpent,
    required this.tiffinDays,
    required this.transactionCount,
    required this.categoryBreakdown,
  });

  String getSummaryText() {
    final buffer = StringBuffer();
    
    buffer.writeln('Monthly Summary:');
    buffer.writeln('• Total spent: ₹${totalSpent.toStringAsFixed(2)}');
    buffer.writeln('• Remaining balance: ₹${remainingBalance.toStringAsFixed(2)}');
    buffer.writeln('• Daily average: ₹${dailyAverage.toStringAsFixed(2)}');
    
    if (topCategory != null) {
      buffer.writeln('• Top category: $topCategory (₹${topCategoryAmount.toStringAsFixed(2)})');
    }
    
    if (spendingChange != 0) {
      final changeText = spendingChange > 0 ? 'increased' : 'decreased';
      buffer.writeln('• Spending ${changeText} by ${spendingChange.abs().toStringAsFixed(1)}% from last month');
    }
    
    if (tiffinDays > 0) {
      buffer.writeln('• Tiffin: ₹${tiffinSpent.toStringAsFixed(2)} over $tiffinDays days');
    }
    
    return buffer.toString();
  }
}
