import 'package:romeu_lanches_mobile/core/network/api_client.dart';
import 'package:romeu_lanches_mobile/features/store/data/store_controller.dart';
import 'package:romeu_lanches_mobile/features/store/data/store_repository.dart';

class StoreFullDependencies {
  late final StoreRepository repository;
  late final StoreController store;

  StoreFullDependencies(ApiClient api) {
    repository = StoreRepository(api);
    store = StoreController(repository);
  }
}
