import 'package:romeu_lanches_mobile/core/network/api_exception.dart';
import 'package:romeu_lanches_mobile/features/catalog/data/add_on.dart';
import 'package:romeu_lanches_mobile/features/catalog/data/catalog_repository.dart';
import 'package:romeu_lanches_mobile/features/catalog/data/menu_category.dart';
import 'package:romeu_lanches_mobile/features/catalog/data/menu_item.dart';
import 'package:signals_flutter/signals_flutter.dart';

class CatalogController {
  final CatalogRepository _repository;

  CatalogController(this._repository);

  final categories = signal<List<MenuCategory>>([]);
  final selectedCategoryId = signal<String?>(null);
  final searchText = signal('');
  final isLoading = signal(false);
  final errorMessage = signal<String?>(null);

  /// Adicionais por produto, buscados sob demanda na tela de detalhes.
  final _addOnsCache = <String, List<AddOn>>{};

  late final allItems = computed(
    () => categories.value.expand((category) => category.items).toList(),
  );

  late final selectedCategory = computed(() {
    final list = categories.value;
    if (list.isEmpty) return null;
    final id = selectedCategoryId.value;
    for (final category in list) {
      if (category.id == id) return category;
    }
    return list.first;
  });

  late final selectedItems = computed(
    () => selectedCategory.value?.items ?? const <MenuItem>[],
  );

  late final isSearching = computed(() => searchText.value.trim().isNotEmpty);

  late final searchResults = computed(() {
    final term = _fold(searchText.value.trim());
    if (term.isEmpty) return const <MenuItem>[];
    return allItems.value
        .where(
          (item) =>
              _fold(item.name).contains(term) ||
              _fold(item.description).contains(term),
        )
        .toList(growable: false);
  });

  /// A API nao tem flag de destaque; usamos os primeiros itens na ordem que o
  /// backend definiu (`ordem` de categoria e produto).
  late final highlightedItems = computed(
    () => allItems.value.take(6).toList(growable: false),
  );

  late final isEmpty = computed(
    () => !isLoading.value && errorMessage.value == null && allItems.value.isEmpty,
  );

  Future<void> load() async {
    if (isLoading.value) return;
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final result = await _repository.fetchMenu();
      categories.value = result;

      // O cardapio muda pelo admin: a categoria selecionada pode ter saido.
      final current = selectedCategoryId.value;
      final stillThere = result.any((category) => category.id == current);
      if (!stillThere) {
        selectedCategoryId.value = result.isEmpty ? null : result.first.id;
      }
    } on ApiException catch (error) {
      errorMessage.value = error.displayMessage;
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<AddOn>> addOnsFor(String productId) async {
    final cached = _addOnsCache[productId];
    if (cached != null) return cached;
    final result = await _repository.fetchAddOns(productId);
    _addOnsCache[productId] = result;
    return result;
  }

  Future<MenuItem> fetchProduct(String id) => _repository.fetchProduct(id);

  void selectCategory(String id) => selectedCategoryId.value = id;
  void setSearchText(String value) => searchText.value = value;
  void clearSearch() => searchText.value = '';

  MenuItem? findById(String id) {
    for (final item in allItems.value) {
      if (item.id == id) return item;
    }
    return null;
  }

  /// Busca sem acento e sem caixa: "bauru file" acha "Bauru Filé".
  static String _fold(String value) {
    const from = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
    const to = 'aaaaaeeeeiiiiooooouuuucn';
    final lower = value.toLowerCase();
    final buffer = StringBuffer();
    for (final char in lower.split('')) {
      final index = from.indexOf(char);
      buffer.write(index == -1 ? char : to[index]);
    }
    return buffer.toString();
  }

  void dispose() {
    selectedCategoryId.dispose();
    searchText.dispose();
    categories.dispose();
    isLoading.dispose();
    errorMessage.dispose();
    allItems.dispose();
    selectedCategory.dispose();
    selectedItems.dispose();
    isSearching.dispose();
    searchResults.dispose();
    highlightedItems.dispose();
    isEmpty.dispose();
  }
}
