import 'package:flutter/material.dart';

class BudgetItemModel extends StatefulWidget {
  final Map<String, dynamic> item;
  final Function() delete;
  final Function() editar;

  const BudgetItemModel({
    super.key,
    required this.item,
    required this.delete,
    required this.editar,
  });

  @override
  State<BudgetItemModel> createState() => _BudgetItemModelState();
}

class _BudgetItemModelState extends State<BudgetItemModel> {
  bool _isExpanded = false; // Define se o item está expandido ou não

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded; // Alterna entre expandido e recolhido
        });
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        color: Colors.grey[900], // Fundo escuro elegante
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300), // Animação suave
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Linha principal (imagem, nome e preço)
              Row(
                children: [
                  // Imagem pequena com sombra
                  widget.item['image'] != null && widget.item['image']!.isNotEmpty
                      ? Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(3, 3),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              widget.item['image'],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      : Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                        ),

                  const SizedBox(width: 12),

                  // Nome e preço do item
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item['name'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Preço: ${widget.item['price']}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Ícone de expansão
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white,
                    size: 30,
                  ),
                ],
              ),

              // Se estiver expandido, exibe os detalhes extras
              if (_isExpanded)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(color: Colors.white24),

                      // Fornecedor
                      Text(
                        "Fornecedor: ${widget.item['supplier'] ?? 'Não informado'}",
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),

                      // Descrição
                      Text(
                        "Descrição:",
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.item['description'] ?? 'Sem descrição disponível',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),

                      // Imagem em tamanho maior
                      if (widget.item['image'] != null && widget.item['image']!.isNotEmpty)
                        Center(
                          child: Container(constraints: BoxConstraints(maxHeight: 500,maxWidth: 500),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                widget.item['image'],
                                
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 12),

                      // Botões de Editar e Excluir
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: widget.editar,
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            label: const Text("Editar", style: TextStyle(color: Colors.blue)),
                          ),
                          TextButton.icon(
                            onPressed: widget.delete,
                            icon: const Icon(Icons.delete, color: Colors.red),
                            label: const Text("Excluir", style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
