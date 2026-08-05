import 'package:romeu_lanches_mobile/features/cart/data/cart_item.dart';
import 'package:romeu_lanches_mobile/features/catalog/data/add_on.dart';
import 'package:romeu_lanches_mobile/features/catalog/data/catalog_controller.dart';
import 'package:romeu_lanches_mobile/features/catalog/data/menu_item.dart';
import 'package:romeu_lanches_mobile/features/orders/data/order_enums.dart';
import 'package:romeu_lanches_mobile/features/store/data/store_controller.dart';
import 'package:signals_flutter/signals_flutter.dart';

class CartController {
  final CatalogController _catalog;
  final StoreController _store;

  CartController(this._catalog, this._store);

  final items = signal<List<CartItem>>([]);
  final deliveryMethod = signal(DeliveryMethod.delivery);

  /// Observacao do pedido inteiro (`CriarPedidoRequest.observacao`), diferente
  /// da observacao de cada item.
  final note = signal('');

  late final itemsCount = computed(
    () => items.value.fold(0, (sum, item) => sum + item.quantity),
  );

  late final subtotal = computed(
    () => items.value.fold(0.0, (sum, item) => sum + item.subtotal),
  );

  /// Taxa vigente da loja. O pedido guarda a taxa em snapshot, entao o valor
  /// aqui e so a previsao do momento.
  late final deliveryFee = computed(
    () => deliveryMethod.value == DeliveryMethod.delivery
        ? _store.deliveryFee.value
        : 0.0,
  );

  late final total = computed(() => subtotal.value + deliveryFee.value);

  late final isEmpty = computed(() => items.value.isEmpty);

  /// Adiciona uma linha. Se ja existe uma identica (mesmo produto, mesmos
  /// adicionais, mesma observacao), soma na quantidade em vez de duplicar.
  void addItem({
    required MenuItem product,
    int quantity = 1,
    List<AddOn> addOns = const [],
    String note = '',
  }) {
    final line = CartItem(
      product: product,
      quantity: quantity,
      addOns: List.unmodifiable(addOns),
      note: note.trim(),
    );

    final next = [...items.value];
    final index = next.indexWhere((item) => item.lineKey == line.lineKey);
    if (index == -1) {
      next.add(line);
    } else {
      next[index] = next[index].copyWith(
        quantity: next[index].quantity + quantity,
      );
    }
    items.value = next;
  }

  /// Atalho do botao "+" da listagem: uma unidade, sem adicionais.
  void addProduct(String productId) {
    final product = _catalog.findById(productId);
    if (product == null) return;
    addItem(product: product);
  }

  void increment(String lineKey) => _changeQuantity(lineKey, 1);

  void decrement(String lineKey) => _changeQuantity(lineKey, -1);

  void _changeQuantity(String lineKey, int delta) {
    final next = [...items.value];
    final index = next.indexWhere((item) => item.lineKey == lineKey);
    if (index == -1) return;

    final quantity = next[index].quantity + delta;
    if (quantity <= 0) {
      next.removeAt(index);
    } else {
      next[index] = next[index].copyWith(quantity: quantity);
    }
    items.value = next;
  }

  void remove(String lineKey) {
    items.value = items.value
        .where((item) => item.lineKey != lineKey)
        .toList(growable: false);
  }

  void clear() {
    items.value = [];
    note.value = '';
  }

  void selectDeliveryMethod(DeliveryMethod method) {
    deliveryMethod.value = method;
  }

  void setNote(String value) => note.value = value;

  /// Produtos que sairam do cardapio ou ficaram indisponiveis enquanto o
  /// carrinho estava montado — `POST /app/pedidos` recusa o pedido inteiro com
  /// `409 Produto indisponivel: X`, entao vale avisar antes.
  List<CartItem> unavailableItems() {
    return items.value.where((item) {
      final current = _catalog.findById(item.product.id);
      return current == null || !current.available;
    }).toList(growable: false);
  }

  void dispose() {
    items.dispose();
    deliveryMethod.dispose();
    note.dispose();
    itemsCount.dispose();
    subtotal.dispose();
    deliveryFee.dispose();
    total.dispose();
    isEmpty.dispose();
  }
}
