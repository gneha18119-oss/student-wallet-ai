import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/transaction_store.dart';
import 'add_transaction_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.store});
  final TransactionStore store;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _currency = '\$';

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.store.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  String money(double value) => '$_currency${value.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final budget = 500.0;
    final progress = (store.totalExpenses / budget).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7FC),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student Wallet AI', style: TextStyle(fontWeight: FontWeight.w800)),
            Text('Your money, made clearer', style: TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Profile (coming soon)',
            onPressed: () => _message('Profile settings will be added next.'),
            icon: const CircleAvatar(
              radius: 17,
              backgroundColor: Color(0xFFE9E5FF),
              child: Icon(Icons.person_outline, color: Color(0xFF6657D9)),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
          children: [
            _balanceCard(store),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _summaryCard('Income', store.totalIncome, Icons.south_west, const Color(0xFF15966B))),
                const SizedBox(width: 12),
                Expanded(child: _summaryCard('Expenses', store.totalExpenses, Icons.north_east, const Color(0xFFE16B6B))),
              ],
            ),
            const SizedBox(height: 22),
            _sectionTitle('Monthly budget', 'Edit later'),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Monthly spending limit', style: TextStyle(fontWeight: FontWeight.w600)),
                        Text(money(budget), style: const TextStyle(fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        backgroundColor: const Color(0xFFECEAF5),
                        color: progress >= 1 ? Colors.redAccent : const Color(0xFF6657D9),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('${(progress * 100).round()}% used • ${money((budget - store.totalExpenses).clamp(0, budget))} left in budget',
                        style: const TextStyle(color: Colors.black54, fontSize: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            _sectionTitle('Recent transactions', 'Latest first'),
            const SizedBox(height: 10),
            if (store.transactions.isEmpty)
              _emptyState()
            else
              ...store.transactions.take(8).map(_transactionTile),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTransaction,
        backgroundColor: const Color(0xFF6657D9),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add transaction'),
      ),
    );
  }

  Widget _balanceCard(TransactionStore store) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7162E8), Color(0xFF5144B8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AVAILABLE BALANCE', style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text(money(store.balance), style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Color(0xFFFFE7A3), size: 17),
              SizedBox(width: 7),
              Text('Small steps make smarter money habits', style: TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String title, double amount, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(color: Colors.black54, fontSize: 12)),
            const SizedBox(height: 3),
            Text(money(amount), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, String trailing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        Text(trailing, style: const TextStyle(color: Colors.black45, fontSize: 11)),
      ],
    );
  }

  Widget _emptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.receipt_long_outlined, size: 36, color: Color(0xFF8D84D8)),
            const SizedBox(height: 10),
            const Text('No transactions yet', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Add your first expense or income to get started.',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _transactionTile(WalletTransaction transaction) {
    final isIncome = transaction.type == TransactionType.income;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isIncome ? const Color(0xFFE2F5EC) : const Color(0xFFFFEAEA),
          child: Icon(isIncome ? Icons.south_west : Icons.north_east,
              color: isIncome ? const Color(0xFF15966B) : const Color(0xFFE16B6B)),
        ),
        title: Text(transaction.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${transaction.category} • ${DateFormat.yMMMd().format(transaction.date)}'),
        trailing: Text(
          '${isIncome ? '+' : '-'}${money(transaction.amount)}',
          style: TextStyle(fontWeight: FontWeight.w800, color: isIncome ? const Color(0xFF15966B) : Colors.black87),
        ),
        onLongPress: () async {
          final shouldDelete = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete transaction?'),
              content: const Text('This removes the entry from this device.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
              ],
            ),
          );
          if (shouldDelete == true) await widget.store.delete(transaction.id);
        },
      ),
    );
  }

  Future<void> _addTransaction() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddTransactionScreen(store: widget.store)),
    );
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
