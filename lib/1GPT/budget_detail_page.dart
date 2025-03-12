// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:sprint/alerts/snackbar.dart';
import 'package:sprint/model/budget_item_model.dart';
import 'package:sprint/model/text_field.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';

class BudgetDetailPage extends StatefulWidget {
  final String budgetName;
  final String? budgetId;
  const BudgetDetailPage(
      {super.key, required this.budgetId, required this.budgetName});

  @override
  State<BudgetDetailPage> createState() => _BudgetDetailPageState();
}

class _BudgetDetailPageState extends State<BudgetDetailPage> {
  bool isLoading = true;
  late bool isValid;
  final CollectionReference budgetsCollection =
      FirebaseFirestore.instance.collection('budgets');
  final ImagePicker _picker = ImagePicker();
  int? _editingIndex;
  double totalPrice = 0.0;

  // Controladores de Texto
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _supplierController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _imageLinkController = TextEditingController();
  final MoneyMaskedTextController _priceController = MoneyMaskedTextController(
    decimalSeparator: ',',
    thousandSeparator: '.',
    leftSymbol: 'R\$ ',
  );

  Uint8List? _selectedImageBytes;
  @override
  void initState() {
    super.initState();
    _calculateTotalPrice();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: budgetsCollection.doc(widget.budgetId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          if (!isLoading) {
            return buildBudgetId(context, snapshot.data!);
          }
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ); // Mostra um carregamento antes de decidir qual tela exibir
        }

        // Se não houver dados ou o orçamento foi excluído, exibe a tela vazia
        if (!snapshot.hasData ||
            snapshot.data == null ||
            !snapshot.data!.exists) {
          return buildBudgetIdIsEmpty(context);
        }

        // Se os dados existem, exibe a tela do orçamento
        return buildBudgetId(context, snapshot.data!);
      },
    );
  }

  /// Tela de orçamento válido
  Widget buildBudgetId(BuildContext context, DocumentSnapshot snapshot) {
    isLoading = false;
    var budget = snapshot.data() as Map<String, dynamic>;
    var items = budget['items'] as List<dynamic>? ?? [];
    double totalPrice =
        items.fold(0, (total, item) => total + (item['price'] ?? 0));

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalhes de(a) ${widget.budgetName}'),
        actions: [
          ElevatedButton(
            onPressed: () {
              _showMyDialog(context);
            },
            child: const Text('Adicionar Item'),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                return BudgetItemModel(
                  item: items[index],
                  delete: () {
                    _deleteItem(index);
                  },
                  editar: () {
                    _editItem(index, items[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Valor total do orçamento: R\$ ${totalPrice.toStringAsFixed(2).replaceAll(".", ",")}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// Tela para quando o orçamento não for encontrado
  Widget buildBudgetIdIsEmpty(BuildContext context) {
    if (MediaQuery.of(context).size.width < 600) {
      return Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Abra o menu e selecione um orçamento',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            Icon(Icons.menu)
          ],
        ),
      );

      // Celular
    } else {
      return Center(
        child: Text('Selecione um orçamento'),
      );
    }
  }

  void _showSnackbar(String message) {
    final overlay = Overlay.of(context);

    final overlayEntry = OverlayEntry(
      builder: (context) => OverlaySnackbar(
        message: message,
        color: Colors.red,
      ),
    );

    overlay.insert(overlayEntry);

    // Remove a Snackbar após 3 segundos
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  ///prepara controlers para edição
  void _editItem(int index, dynamic item) {
    _itemController.text = item['name']?.toString() ?? '';
    _priceController.text = item['price']?.toString() ?? '';
    _supplierController.text = item['supplier']?.toString() ?? '';
    _descriptionController.text = item['description']?.toString() ?? '';
    _imageLinkController.text = item['image']?.toString() ?? '';

    _editingIndex = index;
    _showMyDialog(context);
  }

  /// Método para fazer upload da imagem no Firebase Storage
  Future<String?> _uploadImage(Uint8List imageBytes) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref =
          FirebaseStorage.instance.ref().child('budget_items/$fileName');

      UploadTask uploadTask = ref.putData(imageBytes);
      TaskSnapshot snapshot = await uploadTask.whenComplete(() => null);
      String downloadUrl = await snapshot.ref.getDownloadURL();

      print("✅ Upload concluído: $downloadUrl");
      return downloadUrl;
    } catch (e) {
      print("❌ Erro ao fazer upload da imagem: $e");
      return null;
    }
  }

  /// Método para verificar se a imagem do link é válida
  Future<bool> _isImageValid(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Método para selecionar uma imagem do dispositivo
  Future<void> _pickImage() async {
    try {
      XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        _selectedImageBytes = await pickedFile.readAsBytes();
        setState(() {});
        print("📸 Imagem selecionada!");
      } else {
        print("⚠️ Nenhuma imagem foi selecionada.");
      }
    } catch (e) {
      print("❌ Erro ao selecionar imagem: $e");
    }
  }

  /// Método para adicionar um item ao orçamento no Firebase
  Future<void> _addItem() async {
    try {
      String? imageUrl;

      if (_imageLinkController.text.isNotEmpty) {
        // Verifica se o link da imagem é válido
        isValid = await _isImageValid(_imageLinkController.text);
        if (!isValid) {
          _showSnackbar("Imagem bloqueada pelo fornecedor");
          return;
        }
        imageUrl = _imageLinkController.text;
      }

      if (_selectedImageBytes != null && imageUrl == null) {
        print("⬆️ Iniciando upload da imagem...");
        imageUrl = await _uploadImage(_selectedImageBytes!);
      }

      var doc = await budgetsCollection.doc(widget.budgetId).get();
      if (!doc.exists) {
        print("❌ Erro: Orçamento não encontrado.");
        return;
      }
      num? priceValue = _priceController.numberValue;

      if (priceValue == 0) {
        _showSnackbar("Preço inválido. Digite um número válido.");
        return;
      }

      var budget = doc.data() as Map<String, dynamic>;
      List<dynamic> items = budget['items'] ?? [];
      if (_editingIndex != null) {
        // Estamos editando um item existente
        var oldItem = items[_editingIndex!];

        // Criar um novo mapa com os valores atualizados
        var updatedItem = {
          'name': _itemController.text.trim().isNotEmpty
              ? _itemController.text.trim()
              : oldItem['name'],
          'price': _priceController.text.trim().isNotEmpty
              ? priceValue
              : oldItem['price'],
          'supplier': _supplierController.text.trim().isNotEmpty
              ? _supplierController.text.trim()
              : oldItem['supplier'],
          'description': _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : oldItem['description'],
          'image': imageUrl ?? oldItem['image'],
        };

        // Atualiza somente se houver mudanças
        if (updatedItem != oldItem) {
          items[_editingIndex!] = updatedItem;
        }
      } else {
        // Criando um novo item
        var newItem = {
          'name': _itemController.text.trim(),
          'price': priceValue,
          'supplier': _supplierController.text.trim(),
          'description': _descriptionController.text.trim(),
          'image': imageUrl ?? '',
        };

        items.add(newItem);
      }

      await budgetsCollection.doc(widget.budgetId).update({'items': items});
      _navegationPop();
      _calculateTotalPrice();
      _clearFields();
    } catch (e) {
      print("❌ Erro ao adicionar item: $e");
    }
  }

  /// Nagation que não pode aconcer dentro de metodos async.
  void _navegationPop() {
    Navigator.of(context).pop();
  }

  /// Método para limpar os campos do formulário após salvar
  void _clearFields() {
    _itemController.clear();
    _priceController.clear();
    _supplierController.clear();
    _descriptionController.clear();
    _imageLinkController.clear();
    setState(() {
      _selectedImageBytes = null;
    });
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
                // Cabeçalho do Modal
                Row(
                  children: [
                    const Icon(Icons.add_shopping_cart,
                        color: Colors.white, size: 24),
                    const SizedBox(width: 10),
                    const Text(
                      'Adicionar Item',
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

                // Campos do Formulário
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextField(
                          controller: _itemController,
                          labelText: 'Nome do Item',
                          hintText: 'Exemplo: Placa de Vídeo'),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _priceController,
                        labelText: 'Preço',
                        hintText: 'Digite o preço',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                          controller: _supplierController,
                          labelText: 'Fornecedor',
                          hintText: 'Nome do fornecedor'),
                      const SizedBox(height: 12),
                      CustomTextField(
                          controller: _descriptionController,
                          labelText: 'Descrição',
                          hintText: 'Digite uma descrição detalhada',
                          maxLines: 5),
                      const SizedBox(height: 12),

                      // Campo de imagem e Upload
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _imageLinkController,
                              labelText: 'Link da Foto',
                              hintText: 'Cole um link direto (opcional)',
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.upload_file, size: 18),
                            label: const Text('Upload'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
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
                        _addItem();
                        if (isValid) {
                          Navigator.of(context).pop();
                        }
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

  ///deleta item
  void _deleteItem(int index) async {
    bool confirm = await _showConfirmationDialog();
    if (!confirm) return;

    var doc = await budgetsCollection.doc(widget.budgetId).get();
    if (!doc.exists) return;

    var budget = doc.data() as Map<String, dynamic>;
    List<dynamic> items = budget['items'] ?? [];

    items.removeAt(index);
    await budgetsCollection.doc(widget.budgetId).update({'items': items});
    _calculateTotalPrice();
    print("🗑️ Item deletado!");
  }

  ///popup confirnmação
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

  /// calcula o preço total do orçamento
  Future<void> _calculateTotalPrice() async {
    var doc = await budgetsCollection.doc(widget.budgetId).get();
    if (!doc.exists) return;

    var budget = doc.data() as Map<String, dynamic>;
    List<dynamic> items = budget['items'] ?? [];

    double total = 0.0;
    for (var item in items) {
      if (item['price'] is num) {
        total += (item['price'] as num).toDouble();
      }
    }

    setState(() {
      totalPrice = total;
    });
  }
}
