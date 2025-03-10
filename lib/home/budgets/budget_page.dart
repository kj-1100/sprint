import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sprint/model/text_field.dart';

class BudgetPage extends StatefulWidget {
  final Function(String, String) onBudgetSelected;
  const BudgetPage({super.key, required this.onBudgetSelected});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  final TextEditingController _budgetController = TextEditingController();
  final CollectionReference budgetsCollection =
      FirebaseFirestore.instance.collection('budgets');

  Future<void> _createBudget() async {
    if (_budgetController.text.isNotEmpty) {
      await budgetsCollection
          .add({'name': _budgetController.text, 'items': []});
      _budgetController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão de Orçamentos'),
        actions: [
          IconButton(
            onPressed: () {
              _showMyDialog(context);
            },
            icon: const Icon(Icons.add),
          )
        ],
      ),
      body: Expanded(
        child: StreamBuilder(
          stream: budgetsCollection.snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            var budgets = snapshot.data!.docs;
            return ListView.builder(
              itemCount: budgets.length,
              itemBuilder: (context, index) {
                var budget = budgets[index];
                String budgetName = budget['name'];
                return ListTile(
                  title: Text(budget['name']),
                  onTap: () => widget.onBudgetSelected(budget.id, budgetName),
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// Exibe o Modal para adicionar item
  void _showMyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            constraints: BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((255 * 0.3).toInt()),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.add_shopping_cart,
                        color: Colors.white, size: 24),
                    const SizedBox(width: 10),
                    const Text(
                      'Criar Orçamento',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(color: Colors.white24),
                const SizedBox(height: 16),

                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextField(
                        controller: _budgetController,
                        labelText: 'Nome do Orçamento',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const SizedBox(height: 20),

                // Botões do Modal
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("Cancelar",
                          style: TextStyle(color: Colors.red, fontSize: 16)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _createBudget();
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Salvar",
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
