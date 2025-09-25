import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../widgets/balance_card.dart';
import '../widgets/quick_stats_card.dart';
import '../widgets/recent_transactions_list.dart';
import '../widgets/tiffin_tracker_card.dart';
import 'add_transaction_screen.dart';
import 'transaction_list_screen.dart';
import 'monthly_view_screen.dart';
import 'category_management_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Expense Tracker',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month, color: Colors.white),
            onPressed: () => _navigateToMonthlyView(),
          ),
          IconButton(
            icon: const Icon(Icons.category, color: Colors.white),
            onPressed: () => _navigateToCategoryManagement(),
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

          return RefreshIndicator(
            onRefresh: () async {
              await expenseProvider.initialize();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Month Header
                  _buildMonthHeader(expenseProvider.currentMonthYear),
                  const SizedBox(height: 16),
                  
                  // Balance Card
                  BalanceCard(
                    initialBalance: expenseProvider.currentMonthlyBalance?.initialBalance ?? 0.0,
                    currentBalance: expenseProvider.getCurrentBalance(),
                    onSetBalance: () => _showSetBalanceDialog(expenseProvider),
                  ),
                  const SizedBox(height: 16),
                  
                  // Quick Stats
                  QuickStatsCard(
                    totalExpenses: expenseProvider.getTotalExpenses(),
                    tiffinExpenses: expenseProvider.getTiffinExpenses(),
                    categoryExpenses: expenseProvider.getCategoryExpenses(),
                  ),
                  const SizedBox(height: 16),
                  
                  // Tiffin Tracker
                  TiffinTrackerCard(
                    todayTiffin: expenseProvider.getTiffinForDay(DateTime.now()),
                    monthlyTiffin: expenseProvider.getTiffinExpenses(),
                    onAddTiffin: () => _navigateToAddTransaction(isTiffin: true),
                  ),
                  const SizedBox(height: 16),
                  
                  // Recent Transactions Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Transactions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _navigateToTransactionList(),
                        child: const Text(
                          'View All',
                          style: TextStyle(
                            color: Color(0xFF2196F3),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Recent Transactions List
                  RecentTransactionsList(
                    transactions: expenseProvider.transactions.take(5).toList(),
                    onTransactionTap: (transaction) => _showTransactionDetails(transaction),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddTransaction(),
        backgroundColor: const Color(0xFF2196F3),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildMonthHeader(String monthYear) {
    final date = DateTime.parse('${monthYear}-01');
    final monthName = DateFormat('MMMM yyyy').format(date);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            Icons.calendar_today,
            color: Color(0xFF2196F3),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            monthName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToAddTransaction({bool isTiffin = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(isTiffin: isTiffin),
      ),
    );
  }

  void _navigateToTransactionList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TransactionListScreen(),
      ),
    );
  }

  void _navigateToMonthlyView() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MonthlyViewScreen(),
      ),
    );
  }

  void _navigateToCategoryManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CategoryManagementScreen(),
      ),
    );
  }

  void _showSetBalanceDialog(ExpenseProvider expenseProvider) {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Initial Balance'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Initial Balance',
            prefixText: '₹ ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final balance = double.tryParse(controller.text);
              if (balance != null && balance >= 0) {
                final success = expenseProvider.currentMonthlyBalance == null
                    ? await expenseProvider.setMonthlyBalance(balance)
                    : await expenseProvider.updateMonthlyBalance(balance);
                
                if (success) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Balance updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to update balance'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  void _showTransactionDetails(transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(transaction.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount: ₹${transaction.amount.toStringAsFixed(2)}'),
            Text('Category: ${transaction.category}'),
            Text('Date: ${DateFormat('MMM dd, yyyy').format(transaction.dateTime)}'),
            Text('Time: ${DateFormat('hh:mm a').format(transaction.dateTime)}'),
            if (transaction.isTiffin)
              const Text('Type: Tiffin', style: TextStyle(color: Colors.orange)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}


