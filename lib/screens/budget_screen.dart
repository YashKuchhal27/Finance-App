import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../models/budget.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _budgetController = TextEditingController();
  bool _rolloverEnabled = true;
  double _alertThreshold = 80.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ExpenseProvider>(context, listen: false);
      final budget = provider.currentBudget;
      if (budget != null) {
        _budgetController.text = budget.totalLimit.toString();
        _rolloverEnabled = budget.rolloverEnabled;
        _alertThreshold = budget.alertThreshold * 100;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Management'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          final budget = provider.currentBudget;
          final totalExpenses = provider.getTotalExpenses();
          final remainingBudget = provider.getRemainingBudget();
          final safeToSpend = provider.getSafeToSpend();
          final isAlert =
              provider.isBudgetAlertThreshold(_alertThreshold / 100);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Budget Overview Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Budget Overview',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        if (budget != null) ...[
                          _buildBudgetRow('Total Budget',
                              '₹${budget.totalLimit.toStringAsFixed(2)}'),
                          _buildBudgetRow(
                              'Spent', '₹${totalExpenses.toStringAsFixed(2)}'),
                          _buildBudgetRow('Remaining',
                              '₹${remainingBudget.toStringAsFixed(2)}'),
                          _buildBudgetRow('Safe to Spend',
                              '₹${safeToSpend.toStringAsFixed(2)}'),
                          const SizedBox(height: 16),
                          LinearProgressIndicator(
                            value: totalExpenses / budget.totalLimit,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isAlert ? Colors.red : Colors.green,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${((totalExpenses / budget.totalLimit) * 100).toStringAsFixed(1)}% used',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ] else ...[
                          const Text('No budget set for this month'),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Budget Settings Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Budget Settings',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _budgetController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Monthly Budget (₹)',
                            border: OutlineInputBorder(),
                            prefixText: '₹',
                          ),
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('Enable Rollover'),
                          subtitle:
                              const Text('Carry unused budget to next month'),
                          value: _rolloverEnabled,
                          onChanged: (value) {
                            setState(() {
                              _rolloverEnabled = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Alert Threshold: ${_alertThreshold.toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Slider(
                          value: _alertThreshold,
                          min: 50,
                          max: 95,
                          divisions: 9,
                          label: '${_alertThreshold.toStringAsFixed(0)}%',
                          onChanged: (value) {
                            setState(() {
                              _alertThreshold = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _saveBudget(provider),
                            child: const Text('Save Budget'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Budget Alerts Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Budget Alerts',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        if (isAlert) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              border: Border.all(color: Colors.red[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning, color: Colors.red[700]),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'You\'ve exceeded ${_alertThreshold.toStringAsFixed(0)}% of your budget!',
                                    style: TextStyle(color: Colors.red[700]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              border: Border.all(color: Colors.green[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle,
                                    color: Colors.green[700]),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'You\'re within your budget limits',
                                    style: TextStyle(color: Colors.green[700]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBudgetRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _saveBudget(ExpenseProvider provider) async {
    final amount = double.tryParse(_budgetController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid budget amount')),
      );
      return;
    }

    final budget = Budget(
      monthYear: provider.currentMonthYear,
      totalLimit: amount,
      rolloverEnabled: _rolloverEnabled,
      alertThreshold: _alertThreshold / 100,
      createdAt: DateTime.now(),
    );

    final success = await provider.insertBudget(budget);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget saved successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save budget')),
      );
    }
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }
}
