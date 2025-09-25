import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../models/transaction.dart';
import '../widgets/transaction_list_item.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  String _selectedFilter = 'All';
  String _selectedSort = 'Date (Newest)';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'All Transactions',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All', child: Text('All Transactions')),
              const PopupMenuItem(value: 'Tiffin', child: Text('Tiffin Only')),
              const PopupMenuItem(value: 'Today', child: Text('Today')),
              const PopupMenuItem(value: 'This Week', child: Text('This Week')),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.white),
            onSelected: (value) {
              setState(() {
                _selectedSort = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Date (Newest)', child: Text('Date (Newest)')),
              const PopupMenuItem(value: 'Date (Oldest)', child: Text('Date (Oldest)')),
              const PopupMenuItem(value: 'Amount (High)', child: Text('Amount (High to Low)')),
              const PopupMenuItem(value: 'Amount (Low)', child: Text('Amount (Low to High)')),
              const PopupMenuItem(value: 'Category', child: Text('Category')),
            ],
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

          final filteredTransactions = _getFilteredTransactions(expenseProvider.transactions);
          final sortedTransactions = _getSortedTransactions(filteredTransactions);

          return Column(
            children: [
              // Summary Card
              _buildSummaryCard(expenseProvider, filteredTransactions),
              
              // Transaction List
              Expanded(
                child: filteredTransactions.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: sortedTransactions.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final transaction = sortedTransactions[index];
                          return TransactionListItem(
                            transaction: transaction,
                            onTap: () => _showTransactionDetails(transaction),
                            onEdit: () => _editTransaction(transaction, expenseProvider),
                            onDelete: () => _deleteTransaction(transaction, expenseProvider),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(ExpenseProvider expenseProvider, List<Transaction> transactions) {
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final totalAmount = transactions.fold(0.0, (sum, transaction) => sum + transaction.amount);
    final tiffinAmount = transactions
        .where((transaction) => transaction.isTiffin)
        .fold(0.0, (sum, transaction) => sum + transaction.amount);

    return Container(
      margin: const EdgeInsets.all(16),
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter: $_selectedFilter',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF666666),
                ),
              ),
              Text(
                '${transactions.length} transactions',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Total',
                  formatter.format(totalAmount),
                  const Color(0xFF2196F3),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryItem(
                  'Tiffin',
                  formatter.format(tiffinAmount),
                  const Color(0xFFFF9800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filter or add some transactions',
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

  List<Transaction> _getFilteredTransactions(List<Transaction> transactions) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: now.weekday - 1));

    switch (_selectedFilter) {
      case 'Tiffin':
        return transactions.where((t) => t.isTiffin).toList();
      case 'Today':
        return transactions.where((t) {
          final transactionDate = DateTime(t.dateTime.year, t.dateTime.month, t.dateTime.day);
          return transactionDate.isAtSameMomentAs(today);
        }).toList();
      case 'This Week':
        return transactions.where((t) {
          final transactionDate = DateTime(t.dateTime.year, t.dateTime.month, t.dateTime.day);
          return transactionDate.isAfter(weekStart.subtract(const Duration(days: 1)));
        }).toList();
      default:
        return transactions;
    }
  }

  List<Transaction> _getSortedTransactions(List<Transaction> transactions) {
    switch (_selectedSort) {
      case 'Date (Oldest)':
        return List.from(transactions)..sort((a, b) => a.dateTime.compareTo(b.dateTime));
      case 'Amount (High)':
        return List.from(transactions)..sort((a, b) => b.amount.compareTo(a.amount));
      case 'Amount (Low)':
        return List.from(transactions)..sort((a, b) => a.amount.compareTo(b.amount));
      case 'Category':
        return List.from(transactions)..sort((a, b) => a.category.compareTo(b.category));
      default: // Date (Newest)
        return List.from(transactions)..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    }
  }

  void _showTransactionDetails(Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(transaction.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Amount', '₹${transaction.amount.toStringAsFixed(2)}'),
            _buildDetailRow('Category', transaction.category),
            _buildDetailRow('Date', DateFormat('MMM dd, yyyy').format(transaction.dateTime)),
            _buildDetailRow('Time', DateFormat('hh:mm a').format(transaction.dateTime)),
            if (transaction.isTiffin)
              _buildDetailRow('Type', 'Tiffin', const Color(0xFFFF9800)),
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

  Widget _buildDetailRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF666666),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: valueColor ?? const Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editTransaction(Transaction transaction, ExpenseProvider expenseProvider) {
    // Navigate to edit screen (you can implement this)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit functionality coming soon'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _deleteTransaction(Transaction transaction, ExpenseProvider expenseProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text('Are you sure you want to delete "${transaction.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await expenseProvider.deleteTransaction(transaction.id!);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Transaction deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to delete transaction'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}


