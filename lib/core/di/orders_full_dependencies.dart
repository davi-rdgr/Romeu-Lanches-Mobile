import 'package:romeu_lanches_mobile/core/network/api_client.dart';
import 'package:romeu_lanches_mobile/features/orders/data/orders_controller.dart';
import 'package:romeu_lanches_mobile/features/orders/data/orders_repository.dart';

class OrdersFullDependencies {
  late final OrdersRepository repository;
  late final OrdersController orders;

  OrdersFullDependencies(ApiClient api) {
    repository = OrdersRepository(api);
    orders = OrdersController(repository);
  }
}
