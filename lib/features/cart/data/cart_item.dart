import 'package:romeu_lanches_mobile/features/catalog/data/add_on.dart';
import 'package:romeu_lanches_mobile/features/catalog/data/menu_item.dart';

/// Uma linha do carrinho. A identidade **nao** e o produto: dois X-Burger, um
/// com bacon e outro sem, sao duas linhas distintas — do mesmo jeito que a API
/// aceita `adicionalIds` e `observacao` por item.
///
/// A chave e a [lineKey]: linhas com mesmo produto, mesmos adicionais e mesma
/// observacao se juntam somando a quantidade.
class CartItem {
  final MenuItem product;
  final int quantity;
  final List<AddOn> addOns;
  final String note;

  const CartItem({
    required this.product,
    required this.quantity,
    this.addOns = const [],
    this.note = '',
  });

  /// Preco do produto + adicionais. So para exibicao: o total que vale e o que
  /// o servidor calcula em `POST /app/pedidos` (o front nunca envia preco).
  double get unitPrice =>
      product.price + addOns.fold(0.0, (sum, addOn) => sum + addOn.price);

  double get subtotal => unitPrice * quantity;

  String get addOnsLabel => addOns.map((addOn) => addOn.name).join(', ');

  String get lineKey {
    final ids = addOns.map((addOn) => addOn.id).toList()..sort();
    return '${product.id}|${ids.join(',')}|${note.trim().toLowerCase()}';
  }

  CartItem copyWith({int? quantity}) => CartItem(
    product: product,
    quantity: quantity ?? this.quantity,
    addOns: addOns,
    note: note,
  );

  /// Item no formato de `CriarPedidoRequest.itens`.
  Map<String, dynamic> toRequestJson() => {
    'produtoId': product.id,
    'quantidade': quantity,
    if (addOns.isNotEmpty)
      'adicionalIds': addOns.map((addOn) => addOn.id).toList(),
    if (note.trim().isNotEmpty) 'observacao': note.trim(),
  };
}
