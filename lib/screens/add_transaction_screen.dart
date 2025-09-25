import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../models/transaction.dart';
import '../utils/validators.dart';
import '../utils/security_helper.dart';

class AddTransactionScreen extends StatefulWidget {
  final bool isTiffin;

  const AddTransactionScreen({super.key, this.isTiffin = false});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedCategory = '';
  bool _isTiffin = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isTiffin = widget.isTiffin;
    if (widget.isTiffin) {
      _selectedCategory = 'Food';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.isTiffin ? 'Add Tiffin' : 'Add Transaction',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, expenseProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Transaction Type Card
                  if (!widget.isTiffin) _buildTransactionTypeCard(),
                  const SizedBox(height: 16),

                  // Transaction Form Card
                  _buildTransactionFormCard(expenseProvider),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _submitTransaction(expenseProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              widget.isTiffin ? 'Add Tiffin' : 'Add Transaction',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionTypeCard() {
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
            'Transaction Type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTypeOption(
                  'Regular',
                  Icons.shopping_cart,
                  const Color(0xFF2196F3),
                  !_isTiffin,
                  () => setState(() => _isTiffin = false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTypeOption(
                  'Tiffin',
                  Icons.lunch_dining,
                  const Color(0xFFFF9800),
                  _isTiffin,
                  () => setState(() => _isTiffin = true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeOption(String title, IconData icon, Color color, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionFormCard(ExpenseProvider expenseProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          // Expense Name
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: widget.isTiffin ? 'Tiffin Description' : 'Expense Name',
              hintText: widget.isTiffin ? 'e.g., Lunch at office' : 'e.g., Grocery shopping',
              prefixIcon: const Icon(Icons.description),
              border: const OutlineInputBorder(),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF2196F3)),
              ),
            ),
            validator: Validators.validateExpenseName,
            onChanged: (value) {
              // Sanitize input
              final sanitized = SecurityHelper.sanitizeInput(value);
              if (sanitized != value) {
                _nameController.text = sanitized;
                _nameController.selection = TextSelection.fromPosition(
                  TextPosition(offset: sanitized.length),
                );
              }
            },
          ),
          const SizedBox(height: 16),

          // Amount
          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Amount',
              hintText: '0.00',
              prefixIcon: Icon(Icons.currency_rupee),
              prefixText: '₹ ',
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF2196F3)),
              ),
            ),
            validator: Validators.validateAmount,
            onChanged: (value) {
              // Validate amount format
              if (value.isNotEmpty && !SecurityHelper.isValidAmount(value)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid amount'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 16),

          // Category Selection
          DropdownButtonFormField<String>(
            value: _selectedCategory.isEmpty ? null : _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Category',
              prefixIcon: Icon(Icons.category),
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF2196F3)),
              ),
            ),
            validator: Validators.validateCategory,
            items: expenseProvider.categories.map((category) {
              return DropdownMenuItem<String>(
                value: category.name,
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Color(int.parse(category.color.replaceFirst('#', '0xFF'))),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(category.name),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategory = value ?? '';
              });
            },
          ),
          const SizedBox(height: 16),

          // Current Date & Time
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, color: Color(0xFF666666)),
                const SizedBox(width: 8),
                Text(
                  'Date & Time: ${DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.now())}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitTransaction(ExpenseProvider expenseProvider) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check for suspicious patterns
    if (SecurityHelper.hasSuspiciousPatterns(_nameController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid input detected'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Rate limiting check
    if (SecurityHelper.isRateLimited('user')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Too many requests. Please wait a moment.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final transaction = Transaction(
        name: _nameController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        category: _selectedCategory,
        dateTime: DateTime.now(),
        isTiffin: _isTiffin,
        monthYear: expenseProvider.currentMonthYear,
      );

      final success = await expenseProvider.addTransaction(transaction);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isTiffin ? 'Tiffin added successfully!' : 'Transaction added successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add transaction. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}


