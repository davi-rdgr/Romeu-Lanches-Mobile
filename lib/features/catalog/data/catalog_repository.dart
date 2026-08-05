import 'package:romeu_lanches_mobile/core/network/api_client.dart';
import 'package:romeu_lanches_mobile/features/catalog/data/add_on.dart';
import 'package:romeu_lanches_mobile/features/catalog/data/menu_category.dart';
import 'package:romeu_lanches_mobile/features/catalog/data/menu_item.dart';

/// Cardapio publico — nenhuma dessas rotas precisa de token, entao o cliente
/// nao logado navega no menu inteiro.
class CatalogRepository {
  final ApiClient _api;

  const CatalogRepository(this._api);

  Future<List<MenuCategory>> fetchMenu() async {
    final json = await _api.get('/public/cardapio');
    final categorias = (json as Map<String, dynamic>)['categorias'] as List?;
    return (categorias ?? const [])
        .cast<Map<String, dynamic>>()
        .map(MenuCategory.fromJson)
        .toList(growable: false);
  }

  /// Devolve o produto mesmo indisponivel ou de categoria inativa — util quando
  /// o cliente abre um item que saiu do cardapio.
  Future<MenuItem> fetchProduct(String id) async {
    final json = await _api.get('/public/produtos/$id');
    return MenuItem.fromJson(json as Map<String, dynamic>);
  }

  Future<List<AddOn>> fetchAddOns(String productId) async {
    final json = await _api.get('/public/produtos/$productId/adicionais');
    return (json as List)
        .cast<Map<String, dynamic>>()
        .map(AddOn.fromJson)
        .toList(growable: false);
  }
}
