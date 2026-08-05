import 'package:romeu_lanches_mobile/core/network/api_client.dart';
import 'package:romeu_lanches_mobile/features/addresses/data/address.dart';

class AddressRepository {
  final ApiClient _api;

  const AddressRepository(this._api);

  /// Mais recentes primeiro.
  Future<List<Address>> fetchAll() async {
    final json = await _api.get('/app/enderecos', authenticated: true);
    return (json as List)
        .cast<Map<String, dynamic>>()
        .map(Address.fromJson)
        .toList(growable: false);
  }

  Future<Address> create(Address address) async {
    final json = await _api.post(
      '/app/enderecos',
      body: address.toRequestJson(),
    );
    return Address.fromJson(json as Map<String, dynamic>);
  }

  Future<Address> update(Address address) async {
    final json = await _api.put(
      '/app/enderecos/${address.id}',
      body: address.toRequestJson(),
    );
    return Address.fromJson(json as Map<String, dynamic>);
  }

  /// 204 sem corpo. Soft delete no backend.
  Future<void> remove(String id) => _api.delete('/app/enderecos/$id');
}
