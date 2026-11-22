import 'package:flutter_test/flutter_test.dart';
import 'package:student_wallet_ai/models/transaction.dart';

void main() {
  test('transaction JSON round trip preserves values', () {
    final original = WalletTransaction(
      id: '1',
      title: 'Coffee',
      category: 'Food',
      amount: 4.5,
      date: DateTime(2026, 1, 2),
      type: TransactionType.expense,
    );

    final restored = WalletTransaction.fromJson(original.toJson());

    expect(restored.id, original.id);
    expect(restored.title, original.title);
    expect(restored.amount, original.amount);
    expect(restored.type, original.type);
  });
}
