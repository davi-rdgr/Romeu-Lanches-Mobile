import 'package:romeu_lanches_mobile/features/catalog/data/menu_item.dart';

/// Categoria do cardapio com seus produtos (`CategoriaCardapioResponse`).
///
/// `/public/cardapio` ja devolve so categorias ativas que tenham ao menos um
/// produto disponivel, e os produtos ja vem ordenados — nao ha o que filtrar
/// nem reordenar aqui.
class MenuCategory {
  final String id;
  final String name;
  final int order;
  final List<MenuItem> items;

  const MenuCategory({
    required this.id,
    required this.name,
    this.order = 0,
    this.items = const [],
  });

  factory MenuCategory.fromJson(Map<String, dynamic> json) => MenuCategory(
    id: json['id'] as String,
    name: json['nome'] as String,
    order: (json['ordem'] as num?)?.toInt() ?? 0,
    items: ((json['produtos'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(MenuItem.fromJson)
        .toList(growable: false),
  );
}
