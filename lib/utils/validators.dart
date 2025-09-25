
class Validators {
  static String? validateExpenseName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Expense name is required';
    }
    if (value.trim().length < 2) {
      return 'Expense name must be at least 2 characters';
    }
    if (value.trim().length > 50) {
      return 'Expense name must be less than 50 characters';
    }
    return null;
  }

  static String? validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required';
    }
    
    final amount = double.tryParse(value.trim());
    if (amount == null) {
      return 'Please enter a valid amount';
    }
    
    if (amount <= 0) {
      return 'Amount must be greater than 0';
    }
    
    if (amount > 999999) {
      return 'Amount is too large';
    }
    
    return null;
  }

  static String? validateCategory(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Category is required';
    }
    return null;
  }

  static String? validateBalance(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Initial balance is required';
    }
    
    final balance = double.tryParse(value.trim());
    if (balance == null) {
      return 'Please enter a valid balance';
    }
    
    if (balance < 0) {
      return 'Balance cannot be negative';
    }
    
    if (balance > 9999999) {
      return 'Balance is too large';
    }
    
    return null;
  }

  static String? validateCategoryName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Category name is required';
    }
    
    if (value.trim().length < 2) {
      return 'Category name must be at least 2 characters';
    }
    
    if (value.trim().length > 20) {
      return 'Category name must be less than 20 characters';
    }
    
    // Check for special characters
    if (!RegExp(r'^[a-zA-Z0-9\s]+$').hasMatch(value.trim())) {
      return 'Category name can only contain letters, numbers, and spaces';
    }
    
    return null;
  }

  static String? validateTiffinAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Tiffin amount is required';
    }
    
    final amount = double.tryParse(value.trim());
    if (amount == null) {
      return 'Please enter a valid amount';
    }
    
    if (amount < 0) {
      return 'Amount cannot be negative';
    }
    
    if (amount > 10000) {
      return 'Tiffin amount is too large';
    }
    
    return null;
  }
}
