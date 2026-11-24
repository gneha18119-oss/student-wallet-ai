import 'dart:convert';
import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = WalletStore();
  await store.load();
  runApp(StudentWalletApp(store: store));
}

class WalletEntry {
  WalletEntry({
    required this.id, required this.title, required this.amount,
    required this.category, required this.type, required this.date,
    required this.payment, required this.wallet, this.note = '',
  });
  final String id, title, category, type, payment, wallet, note;
  final double amount;
  final DateTime date;

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'amount': amount, 'category': category,
    'type': type, 'date': date.toIso8601String(), 'payment': payment,
    'wallet': wallet, 'note': note,
  };

  factory WalletEntry.fromJson(Map<String, dynamic> j) => WalletEntry(
    id: j['id'] as String, title: j['title'] as String,
    amount: (j['amount'] as num).toDouble(), category: j['category'] as String,
    type: j['type'] as String, date: DateTime.parse(j['date'] as String),
    payment: (j['payment'] ?? 'Cash') as String,
    wallet: (j['wallet'] ?? 'Main Wallet') as String,
    note: (j['note'] ?? '') as String,
  );
}

class WalletStore extends ChangeNotifier {
  static const _entriesKey = 'swa_entries_v2';
  static const _budgetKey = 'swa_monthly_budget_v1';
  static const _goalKey = 'swa_savings_goal_v1';
  final List<WalletEntry> entries = [];
  double monthlyBudget = 5000;
  double savingsGoal = 10000;

  double get income => entries.where((e) => e.type == 'Income').fold(0, (s,e) => s+e.amount);
  double get expenses => entries.where((e) => e.type == 'Expense').fold(0, (s,e) => s+e.amount);
  double get balance => income - expenses;
  double get thisMonthExpenses {
    final now = DateTime.now();
    return entries.where((e) => e.type == 'Expense' && e.date.year == now.year && e.date.month == now.month).fold(0, (s,e) => s+e.amount);
  }
  double get thisMonthIncome {
    final now = DateTime.now();
    return entries.where((e) => e.type == 'Income' && e.date.year == now.year && e.date.month == now.month).fold(0, (s,e) => s+e.amount);
  }

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    monthlyBudget = p.getDouble(_budgetKey) ?? 5000;
    savingsGoal = p.getDouble(_goalKey) ?? 10000;
    final raw = p.getString(_entriesKey) ?? p.getString('student_wallet_transactions_v1');
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        entries..clear()..addAll(list.map((x) => WalletEntry.fromJson(Map<String,dynamic>.from(x as Map))));
        entries.sort((a,b) => b.date.compareTo(a.date));
      } catch (_) {}
    }
  }
  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_entriesKey, jsonEncode(entries.map((e)=>e.toJson()).toList()));
    await p.setDouble(_budgetKey, monthlyBudget);
    await p.setDouble(_goalKey, savingsGoal);
  }
  Future<void> upsert(WalletEntry e) async {
    final i = entries.indexWhere((x)=>x.id == e.id);
    if (i < 0) { entries.insert(0,e); } else { entries[i] = e; }
    entries.sort((a,b)=>b.date.compareTo(a.date));
    await save(); notifyListeners();
  }
  Future<void> remove(String id) async {
    entries.removeWhere((e)=>e.id == id);
    await save(); notifyListeners();
  }
  Future<void> setTargets(double budget, double goal) async {
    monthlyBudget = budget; savingsGoal = goal;
    await save(); notifyListeners();
  }
}

class StudentWalletApp extends StatelessWidget {
  const StudentWalletApp({super.key, required this.store});
  final WalletStore store;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Student Wallet AI', debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6657D9)), scaffoldBackgroundColor: const Color(0xFFF7F7FC)),
    home: MainScreen(store: store),
  );
}

String money(double n) => NumberFormat.currency(locale:'en_IN', symbol:'₹', decimalDigits:2).format(n);

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.store});
  final WalletStore store;
  @override
  State<MainScreen> createState()=>_MainScreenState();
}
class _MainScreenState extends State<MainScreen> {
  int tab = 0;
  Future<void> openEntry([WalletEntry? old]) async {
    await showDialog<void>(context: context, builder: (_) => EntryDialog(store: widget.store, old: old));
  }
  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(store: widget.store, add: ()=>openEntry()),
      EntriesPage(store: widget.store, edit: (e)=>openEntry(e)),
      TargetsPage(store: widget.store),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Student Wallet AI', style: TextStyle(fontWeight:FontWeight.bold)), actions:[
        IconButton(tooltip:'Add transaction', onPressed:()=>openEntry(), icon:const Icon(Icons.add_circle_outline))
      ]),
      body: pages[tab],
      bottomNavigationBar: NavigationBar(selectedIndex:tab, onDestinationSelected:(i)=>setState(()=>tab=i), destinations:const [
        NavigationDestination(icon:Icon(Icons.dashboard_outlined), selectedIcon:Icon(Icons.dashboard), label:'Home'),
        NavigationDestination(icon:Icon(Icons.receipt_long_outlined), label:'Transactions'),
        NavigationDestination(icon:Icon(Icons.savings_outlined), label:'Budget & Goals'),
      ]),
      floatingActionButton: tab == 0 ? FloatingActionButton.extended(onPressed:()=>openEntry(), icon:const Icon(Icons.add), label:const Text('Add')) : null,
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.store, required this.add});
  final WalletStore store; final VoidCallback add;
  @override
  Widget build(BuildContext context)=>AnimatedBuilder(animation:store,builder:(context,_) {
    final spent=store.thisMonthExpenses;
    final ratio=store.monthlyBudget<=0?0:(spent/store.monthlyBudget).clamp(0.0,1.0);
    return ListView(padding:const EdgeInsets.all(16), children:[
      Container(padding:const EdgeInsets.all(22), decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF6657D9),Color(0xFF8978EF)]),borderRadius:BorderRadius.circular(22)), child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('Available Balance',style:TextStyle(color:Colors.white70)),
        const SizedBox(height:8), Text(money(store.balance),style:const TextStyle(color:Colors.white,fontSize:30,fontWeight:FontWeight.bold)),
        const SizedBox(height:18), Row(children:[
          Expanded(child:_Metric('Total income',money(store.income),Icons.south_west)),
          Expanded(child:_Metric('Total expenses',money(store.expenses),Icons.north_east)),
        ])
      ])),
      const SizedBox(height:16),
      Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('This month budget',style:TextStyle(fontWeight:FontWeight.bold,fontSize:17)),
        const SizedBox(height:8), Text('${money(spent)} spent of ${money(store.monthlyBudget)}'),
        const SizedBox(height:10), LinearProgressIndicator(value:ratio,minHeight:9,borderRadius:BorderRadius.circular(10)),
        const SizedBox(height:6), Text(money((store.monthlyBudget-spent).clamp(0,double.infinity))+' remaining',style:const TextStyle(color:Colors.black54)),
      ]))),
      const SizedBox(height:18), const Text('Recent transactions',style:TextStyle(fontWeight:FontWeight.bold,fontSize:18)),
      const SizedBox(height:8),
      if(store.entries.isEmpty) const Padding(padding:EdgeInsets.all(24),child:Text('No transactions yet. Tap Add to record your first entry.',textAlign:TextAlign.center))
      else ...store.entries.take(5).map((e)=>EntryTile(entry:e,onEdit:()=>showEntryEditor(context,store,e),onDelete:()=>store.remove(e.id))),
    ]);
  });
}

class _Metric extends StatelessWidget {
  const _Metric(this.label,this.value,this.icon);
  final String label,value; final IconData icon;
  @override Widget build(BuildContext context)=>Row(children:[Icon(icon,color:Colors.white),const SizedBox(width:7),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(label,style:const TextStyle(color:Colors.white70,fontSize:12)),Text(value,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold))]))]);
}

class EntriesPage extends StatefulWidget {
  const EntriesPage({super.key,required this.store,required this.edit});
  final WalletStore store; final ValueChanged<WalletEntry> edit;
  @override State<EntriesPage> createState()=>_EntriesPageState();
}
class _EntriesPageState extends State<EntriesPage> {
  String filter='All';
  @override Widget build(BuildContext context)=>AnimatedBuilder(animation:widget.store,builder:(context,_) {
    final list=widget.store.entries.where((e)=>filter=='All'||e.type==filter).toList();
    return Column(children:[
      Padding(padding:const EdgeInsets.all(12),child:SegmentedButton<String>(segments:const[
        ButtonSegment(value:'All',label:Text('All')),ButtonSegment(value:'Income',label:Text('Income')),ButtonSegment(value:'Expense',label:Text('Expense'))
      ],selected:{filter},onSelectionChanged:(s)=>setState(()=>filter=s.first))),
      Expanded(child:list.isEmpty?const Center(child:Text('No matching transactions')):ListView(padding:const EdgeInsets.symmetric(horizontal:12),children:list.map((e)=>EntryTile(entry:e,onEdit:()=>widget.edit(e),onDelete:()=>widget.store.remove(e.id))).toList())),
    ]);
  });
}

class EntryTile extends StatelessWidget {
  const EntryTile({super.key,required this.entry,required this.onEdit,required this.onDelete});
  final WalletEntry entry; final VoidCallback onEdit,onDelete;
  @override Widget build(BuildContext context) {
    final inc=entry.type=='Income';
    return Card(margin:const EdgeInsets.only(bottom:8),child:ListTile(
      leading:CircleAvatar(backgroundColor:inc?Colors.green.shade50:Colors.red.shade50,child:Icon(inc?Icons.south_west:Icons.north_east,color:inc?Colors.green:Colors.red)),
      title:Text(entry.title,style:const TextStyle(fontWeight:FontWeight.w600)),
      subtitle:Text('${entry.category} • ${DateFormat('dd MMM yyyy').format(entry.date)}\\n${entry.payment} • ${entry.wallet}',maxLines:2),
      isThreeLine:true,
      trailing:PopupMenuButton<String>(onSelected:(v)=>v=='edit'?onEdit():onDelete(),itemBuilder:(_)=>const[
        PopupMenuItem(value:'edit',child:Text('Edit')),PopupMenuItem(value:'delete',child:Text('Delete'))
      ], child:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.end,children:[
        Text('${inc?'+':'-'}${money(entry.amount)}',style:TextStyle(color:inc?Colors.green:Colors.red,fontWeight:FontWeight.bold)),
        const Icon(Icons.more_vert,size:18),
      ])),
    ));
  }
}

void showEntryEditor(BuildContext context,WalletStore store,WalletEntry entry) {
  showDialog<void>(context:context,builder:(_)=>EntryDialog(store:store,old:entry));
}

class EntryDialog extends StatefulWidget {
  const EntryDialog({super.key,required this.store,this.old});
  final WalletStore store; final WalletEntry? old;
  @override State<EntryDialog> createState()=>_EntryDialogState();
}
class _EntryDialogState extends State<EntryDialog> {
  final keyForm=GlobalKey<FormState>();
  late final title=TextEditingController(text:widget.old?.title??'');
  late final amount=TextEditingController(text:widget.old?.amount.toString()??'');
  late final note=TextEditingController(text:widget.old?.note??'');
  late String type=widget.old?.type??'Expense';
  late String category=widget.old?.category??'Food';
  late String payment=widget.old?.payment??'UPI';
  late String wallet=widget.old?.wallet??'Main Wallet';
  late DateTime date=widget.old?.date??DateTime.now();
  final expenseCats=['Food','Transport','Rent','Fees','Books','Shopping','Health','Entertainment','Subscriptions','Other'];
  final incomeCats=['Pocket Money','Part-time Job','Scholarship','Gift','Salary','Other'];
  @override void dispose(){title.dispose();amount.dispose();note.dispose();super.dispose();}
  @override Widget build(BuildContext context) {
    final cats=type=='Expense'?expenseCats:incomeCats;
    if(!cats.contains(category)) category=cats.first;
    return AlertDialog(
      title:Text(widget.old==null?'Add transaction':'Edit transaction'),
      content:SingleChildScrollView(child:Form(key:keyForm,child:Column(mainAxisSize:MainAxisSize.min,children:[
        SegmentedButton<String>(segments:const[ButtonSegment(value:'Expense',label:Text('Expense')),ButtonSegment(value:'Income',label:Text('Income'))],selected:{type},onSelectionChanged:(s)=>setState(()=>type=s.first)),
        const SizedBox(height:12),
        TextFormField(controller:title,decoration:const InputDecoration(labelText:'Description *'),validator:(v)=>v==null||v.trim().isEmpty?'Enter description':null),
        const SizedBox(height:10),
        TextFormField(controller:amount,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Amount *',prefixText:'₹ '),validator:(v){final n=double.tryParse(v??'');return n==null||!n.isFinite||n<=0?'Enter a valid amount':null;}),
        const SizedBox(height:10),
        DropdownButtonFormField<String>(value:category,decoration:const InputDecoration(labelText:'Category'),items:cats.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setState(()=>category=v??cats.first)),
        const SizedBox(height:10),
        DropdownButtonFormField<String>(value:payment,decoration:const InputDecoration(labelText:'Payment method'),items:['Cash','UPI','Debit Card','Credit Card','Bank Transfer','Other'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setState(()=>payment=v??'Cash')),
        const SizedBox(height:10),
        DropdownButtonFormField<String>(value:wallet,decoration:const InputDecoration(labelText:'Wallet / Account'),items:['Main Wallet','Cash','Bank Account','UPI Wallet','Other'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setState(()=>wallet=v??'Main Wallet')),
        const SizedBox(height:8),
        TextFormField(controller:note,decoration:const InputDecoration(labelText:'Notes (optional)')),
        const SizedBox(height:8),
        OutlinedButton.icon(onPressed:()async{final d=await showDatePicker(context:context,initialDate:date,firstDate:DateTime(2000),lastDate:DateTime(2100));if(d!=null)setState(()=>date=d);},icon:const Icon(Icons.calendar_month),label:Text(DateFormat('dd MMM yyyy').format(date))),
      ]))),
      actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Cancel')),FilledButton(onPressed:save,child:const Text('Save'))],
    );
  }
  Future<void> save() async {
    if(!keyForm.currentState!.validate())return;
    final e=WalletEntry(id:widget.old?.id??DateTime.now().microsecondsSinceEpoch.toString(),title:title.text.trim(),amount:double.parse(amount.text.trim()),category:category,type:type,date:date,payment:payment,wallet:wallet,note:note.text.trim());
    await widget.store.upsert(e);
    if(mounted)Navigator.pop(context);
  }
}

class TargetsPage extends StatefulWidget {
  const TargetsPage({super.key,required this.store});
  final WalletStore store;
  @override State<TargetsPage> createState()=>_TargetsPageState();
}
class _TargetsPageState extends State<TargetsPage> {
  late final budget=TextEditingController(text:widget.store.monthlyBudget.toStringAsFixed(0));
  late final goal=TextEditingController(text:widget.store.savingsGoal.toStringAsFixed(0));
  @override void dispose(){budget.dispose();goal.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>AnimatedBuilder(animation:widget.store,builder:(context,_)=>ListView(padding:const EdgeInsets.all(16),children:[
    Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('Monthly budget',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
      const SizedBox(height:8),Text('Spent this month: ${money(widget.store.thisMonthExpenses)}'),
      const SizedBox(height:12),TextField(controller:budget,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Monthly budget (₹)')),
      const SizedBox(height:18),const Text('Savings goal',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
      const SizedBox(height:8),Text('Current recorded balance: ${money(widget.store.balance)}'),
      const SizedBox(height:12),TextField(controller:goal,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Target amount (₹)')),
      const SizedBox(height:18),SizedBox(width:double.infinity,child:FilledButton(onPressed:()async{final b=double.tryParse(budget.text);final g=double.tryParse(goal.text);if(b==null||g==null||b<0||g<0){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter valid non-negative amounts')));return;}await widget.store.setTargets(b,g);if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Targets saved')));},child:const Text('Save targets'))),
    ]))),
    const Padding(padding:EdgeInsets.only(top:12),child:Text('Note: savings progress is based on the recorded balance. This is a local prototype; it does not sync to an online account.',style:TextStyle(color:Colors.black54))),
  ]));
}
