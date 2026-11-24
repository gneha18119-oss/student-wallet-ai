import 'package:material_ui/material_ui.dart';
import '../models/transaction.dart';
import '../services/transaction_store.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key, required this.store});
  final TransactionStore store;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  TransactionType _type = TransactionType.expense;
  String _category = 'Food';
  DateTime _date = DateTime.now();

  final _expenseCategories = ['Food', 'Transport', 'Shopping', 'Rent', 'Books', 'Entertainment', 'Other'];
  final _incomeCategories = ['Pocket money', 'Part-time job', 'Scholarship', 'Gift', 'Other'];

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = _type == TransactionType.expense ? _expenseCategories : _incomeCategories;
    if (!categories.contains(_category)) _category = categories.first;

    return Scaffold(
      appBar: AppBar(title: const Text('Add transaction')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(value: TransactionType.expense, label: Text('Expense'), icon: Icon(Icons.north_east)),
                  ButtonSegment(value: TransactionType.income, label: Text('Income'), icon: Icon(Icons.south_west)),
                ],
                selected: {_type},
                onSelectionChanged: (value) => setState(() => _type = value.first),
              ),
              const SizedBox(height: 22),
              const Text('What was it for?', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(hintText: 'e.g. Lunch, Bus pass, Pocket money'),
                validator: (value) => value == null || value.trim().isEmpty ? 'Enter a description' : null,
              ),
              const SizedBox(height: 18),
              const Text('Amount (USD)', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(prefixText: '\$ ', hintText: '0.00'),
                validator: (value) {
                  final amount = double.tryParse(value ?? '');
                  if (amount == null || amount <= 0) return 'Enter an amount greater than zero';
                  if (!amount.isFinite) return 'Enter a valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 18),
              const Text('Category', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _category,
                items: categories.map((category) => DropdownMenuItem(value: category, child: Text(category))).toList(),
                onChanged: (value) => setState(() => _category = value ?? categories.first),
              ),
              const SizedBox(height: 18),
              const Text('Date', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text('${_date.day}/${_date.month}/${_date.year}'),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6657D9),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Save transaction'),
              ),
              const SizedBox(height: 10),
              const Text('Prototype note: amounts are currently entered in USD. Multi-currency settings will be added in a later step.',
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final transaction = WalletTransaction(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      category: _category,
      amount: double.parse(_amountController.text.trim()),
      date: _date,
      type: _type,
    );
    await widget.store.add(transaction);
    if (mounted) Navigator.pop(context);
  }
}
