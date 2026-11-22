import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/transaction_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = TransactionStore();
  await store.load();
  runApp(StudentWalletApp(store: store));
}

class StudentWalletApp extends StatelessWidget {
  const StudentWalletApp({super.key, required this.store});

  final TransactionStore store;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF6657D9);
    return MaterialApp(
      title: 'Student Wallet AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light),
        scaffoldBackgroundColor: const Color(0xFFF7F7FC),
        cardTheme: const CardTheme(
          elevation: 0,
          color: Colors.white,
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF5F5FA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: HomeScreen(store: store),
    );
  }
}
