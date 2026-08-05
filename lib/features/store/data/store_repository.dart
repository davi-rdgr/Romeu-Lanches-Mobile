import 'package:romeu_lanches_mobile/core/network/api_client.dart';
import 'package:romeu_lanches_mobile/features/store/data/business_hours.dart';
import 'package:romeu_lanches_mobile/features/store/data/store_info.dart';

class StoreRepository {
  final ApiClient _api;

  const StoreRepository(this._api);

  /// `/public/loja/status` so expoe `aberta` — e a unica fonte de verdade sobre
  /// a loja aceitar pedidos agora.
  Future<bool> fetchIsOpen() async {
    final json = await _api.get('/public/loja/status');
    return (json as Map<String, dynamic>)['aberta'] as bool? ?? false;
  }

  Future<StoreInfo> fetchInfo() async {
    final json = await _api.get('/public/loja/info');
    return StoreInfo.fromJson(json as Map<String, dynamic>);
  }

  /// Os 7 dias, ja ordenados de Segunda (1) a Domingo (7).
  Future<List<BusinessHours>> fetchHours() async {
    final json = await _api.get('/public/loja/horarios');
    return (json as List)
        .cast<Map<String, dynamic>>()
        .map(BusinessHours.fromJson)
        .toList(growable: false);
  }
}
