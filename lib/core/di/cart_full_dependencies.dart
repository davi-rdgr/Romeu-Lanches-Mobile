import 'package:romeu_lanches_mobile/features/cart/data/cart_controller.dart';
import 'package:romeu_lanches_mobile/features/catalog/data/catalog_controller.dart';
import 'package:romeu_lanches_mobile/features/store/data/store_controller.dart';

class CartFullDependencies {
  late final CartController cart;

  CartFullDependencies(CatalogController catalog, StoreController store) {
    cart = CartController(catalog, store);
  }
}
