import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../widgets/monthly_summary_card.dart';
import '../widgets/category_breakdown_chart.dart';

class MonthlyViewScreen extends StatefulWidget {
  const MonthlyViewScreen({super.key});

  @override
  State<MonthlyViewScreen> createState() => _MonthlyViewScreenState();
}

class _MonthlyViewScreenState extends State<MonthlyViewScreen> {
  String _selectedMonth = '';
  List<String> _availableMonths = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableMonths();
  }

  Future<void> _loadAvailableMonths() async {
    final expenseProvider = context.read<ExpenseProvider>();
    final months = await expenseProvider.getAvailableMonths();
    
    if (mounted) {
      setState(() {
        _availableMonths = months;
        if (months.isNotEmpty && _selectedMonth.isEmpty) {
          _selectedMonth = months.first;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Monthly View',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        actions: [
          if (_availableMonths.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.calendar_month, color: Colors.white),
              onSelected: (value) {
                setState(() {
                  _selectedMonth = value;
                });
                context.read<ExpenseProvider>().switchToMonth(value);
              },
              itemBuilder: (context) => _availableMonths.map((month) {
                final date = DateTime.parse('${month}-01');
                final monthName = DateFormat('MMMM yyyy').format(date);
                return PopupMenuItem(
                  value: month,
                  child: Text(monthName),
                );
              }).toList(),
            ),
        ],
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, expenseProvider, child) {
          if (expenseProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
              ),
            );
          }

          if (_availableMonths.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              await _loadAvailableMonths();
              await expenseProvider.initialize();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Month Selector
                  _buildMonthSelector(),
                  const SizedBox(height: 16),

                  // Monthly Summary
                  MonthlySummaryCard(
                    monthYear: _selectedMonth,
                    initialBalance: expenseProvider.currentMonthlyBalance?.initialBalance ?? 0.0,
                    currentBalance: expenseProvider.getCurrentBalance(),
                    totalExpenses: expenseProvider.getTotalExpenses(),
                    tiffinExpenses: expenseProvider.getTiffinExpenses(),
                    transactionCount: expenseProvider.transactions.length,
                  ),
                  const SizedBox(height: 16),

                  // Category Breakdown
                  CategoryBreakdownChart(
                    categoryExpenses: expenseProvider.getCategoryExpenses(),
                    totalExpenses: expenseProvider.getTotalExpenses(),
                  ),
                  const SizedBox(height: 16),

                  // Daily Breakdown
                  _buildDailyBreakdown(expenseProvider),
                  const SizedBox(height: 16),

                  // Top Transactions
                  _buildTopTransactions(expenseProvider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Data Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some transactions to see monthly insights',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    if (_availableMonths.isEmpty) return const SizedBox.shrink();

    final date = DateTime.parse('${_selectedMonth}-01');
    final monthName = DateFormat('MMMM yyyy').format(date);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_month,
            color: Color(0xFF2196F3),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              monthName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
          ),
          Text(
            '${_availableMonths.length} months',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyBreakdown(ExpenseProvider expenseProvider) {
    final dailyExpenses = _getDailyExpenses(expenseProvider.transactions);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Breakdown',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),
          if (dailyExpenses.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No transactions for this month',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            ...dailyExpenses.entries.take(7).map((entry) {
              final date = entry.key;
              final amount = entry.value;
              final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          date.day.toString(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2196F3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE').format(date),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF333333),
                            ),
                          ),
                          Text(
                            DateFormat('MMM dd, yyyy').format(date),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatter.format(amount),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildTopTransactions(ExpenseProvider expenseProvider) {
    final topTransactions = expenseProvider.transactions
      ..sort((a, b) => b.amount.compareTo(a.amount));
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Transactions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),
          if (topTransactions.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No transactions for this month',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            ...topTransactions.take(5).map((transaction) {
              final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(transaction.category).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getCategoryIcon(transaction.category),
                        color: _getCategoryColor(transaction.category),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF333333),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${transaction.category} • ${DateFormat('MMM dd').format(transaction.dateTime)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatter.format(transaction.amount),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Map<DateTime, double> _getDailyExpenses(List transactions) {
    final Map<DateTime, double> dailyExpenses = {};
    
    for (var transaction in transactions) {
      final date = DateTime(transaction.dateTime.year, transaction.dateTime.month, transaction.dateTime.day);
      dailyExpenses[date] = (dailyExpenses[date] ?? 0.0) + transaction.amount;
    }
    
    return dailyExpenses;
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'travel':
        return const Color(0xFFFF5722);
      case 'food':
        return const Color(0xFF4CAF50);
      case 'misc':
        return const Color(0xFF9C27B0);
      default:
        return const Color(0xFF2196F3);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'travel':
        return Icons.directions_car;
      case 'food':
        return Icons.restaurant;
      case 'misc':
        return Icons.category;
      default:
        return Icons.shopping_cart;
    }
  }
}


