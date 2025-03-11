import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sprint/home/budgets/budget_detail_page.dart';
import 'package:sprint/home/budgets/budget_page.dart';

class HomePageSmall extends StatefulWidget {
  const HomePageSmall({super.key});
  
  @override
  State<HomePageSmall> createState() => _HomePageSmallState();
}

class _HomePageSmallState extends State<HomePageSmall> {
  User? _usuario;
  String? _selectedBudgetId;
  String? _selectedBudgetName;

  @override
  void initState() {
    super.initState();
    _usuario = FirebaseAuth.instance.currentUser;
    // Proteção de rota: se não houver usuário logado, redireciona para Login
    if (_usuario == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      });
    }
  }

  void _onBudgetSelected(String budgetId, String budgetName) {
    setState(() {
      _selectedBudgetId = budgetId;
      _selectedBudgetName = budgetName;
    });
    Navigator.of(context).pop(); // Fecha o drawer ao selecionar um orçamento
  }

  @override
  Widget build(BuildContext context) {
    if (_usuario == null) {
      return const Scaffold();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text( _selectedBudgetName != null && _selectedBudgetName!.isNotEmpty 
        ? ""
        : "Selecione um orçamento",),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      drawer: Drawer(
        child: BudgetPage(onBudgetSelected: _onBudgetSelected),
      ),
      body: _selectedBudgetId != null
          ? BudgetDetailPage(
              budgetId: _selectedBudgetId!,
              budgetName: _selectedBudgetName!,
            )
          : const Center(
              child: Row(mainAxisAlignment: MainAxisAlignment.center,
                          children: [Text(
                'Abra o menu e selecione um orçamento',
                textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18), ),
                          Icon(Icons.menu) ],
                        ),),
               
             
            
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }
}
