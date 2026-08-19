import 'dart:async';

import 'package:romeu_lanches_mobile/core/config/app_config.dart';
import 'package:romeu_lanches_mobile/core/network/api_exception.dart';
import 'package:romeu_lanches_mobile/core/network/realtime_client.dart';
import 'package:romeu_lanches_mobile/features/cart/data/cart_item.dart';
import 'package:romeu_lanches_mobile/features/orders/data/order.dart';
import 'package:romeu_lanches_mobile/features/orders/data/order_enums.dart';
import 'package:romeu_lanches_mobile/features/orders/data/orders_repository.dart';
import 'package:romeu_lanches_mobile/features/orders/data/pix_payment.dart';
import 'package:signals_flutter/signals_flutter.dart';

class OrdersController {
  final OrdersRepository _repository;

  OrdersController(this._repository);

  /// Historico (`PedidoResumoResponse`).
  final orders = signal<List<OrderSummary>>([]);

  /// Cache dos pedidos completos, por id.
  final details = signal<Map<String, Order>>({});

  final isLoading = signal(false);
  final errorMessage = signal<String?>(null);

  Timer? _pollTimer;
  String? _trackedId;

  late final activeOrders = computed(
    () => orders.value.where((order) => order.isActive).toList(growable: false),
  );

  Order? orderById(String id) => details.value[id];

  Future<void> load() async {
    if (isLoading.value) return;
    isLoading.value = true;
    errorMessage.value = null;
    try {
      orders.value = await _repository.fetchAll();
    } on ApiException catch (error) {
      errorMessage.value = error.displayMessage;
    } finally {
      isLoading.value = false;
    }
  }

  /// Monta o `CriarPedidoRequest` a partir do carrinho. Erros de regra (loja
  /// fechada, produto indisponivel, forma de pagamento nao aceita) sobem como
  /// `ApiException` para a tela decidir a mensagem.
  Future<Order> create({
    required List<CartItem> items,
    required DeliveryMethod deliveryMethod,
    required PaymentMethod paymentMethod,
    String? addressId,
    String note = '',
  }) async {
    final request = <String, dynamic>{
      'tipoEntrega': deliveryMethod.apiValue,
      'formaPagamento': paymentMethod.apiValue,
      // Ignorado em RETIRADA; obrigatorio em ENTREGA.
      if (deliveryMethod == DeliveryMethod.delivery && addressId != null)
        'enderecoId': addressId,
      if (note.trim().isNotEmpty) 'observacao': note.trim(),
      'itens': items.map((item) => item.toRequestJson()).toList(),
    };

    final order = await _repository.create(request);
    _store(order);
    orders.value = [OrderSummary.fromOrder(order), ...orders.value];
    return order;
  }

  Future<Order?> refreshOrder(String id) async {
    try {
      final order = await _repository.fetchById(id);
      _store(order);
      _patchSummary(order);
      return order;
    } on ApiException {
      // Falha de rede num refresh nao derruba a tela: o dado anterior segue.
      return details.value[id];
    }
  }

  Future<PixPayment> requestPixPayment(String orderId) =>
      _repository.requestPixPayment(orderId);

  /// Evento do canal `/topic/cliente/{id}`. O `dado` e o `PedidoResponse`
  /// completo, entao da para atualizar o cache e a listagem sem ir na API.
  ///
  /// Serve para `PEDIDO_CRIADO` e `STATUS_ATUALIZADO` sem distincao: os dois
  /// carregam o pedido inteiro, e gravar o estado mais novo resolve os dois
  /// casos (inserir na listagem ou trocar o status).
  void applyRealtimeEvent(RealtimeEvent event) {
    final Order order;
    try {
      order = Order.fromJson(event.data);
    } catch (_) {
      // Payload inesperado (campo novo obrigatorio, formato mudado): o polling
      // ainda traz o estado certo, entao nao vale derrubar nada aqui.
      return;
    }

    _store(order);
    _patchSummary(order);

    // O pedido acompanhado terminou: nao ha mais o que esperar.
    if (_trackedId == order.id && !order.isActive) stopTracking();
  }

  /// Polling do acompanhamento. Enquanto o WebSocket nao estiver ligado, e o
  /// refetch que move a tela — e mesmo depois ele fica como fallback, porque o
  /// envio dos eventos e best-effort.
  void startTracking(String id) {
    if (_trackedId == id && _pollTimer != null) return;
    stopTracking();
    _trackedId = id;
    refreshOrder(id);
    _pollTimer = Timer.periodic(AppConfig.orderPollingInterval, (_) async {
      final order = await refreshOrder(id);
      // Pedido terminou: nao ha mais o que esperar.
      if (order != null && !order.isActive) stopTracking();
    });
  }

  void stopTracking() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _trackedId = null;
  }

  void _store(Order order) {
    details.value = {...details.value, order.id: order};
  }

  void _patchSummary(Order order) {
    final updated = OrderSummary.fromOrder(order);
    final index = orders.value.indexWhere((item) => item.id == order.id);
    if (index == -1) {
      orders.value = [updated, ...orders.value];
      return;
    }
    final next = [...orders.value];
    next[index] = updated;
    orders.value = next;
  }

  /// Sessao encerrada: o historico era de outro cliente.
  void clear() {
    stopTracking();
    orders.value = [];
    details.value = {};
    errorMessage.value = null;
  }

  void dispose() {
    stopTracking();
    orders.dispose();
    details.dispose();
    isLoading.dispose();
    errorMessage.dispose();
    activeOrders.dispose();
  }
}
