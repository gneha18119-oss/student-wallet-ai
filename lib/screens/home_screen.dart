import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart';
import '../services/transaction_store.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.store});

  final TransactionStore store;

  String money(double amount) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    ).format(amount);
  }

  Future<void> addTransaction(BuildContext context) async {
    final titleController = TextEditingController();
    final amountController = TextEditingController();

    final formKey = GlobalKey<FormState>();
    var type = TransactionType.expense;
    var category = 'Food';
    var date = DateTime.now();

    final categories = [
      'Food',
      'Travel',
      'Books',
      'Fees',
      'Shopping',
      'Pocket Money',
      'Other',
    ];

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Transaction'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<TransactionType>(
                        value: type,
                        decoration: const InputDecoration(
                          labelText: 'Transaction type',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: TransactionType.expense,
                            child: Text('Expense'),
                          ),
                          DropdownMenuItem(
                            value: TransactionType.income,
                            child: Text('Income'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => type = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'e.g. Lunch',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter a description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: amountController,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Amount',
                          prefixText: '₹ ',
                        ),
                        validator: (value) {
                          final amount = double.tryParse(
                            value?.trim() ?? '',
                          );

                          if (amount == null || amount <= 0) {
                            return 'Enter a valid amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: category,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                        items: categories.map((item) {
                          return DropdownMenuItem(
                            value: item,
                            child: Text(item),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => category = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final selected = await showDatePicker(
                            context: context,
                            initialDate: date,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );

                          if (selected != null) {
                            setDialogState(() => date = selected);
                          }
                        },
                        icon: const Icon(Icons.calendar_month),
                        label: Text(
                          DateFormat('dd MMM yyyy').format(date),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    final transaction = WalletTransaction(
                      id: DateTime.now()
                          .microsecondsSinceEpoch
                          .toString(),
                      title: titleController.text.trim(),
                      category: category,
                      amount: double.parse(amountController.text.trim()),
                      date: date,
                      type: type,
                    );

                    await store.add(transaction);

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    amountController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Student Wallet',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () => addTransaction(context),
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add transaction',
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, child) {
          final transactions = store.transactions;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF6657D9),
                      Color(0xFF8978EF),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Available Balance',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      money(store.balance),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _BalanceItem(
                            label: 'Income',
                            amount: money(store.totalIncome),
                            icon: Icons.arrow_downward,
                          ),
                        ),
                        Expanded(
                          child: _BalanceItem(
                            label: 'Expenses',
                            amount: money(store.totalExpenses),
                            icon: Icons.arrow_upward,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Transactions',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('${transactions.length} records'),
                ],
              ),
              const SizedBox(height: 12),
              if (transactions.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 55,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No transactions yet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text('Tap + to add your first transaction.'),
                    ],
                  ),
                )
              else
                ...transactions.map((transaction) {
                  final isIncome =
                      transaction.type == TransactionType.income;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isIncome
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        child: Icon(
                          isIncome
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          color: isIncome ? Colors.green : Colors.red,
                        ),
                      ),
                      title: Text(
                        transaction.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${transaction.category} • '
                        '${DateFormat('dd MMM yyyy').format(transaction.date)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${isIncome ? '+' : '-'}'
                            '${money(transaction.amount)}',
                            style: TextStyle(
                              color: isIncome ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'delete') {
                                await store.delete(transaction.id);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => addTransaction(context),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }
}

class _BalanceItem extends StatelessWidget {
  const _BalanceItem({
    required this.label,
    required this.amount,
    required this.icon,
  });

  final String label;
  final String amount;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 19),
        const SizedBox(width: 7),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 3),
              Text(
                amount,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
