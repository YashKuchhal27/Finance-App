import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityHelper {
  static const String _keyPrefix = 'expense_tracker_';
  static const String _saltKey = '${_keyPrefix}salt';
  static const String _encryptionKey = '${_keyPrefix}encryption_key';

  // Generate a random salt
  static String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Encode(bytes);
  }

  // Generate encryption key from salt
  static String _generateEncryptionKey(String salt) {
    final bytes = utf8.encode(salt + 'expense_tracker_app');
    final digest = sha256.convert(bytes);
    return base64Encode(digest.bytes);
  }

  // Initialize security settings
  static Future<void> initializeSecurity() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Generate and store salt if not exists
    if (!prefs.containsKey(_saltKey)) {
      final salt = _generateSalt();
      await prefs.setString(_saltKey, salt);
    }
    
    // Generate and store encryption key if not exists
    if (!prefs.containsKey(_encryptionKey)) {
      final salt = prefs.getString(_saltKey) ?? _generateSalt();
      final encryptionKey = _generateEncryptionKey(salt);
      await prefs.setString(_encryptionKey, encryptionKey);
    }
  }

  // Get encryption key
  static Future<String> getEncryptionKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_encryptionKey) ?? '';
  }

  // Simple XOR encryption for sensitive data
  static String _xorEncrypt(String text, String key) {
    final textBytes = utf8.encode(text);
    final keyBytes = utf8.encode(key);
    final encrypted = <int>[];
    
    for (int i = 0; i < textBytes.length; i++) {
      encrypted.add(textBytes[i] ^ keyBytes[i % keyBytes.length]);
    }
    
    return base64Encode(encrypted);
  }

  // Simple XOR decryption
  static String _xorDecrypt(String encryptedText, String key) {
    final encryptedBytes = base64Decode(encryptedText);
    final keyBytes = utf8.encode(key);
    final decrypted = <int>[];
    
    for (int i = 0; i < encryptedBytes.length; i++) {
      decrypted.add(encryptedBytes[i] ^ keyBytes[i % keyBytes.length]);
    }
    
    return utf8.decode(decrypted);
  }

  // Encrypt sensitive data
  static Future<String> encryptData(String data) async {
    final key = await getEncryptionKey();
    return _xorEncrypt(data, key);
  }

  // Decrypt sensitive data
  static Future<String> decryptData(String encryptedData) async {
    final key = await getEncryptionKey();
    return _xorDecrypt(encryptedData, key);
  }

  // Validate data integrity
  static bool validateDataIntegrity(String data, String expectedHash) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString() == expectedHash;
  }

  // Generate data hash
  static String generateDataHash(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Sanitize input to prevent injection attacks
  static String sanitizeInput(String input) {
    return input
        .replaceAll(RegExp(r'[<>"\'']'), '') // Remove potentially dangerous characters
        .trim();
  }

  // Validate amount input
  static bool isValidAmount(String amount) {
    final regex = RegExp(r'^\d+(\.\d{1,2})?$');
    return regex.hasMatch(amount);
  }

  // Validate category name
  static bool isValidCategoryName(String name) {
    final regex = RegExp(r'^[a-zA-Z0-9\s]{2,20}$');
    return regex.hasMatch(name);
  }

  // Check for suspicious patterns
  static bool hasSuspiciousPatterns(String input) {
    final suspiciousPatterns = [
      RegExp(r'<script', caseSensitive: false),
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'data:', caseSensitive: false),
      RegExp(r'vbscript:', caseSensitive: false),
      RegExp(r'onload=', caseSensitive: false),
      RegExp(r'onerror=', caseSensitive: false),
    ];
    
    return suspiciousPatterns.any((pattern) => pattern.hasMatch(input));
  }

  // Rate limiting for transaction additions
  static final Map<String, List<DateTime>> _rateLimitMap = {};
  
  static bool isRateLimited(String userId, {int maxRequests = 10, Duration window = const Duration(minutes: 1)}) {
    final now = DateTime.now();
    final userRequests = _rateLimitMap[userId] ?? [];
    
    // Remove old requests outside the window
    userRequests.removeWhere((time) => now.difference(time) > window);
    
    if (userRequests.length >= maxRequests) {
      return true;
    }
    
    userRequests.add(now);
    _rateLimitMap[userId] = userRequests;
    return false;
  }

  // Clear rate limit data
  static void clearRateLimit() {
    _rateLimitMap.clear();
  }
}


