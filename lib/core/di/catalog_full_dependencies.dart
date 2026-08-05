import 'package:romeu_lanches_mobile/core/network/api_client.dart';
import 'package:romeu_lanches_mobile/features/catalog/data/catalog_controller.dart';
import 'package:romeu_lanches_mobile/features/catalog/data/catalog_repository.dart';

class CatalogFullDependencies {
  late final CatalogRepository repository;
  late final CatalogController catalog;

  CatalogFullDependencies(ApiClient api) {
    repository = CatalogRepository(api);
    catalog = CatalogController(repository);
  }
}
