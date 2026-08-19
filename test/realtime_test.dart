import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:romeu_lanches_mobile/core/network/api_client.dart';
import 'package:romeu_lanches_mobile/core/network/realtime_client.dart';
import 'package:romeu_lanches_mobile/features/orders/data/order.dart';
import 'package:romeu_lanches_mobile/features/orders/data/orders_controller.dart';
import 'package:romeu_lanches_mobile/features/orders/data/orders_repository.dart';

/// `PedidoResponse` como vem no `dado` do evento do canal do cliente.
Map<String, dynamic> _pedido({
  String id = 'ped-1',
  String status = 'NOVO',
}) => {
  'id': id,
  'numero': 1042,
  'status': status,
  'tipoEntrega': 'ENTREGA',
  'formaPagamento': 'PIX',
  'endereco': {
    'rua': 'Av. Brasil',
    'numero': '1200',
    'bairro': 'Centro',
    'complemento': null,
    'referencia': null,
  },
  'subtotal': 49.80,
  'taxaEntrega': 8.00,
  'total': 57.80,
  'observacao': '',
  'criadoEm': '2026-07-25T19:42:10.123-03:00',
  'itens': [
    {
      'id': 'item-1',
      'nome': 'X-Burger',
      'precoUnitario': 24.90,
      'quantidade': 2,
      'subtotal': 49.80,
      'observacao': '',
      'adicionais': [],
    },
  ],
};

String _envelope(String tipo, Map<String, dynamic> dado) =>
    jsonEncode({'tipo': tipo, 'dado': dado});

OrdersController _controller() {
  final api = ApiClient(
    tokenProvider: () => 'token',
    onUnauthorized: () {},
    httpClient: MockClient(
      (_) async => http.Response('{}', 500),
    ),
  );
  return OrdersController(OrdersRepository(api));
}

void main() {
  group('RealtimeEvent.tryParse', () {
    test('le o envelope do evento', () {
      final event = RealtimeEvent.tryParse(
        _envelope('STATUS_ATUALIZADO', _pedido(status: 'EM_PREPARO')),
      );

      expect(event, isNotNull);
      expect(event!.type, RealtimeEventType.statusUpdated);
      expect(event.data['status'], 'EM_PREPARO');
    });

    test('tipo desconhecido nao virra outro tipo', () {
      final event = RealtimeEvent.tryParse(
        _envelope('PEDIDO_ESTORNADO', _pedido()),
      );

      expect(event!.type, RealtimeEventType.unknown);
    });

    test('corpo invalido devolve null em vez de estourar', () {
      expect(RealtimeEvent.tryParse(null), isNull);
      expect(RealtimeEvent.tryParse(''), isNull);
      expect(RealtimeEvent.tryParse('nao e json'), isNull);
      expect(RealtimeEvent.tryParse('{"tipo":"PEDIDO_CRIADO"}'), isNull);
      expect(RealtimeEvent.tryParse('[]'), isNull);
    });
  });

  group('OrdersController.applyRealtimeEvent', () {
    test('PEDIDO_CRIADO entra no cache e na listagem', () {
      final orders = _controller();
      addTearDown(orders.dispose);

      orders.applyRealtimeEvent(
        RealtimeEvent.tryParse(_envelope('PEDIDO_CRIADO', _pedido()))!,
      );

      expect(orders.orderById('ped-1')?.number, 1042);
      expect(orders.orders.value.single.id, 'ped-1');
      expect(orders.activeOrders.value, hasLength(1));
    });

    test('STATUS_ATUALIZADO troca o status sem duplicar a linha', () {
      final orders = _controller();
      addTearDown(orders.dispose);

      orders.applyRealtimeEvent(
        RealtimeEvent.tryParse(
          _envelope('PEDIDO_CRIADO', _pedido(status: 'AGUARDANDO_PAGAMENTO')),
        )!,
      );
      orders.applyRealtimeEvent(
        RealtimeEvent.tryParse(
          _envelope('STATUS_ATUALIZADO', _pedido(status: 'CANCELADO')),
        )!,
      );

      expect(orders.orders.value, hasLength(1));
      expect(orders.orderById('ped-1')?.status, OrderStatus.cancelled);
      expect(orders.activeOrders.value, isEmpty);
    });

    test('payload quebrado e ignorado', () {
      final orders = _controller();
      addTearDown(orders.dispose);

      // Sem `id`: o `Order.fromJson` estoura, e o evento tem que morrer aqui.
      orders.applyRealtimeEvent(
        const RealtimeEvent(
          type: RealtimeEventType.statusUpdated,
          data: {'status': 'NOVO'},
        ),
      );

      expect(orders.orders.value, isEmpty);
      expect(orders.details.value, isEmpty);
    });
  });
}
