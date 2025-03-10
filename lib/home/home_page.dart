import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:sprint/home/budgets/budget_detail_page.dart';
import 'package:sprint/home/budgets/budget_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _multiViewController = MultiSplitViewController(
      areas: [Area(size: 300, min: 0.1), Area(min: 500)]);
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

  @override
  void dispose() {
    _multiViewController.dispose();
    super.dispose();
  }

  void _onBudgetSelected(String budgetId,String budgetName) {
    setState(() {
      _selectedBudgetId = budgetId;
      _selectedBudgetName =budgetName;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_usuario == null) {
      return const Scaffold();
    }

    return Scaffold(

      body: Column(
        children: [Row(mainAxisAlignment: MainAxisAlignment.end,children: [IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),],),
          Expanded(
            child: MultiSplitViewTheme(
              data: MultiSplitViewThemeData(
                  dividerPainter: DividerPainters.background(
                      color: Theme.of(context).focusColor, highlightedColor: Theme.of(context).colorScheme.primary)),
              child: MultiSplitView(
                controller: _multiViewController,
                builder: (context, area) {
                  if (area.index == 0) {
                    return BudgetPage(onBudgetSelected: _onBudgetSelected);
                  } else {
                    return _selectedBudgetId != null
                        ? BudgetDetailPage(budgetId: _selectedBudgetId!, budgetName: _selectedBudgetName!,)
                        : const Center(child: Text('Selecione um orçamento'));
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }
}

