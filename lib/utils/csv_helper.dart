import 'dart:io';
import '../models/transaction.dart';

class CsvHelper {
  // Export transactions to CSV
  static Future<String> exportTransactions(
      List<Transaction> transactions) async {
    final buffer = StringBuffer();

    // CSV header
    buffer.writeln('Date,Name,Amount,Category,Is Tiffin,Month Year');

    // CSV rows
    for (final transaction in transactions) {
      final date = transaction.dateTime.toIso8601String().split('T')[0];
      final name = _escapeCsvField(transaction.name);
      final amount = transaction.amount.toStringAsFixed(2);
      final category = _escapeCsvField(transaction.category);
      final isTiffin = transaction.isTiffin ? 'Yes' : 'No';
      final monthYear = transaction.monthYear;

      buffer.writeln('$date,$name,$amount,$category,$isTiffin,$monthYear');
    }

    return buffer.toString();
  }

  // Import transactions from CSV
  static List<Transaction> importTransactions(String csvContent) {
    final lines = csvContent.split('\n');
    final transactions = <Transaction>[];

    // Skip header line
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      try {
        final fields = _parseCsvLine(line);
        if (fields.length < 6) continue;

        final date = DateTime.parse(fields[0]);
        final name = _unescapeCsvField(fields[1]);
        final amount = double.parse(fields[2]);
        final category = _unescapeCsvField(fields[3]);
        final isTiffin = fields[4].toLowerCase() == 'yes';
        final monthYear = fields[5];

        final transaction = Transaction(
          name: name,
          amount: amount,
          category: category,
          dateTime: date,
          isTiffin: isTiffin,
          monthYear: monthYear,
        );

        transactions.add(transaction);
      } catch (e) {
        // Skip invalid lines
        continue;
      }
    }

    return transactions;
  }

  // Save CSV to file
  static Future<File> saveCsvToFile(String csvContent, String filename) async {
    final file = File(filename);
    await file.writeAsString(csvContent);
    return file;
  }

  // Read CSV from file
  static Future<String> readCsvFromFile(File file) async {
    return await file.readAsString();
  }

  // Helper methods
  static String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  static String _unescapeCsvField(String field) {
    if (field.startsWith('"') && field.endsWith('"')) {
      return field.substring(1, field.length - 1).replaceAll('""', '"');
    }
    return field;
  }

  static List<String> _parseCsvLine(String line) {
    final fields = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          // Escaped quote
          buffer.write('"');
          i++; // Skip next quote
        } else {
          // Toggle quote state
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        // Field separator
        fields.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }

    // Add last field
    fields.add(buffer.toString());
    return fields;
  }
}
