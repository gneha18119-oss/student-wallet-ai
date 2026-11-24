import 'package:flutter_test/flutter_test.dart';

void main() {
  test('basic arithmetic for wallet balance', () {
    const income = 1000.0;
    const expenses = 350.0;
    expect(income - expenses, 650.0);
  });
}
