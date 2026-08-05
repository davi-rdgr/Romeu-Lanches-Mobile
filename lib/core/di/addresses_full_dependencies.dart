import 'package:romeu_lanches_mobile/core/network/api_client.dart';
import 'package:romeu_lanches_mobile/features/addresses/data/address_controller.dart';
import 'package:romeu_lanches_mobile/features/addresses/data/address_repository.dart';

class AddressesFullDependencies {
  late final AddressRepository repository;
  late final AddressController addresses;

  AddressesFullDependencies(ApiClient api) {
    repository = AddressRepository(api);
    addresses = AddressController(repository);
  }
}
