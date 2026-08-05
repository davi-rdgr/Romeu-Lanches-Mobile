import 'package:romeu_lanches_mobile/core/network/api_client.dart';
import 'package:romeu_lanches_mobile/features/orders/data/order.dart';
import 'package:romeu_lanches_mobile/features/orders/data/pix_payment.dart';

class OrdersRepository {
  final ApiClient _api;

  const OrdersRepository(this._api);

  /// `POST /app/pedidos` — 201. O corpo nao leva preco nem total: o servidor
  /// calcula tudo e congela o snapshot no pedido.
  Future<Order> create(Map<String, dynamic> request) async {
    final json = await _api.post('/app/pedidos', body: request);
    return Order.fromJson(json as Map<String, dynamic>);
  }

  /// So os pedidos do cliente autenticado.
  Future<List<OrderSummary>> fetchAll() async {
    final json = await _api.get('/app/pedidos', authenticated: true);
    return (json as List)
        .cast<Map<String, dynamic>>()
        .map(OrderSummary.fromJson)
        .toList(growable: false);
  }

  Future<Order> fetchById(String id) async {
    final json = await _api.get('/app/pedidos/$id', authenticated: true);
    return Order.fromJson(json as Map<String, dynamic>);
  }

  /// Gera (ou reaproveita) a cobranca PIX. E idempotente: se ja existe um PIX
  /// pendente e nao expirado, devolve o mesmo QR.
  Future<PixPayment> requestPixPayment(String orderId) async {
    final json = await _api.post('/app/pedidos/$orderId/pagamento');
    return PixPayment.fromJson(json as Map<String, dynamic>);
  }
}
