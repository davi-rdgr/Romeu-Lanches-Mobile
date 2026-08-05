/// Produto do cardapio (`ProdutoResponse` da API).
class MenuItem {
  final String id;
  final String categoryId;
  final String categoryName;
  final String name;
  final String description;
  final double price;
  final bool available;
  final String? imageUrl;
  final int order;

  const MenuItem({
    required this.id,
    required this.categoryId,
    this.categoryName = '',
    required this.name,
    this.description = '',
    required this.price,
    this.available = true,
    this.imageUrl,
    this.order = 0,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) => MenuItem(
    id: json['id'] as String,
    categoryId: json['categoriaId'] as String,
    categoryName: json['categoriaNome'] as String? ?? '',
    name: json['nome'] as String,
    description: json['descricao'] as String? ?? '',
    price: (json['preco'] as num).toDouble(),
    available: json['disponivel'] as bool? ?? true,
    imageUrl: (json['imagemUrl'] as String?)?.trim().isEmpty ?? true
        ? null
        : json['imagemUrl'] as String,
    order: (json['ordem'] as num?)?.toInt() ?? 0,
  );
}
