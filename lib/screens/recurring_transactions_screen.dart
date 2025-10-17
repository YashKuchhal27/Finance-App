import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../models/recurring_transaction.dart';

class RecurringTransactionsScreen extends StatefulWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  State<RecurringTransactionsScreen> createState() => _RecurringTransactionsScreenState();
}

class _RecurringTransactionsScreenState extends State<RecurringTransactionsScreen> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedCategory = 'Food';
  String _selectedFrequency = 'monthly';
  int? _selectedDayOfMonth;
  int? _selectedWeekday;
  bool _isTiffin = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Transactions'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddRecurringDialog(),
          ),
        ],
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          final recurringTransactions = provider.recurringTransactions;

          if (recurringTransactions.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.repeat, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No recurring transactions',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap + to add your first recurring transaction',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: recurringTransactions.length,
            itemBuilder: (context, index) {
              final recurring = recurringTransactions[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _isTiffin ? Colors.orange : Colors.blue,
                    child: Icon(
                      _getFrequencyIcon(recurring.frequency),
                      color: Colors.white,
                    ),
                  ),
                  title: Text(recurring.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('₹${recurring.amount.toStringAsFixed(2)} - ${recurring.category}'),
                      Text('Next: ${_formatDate(recurring.nextRunAt)}'),
                      if (recurring.isTiffin) const Text('🍱 Tiffin', style: TextStyle(color: Colors.orange)),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditRecurringDialog(recurring);
                      } else if (value == 'delete') {
                        _showDeleteConfirmation(recurring.id!);
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddRecurringDialog() {
    _resetForm();
    showDialog(
      context: context,
      builder: (context) => _buildRecurringDialog(),
    );
  }

  void _showEditRecurringDialog(RecurringTransaction recurring) {
    _nameController.text = recurring.name;
    _amountController.text = recurring.amount.toString();
    _selectedCategory = recurring.category;
    _selectedFrequency = recurring.frequency;
    _selectedDayOfMonth = recurring.dayOfMonth;
    _selectedWeekday = recurring.weekday;
    _isTiffin = recurring.isTiffin;

    showDialog(
      context: context,
      builder: (context) => _buildRecurringDialog(recurring: recurring),
    );
  }

  Widget _buildRecurringDialog({RecurringTransaction? recurring}) {
    return AlertDialog(
      title: Text(recurring == null ? 'Add Recurring Transaction' : 'Edit Recurring Transaction'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (₹)',
                border: OutlineInputBorder(),
                prefixText: '₹',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: ['Food', 'Travel', 'Misc'].map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedFrequency,
              decoration: const InputDecoration(
                labelText: 'Frequency',
                border: OutlineInputBorder(),
              ),
              items: ['daily', 'weekly', 'monthly'].map((frequency) {
                return DropdownMenuItem(
                  value: frequency,
                  child: Text(frequency.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedFrequency = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            if (_selectedFrequency == 'monthly') ...[
              DropdownButtonFormField<int>(
                value: _selectedDayOfMonth ?? 1,
                decoration: const InputDecoration(
                  labelText: 'Day of Month',
                  border: OutlineInputBorder(),
                ),
                items: List.generate(31, (index) => index + 1).map((day) {
                  return DropdownMenuItem(
                    value: day,
                    child: Text('$day'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDayOfMonth = value;
                  });
                },
              ),
            ],
            if (_selectedFrequency == 'weekly') ...[
              DropdownButtonFormField<int>(
                value: _selectedWeekday ?? 1,
                decoration: const InputDecoration(
                  labelText: 'Day of Week',
                  border: OutlineInputBorder(),
                ),
                items: [
                  {'value': 1, 'label': 'Monday'},
                  {'value': 2, 'label': 'Tuesday'},
                  {'value': 3, 'label': 'Wednesday'},
                  {'value': 4, 'label': 'Thursday'},
                  {'value': 5, 'label': 'Friday'},
                  {'value': 6, 'label': 'Saturday'},
                  {'value': 7, 'label': 'Sunday'},
                ].map((item) {
                  return DropdownMenuItem(
                    value: item['value'] as int,
                    child: Text(item['label'] as String),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedWeekday = value;
                  });
                },
              ),
            ],
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Is Tiffin'),
              subtitle: const Text('Mark this as a tiffin expense'),
              value: _isTiffin,
              onChanged: (value) {
                setState(() {
                  _isTiffin = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => _saveRecurringTransaction(recurring),
          child: Text(recurring == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }

  Future<void> _saveRecurringTransaction(RecurringTransaction? existing) async {
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text);

    if (name.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields correctly')),
      );
      return;
    }

    final now = DateTime.now();
    final nextRunAt = existing?.nextRunAt ?? now;

    final recurringTransaction = RecurringTransaction(
      id: existing?.id,
      name: name,
      amount: amount,
      category: _selectedCategory,
      isTiffin: _isTiffin,
      frequency: _selectedFrequency,
      dayOfMonth: _selectedDayOfMonth,
      weekday: _selectedWeekday,
      nextRunAt: nextRunAt,
    );

    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    bool success;
    if (existing == null) {
      success = await provider.addRecurringTransaction(recurringTransaction);
    } else {
      success = await provider.updateRecurringTransaction(recurringTransaction);
    }

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(existing == null ? 'Recurring transaction added!' : 'Recurring transaction updated!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save recurring transaction')),
      );
    }
  }

  void _showDeleteConfirmation(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recurring Transaction'),
        content: const Text('Are you sure you want to delete this recurring transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final provider = Provider.of<ExpenseProvider>(context, listen: false);
              final success = await provider.deleteRecurringTransaction(id);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Recurring transaction deleted')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    _nameController.clear();
    _amountController.clear();
    _selectedCategory = 'Food';
    _selectedFrequency = 'monthly';
    _selectedDayOfMonth = 1;
    _selectedWeekday = 1;
    _isTiffin = false;
  }

  IconData _getFrequencyIcon(String frequency) {
    switch (frequency) {
      case 'daily':
        return Icons.today;
      case 'weekly':
        return Icons.date_range;
      case 'monthly':
        return Icons.calendar_month;
      default:
        return Icons.repeat;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}
