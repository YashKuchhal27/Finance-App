# Expense Tracker App

A comprehensive Flutter mobile application for tracking personal expenses with a focus on simplicity and monthly organization.

## Features

### Core Functionality
- **Transaction Recording**: Add multiple transactions throughout the day with name, amount, and category
- **Balance Management**: Set initial balance for each month and track current balance
- **Tiffin Tracking**: Special daily expense tracking for tiffin with running totals
- **Monthly Organization**: Separate logs for each month with historical data preservation

### Category Management
- **Default Categories**: Travel, Food, Misc (3 compulsory categories)
- **Custom Categories**: Add up to 5 additional user-defined categories
- **Total Limit**: Maximum 8 categories (3 default + 5 custom)
- **Color Coding**: Visual category identification with custom colors

### Security Features
- **Input Validation**: Comprehensive validation for all user inputs
- **Data Sanitization**: Protection against injection attacks
- **Rate Limiting**: Prevents spam transactions
- **Local Data Encryption**: Sensitive data encryption using XOR encryption
- **Suspicious Pattern Detection**: Identifies and blocks malicious inputs

### User Interface
- **Modern Material Design**: Clean, intuitive interface following Material Design 3
- **Responsive Layout**: Optimized for both Android and iOS
- **Dark/Light Theme Support**: Consistent theming across the app
- **Real-time Updates**: Instant balance and total updates
- **Interactive Charts**: Visual representation of expense breakdowns

## Technical Architecture

### State Management
- **Provider Pattern**: Centralized state management using Provider
- **Reactive UI**: Real-time updates based on data changes
- **Efficient Rebuilds**: Optimized widget rebuilds for better performance

### Data Persistence
- **SQLite Database**: Local database for offline data storage
- **Data Models**: Well-structured models for transactions, categories, and monthly balances
- **Data Integrity**: Foreign key constraints and data validation

### Security Implementation
- **Input Sanitization**: All user inputs are sanitized before processing
- **Data Encryption**: Sensitive data encrypted using XOR encryption with dynamic keys
- **Rate Limiting**: Prevents abuse with configurable rate limits
- **Validation Layer**: Multi-layer validation for data integrity

## Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Android Studio / Xcode for mobile development
- VS Code or Android Studio for development

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd expense_tracker
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   # For Android
   flutter run
   
   # For iOS (macOS only)
   flutter run -d ios
   ```

### Building for Production

1. **Android APK**
   ```bash
   flutter build apk --release
   ```

2. **iOS App**
   ```bash
   flutter build ios --release
   ```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── transaction.dart
│   ├── category.dart
│   └── monthly_balance.dart
├── providers/                # State management
│   └── expense_provider.dart
├── screens/                  # UI screens
│   ├── home_screen.dart
│   ├── add_transaction_screen.dart
│   ├── transaction_list_screen.dart
│   ├── monthly_view_screen.dart
│   └── category_management_screen.dart
├── widgets/                  # Reusable widgets
│   ├── balance_card.dart
│   ├── quick_stats_card.dart
│   ├── tiffin_tracker_card.dart
│   ├── recent_transactions_list.dart
│   ├── transaction_list_item.dart
│   ├── monthly_summary_card.dart
│   └── category_breakdown_chart.dart
├── database/                 # Database layer
│   └── database_helper.dart
└── utils/                    # Utility functions
    ├── validators.dart
    └── security_helper.dart
```

## Key Features Explained

### Transaction Management
- Users can add unlimited transactions per day
- Each transaction includes name, amount, category, and timestamp
- Special tiffin flag for daily meal tracking
- Real-time balance calculations

### Monthly Organization
- Each month has its own data set
- Initial balance setting for each month
- Historical data preservation
- Month-to-month navigation

### Category System
- 3 default categories (Travel, Food, Misc)
- Up to 5 custom categories
- Color-coded visual identification
- Category-based expense tracking

### Security Measures
- Input validation and sanitization
- Rate limiting for transaction additions
- Data encryption for sensitive information
- Suspicious pattern detection

## Dependencies

- **flutter**: SDK
- **provider**: State management
- **sqflite**: Local database
- **path**: File path utilities
- **intl**: Internationalization
- **crypto**: Encryption utilities
- **shared_preferences**: Local storage
- **form_validator**: Input validation

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions, please open an issue in the repository.

## Roadmap

- [ ] Data export/import functionality
- [ ] Budget limits and alerts
- [ ] Receipt photo attachment
- [ ] Cloud backup and sync
- [ ] Advanced reporting and analytics
- [ ] Multi-currency support
- [ ] Recurring transaction support


