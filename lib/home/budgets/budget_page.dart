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
  String? _selectedBudgetId;

  Future<void> _createBudget() async {
    if (_budgetController.text.isNotEmpty) {
      await budgetsCollection
          .add({'name': _budgetController.text, 'items': []});
      _budgetController.clear();
    }
  }

  Future<void> _editBudget(String budgetId) async {
    if (_budgetController.text.isNotEmpty) {
      await budgetsCollection
          .doc(budgetId)
          .update({'name': _budgetController.text});
      _budgetController.clear();
      setState(() {});
    }
  }

  Future<bool> _showConfirmationDialog() async {
    return await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("Confirmar Exclusão"),
              content:
                  const Text("Tem certeza de que deseja excluir este item?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("Cancelar"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("Excluir",
                      style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _deleteBudget(String budgetId) async {
    bool confirm = await _showConfirmationDialog();
    if (!confirm) return;

    if (_selectedBudgetId == budgetId) {
      setState(() {
        _selectedBudgetId = null;
      });
    }
    await budgetsCollection.doc(budgetId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão de Orçamentos'),
        actions: [
          IconButton(
            onPressed: () {
              _showMyDialog(context, isEditing: false);
            },
            icon: const Icon(Icons.add),
          )
        ],
      ),
      body: StreamBuilder(
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
              String budgetId = budget.id;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedBudgetId = budgetId;
                  });
                  widget.onBudgetSelected(budgetId, budgetName);
                },
                child: Container(
                  color: _selectedBudgetId == budgetId
                      ? Theme.of(context)
                          .colorScheme
                          .primary
                          .withAlpha((255 * 0.1).toInt())
                      : Colors.transparent,
                  child: ListTile(
                    title: Text(budget['name']),
                    trailing: GestureDetector(
                      onTapDown: (TapDownDetails details) {
                        _showConfigurations(context, budgetId, budgetName,
                            details.globalPosition);
                      },
                      child: const Icon(Icons.more_vert_outlined),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Exibe o Modal para adicionar ou editar um orçamento
  void _showMyDialog(BuildContext context,
      {required bool isEditing, String? budgetId, String? initialName}) {
    _budgetController.text = isEditing ? initialName ?? '' : '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
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
                    Text(
                      isEditing ? 'Editar Orçamento' : 'Criar Orçamento',
                      style: const TextStyle(
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
                CustomTextField(
                  controller: _budgetController,
                  labelText: 'Nome do Orçamento',
                ),
                const SizedBox(height: 20),
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
                        if (isEditing && budgetId != null) {
                          _editBudget(budgetId);
                        } else {
                          _createBudget();
                        }
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        isEditing ? "Atualizar" : "Salvar",
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16),
                      ),
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

  void _showConfigurations(BuildContext context, String budgetId,
      String budgetName, Offset position) async {
    final selected = await showMenu<int>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx, position.dy, // Usa as coordenadas do clique
        position.dx + 1, position.dy + 1, // Pequeno ajuste para alinhar melhor
      ),
      items: [
        PopupMenuItem<int>(
          value: 2,
          child: ListTile(
            leading: const Icon(Icons.edit),
            title: const Text("Editar"),
          ),
        ),
        PopupMenuItem<int>(
          value: 3,
          child: ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Excluir'),
          ),
        ),
      ],
    );

    if (selected != null) {
      switch (selected) {
        case 2:
          // ignore: use_build_context_synchronously
          _showMyDialog(context,
              isEditing: true, budgetId: budgetId, initialName: budgetName);
          break;
        case 3:
          _deleteBudget(budgetId);
          break;
      }
    }
  }
}
