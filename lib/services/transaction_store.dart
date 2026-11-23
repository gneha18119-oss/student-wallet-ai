import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';

class TransactionStore extends ChangeNotifier {
  static const _storageKey = 'student_wallet_transactions_v1';
  final List<WalletTransaction> _transactions = [];

  List<WalletTransaction> get transactions =>
      List.unmodifiable(_transactions);

  double get totalIncome => _transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0, (sum, t) => sum + t.amount);

  double get totalExpenses => _transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0, (sum, t) => sum + t.amount);

  double get balance => totalIncome - totalExpenses;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      _transactions
        ..clear()
        ..addAll(decoded.map((item) =>
            WalletTransaction.fromJson(item as Map<String, dynamic>)));
      _transactions.sort((a, b) => b.date.compareTo(a.date));
    } catch (_) {
      // Ignore malformed local prototype data rather than crashing the app.
    }
  }

  Future<void> add(WalletTransaction transaction) async {
    _transactions.insert(0, transaction);
    await _save();
    notifyListeners();
  }

  Future<void> delete(String id) async {
    _transactions.removeWhere((t) => t.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_transactions.map((t) => t.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }
}
