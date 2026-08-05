import 'package:romeu_lanches_mobile/features/addresses/data/address.dart';
import 'package:romeu_lanches_mobile/features/orders/data/order_enums.dart';

/// `StatusPedido`. A maquina de estados vive no backend; o app so exibe.
enum OrderStatus {
  awaitingPayment('AGUARDANDO_PAGAMENTO'),
  received('NOVO'),
  preparing('EM_PREPARO'),
  ready('PRONTO'),
  completed('CONCLUIDO'),
  cancelled('CANCELADO');

  const OrderStatus(this.apiValue);

  final String apiValue;

  static OrderStatus fromApi(String value) => values.firstWhere(
    (status) => status.apiValue == value,
    orElse: () => OrderStatus.received,
  );

  /// O texto muda entre entrega e retirada: `PRONTO` e o unico estado antes do
  /// fim, e significa coisas diferentes nos dois fluxos (nao existe um
  /// "saiu para entrega" separado na API).
  String labelFor(DeliveryMethod method) {
    final isDelivery = method == DeliveryMethod.delivery;
    return switch (this) {
      OrderStatus.awaitingPayment => 'Aguardando pagamento',
      OrderStatus.received => 'Pedido recebido',
      OrderStatus.preparing => 'Fazendo seu lanche',
      OrderStatus.ready => isDelivery
          ? 'Saindo para entrega'
          : 'Pronto para retirada',
      OrderStatus.completed => isDelivery ? 'Entregue' : 'Retirado',
      OrderStatus.cancelled => 'Cancelado',
    };
  }

  bool get isTerminal =>
      this == OrderStatus.completed || this == OrderStatus.cancelled;
}

class OrderItemAddOn {
  final String id;
  final String name;
  final double price;

  const OrderItemAddOn({
    required this.id,
    required this.name,
    required this.price,
  });

  factory OrderItemAddOn.fromJson(Map<String, dynamic> json) => OrderItemAddOn(
    id: json['id'] as String? ?? '',
    name: json['nome'] as String? ?? '',
    price: (json['preco'] as num?)?.toDouble() ?? 0,
  );
}

class OrderLineItem {
  final String id;
  final String name;

  /// Preco do produto no momento do pedido (snapshot), **sem** os adicionais.
  final double unitPrice;
  final int quantity;

  /// Total da linha, com os adicionais somados.
  final double subtotal;
  final String note;
  final List<OrderItemAddOn> addOns;

  const OrderLineItem({
    this.id = '',
    required this.name,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
    this.note = '',
    this.addOns = const [],
  });

  factory OrderLineItem.fromJson(Map<String, dynamic> json) => OrderLineItem(
    id: json['id'] as String? ?? '',
    name: json['nome'] as String? ?? '',
    unitPrice: (json['precoUnitario'] as num?)?.toDouble() ?? 0,
    quantity: (json['quantidade'] as num?)?.toInt() ?? 0,
    subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
    note: json['observacao'] as String? ?? '',
    addOns: ((json['adicionais'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(OrderItemAddOn.fromJson)
        .toList(growable: false),
  );

  String get addOnsLabel => addOns.map((addOn) => addOn.name).join(', ');
}

/// `PedidoResponse` — o pedido completo. Todos os valores vem calculados pelo
/// servidor; o app nunca recalcula nem envia preco.
class Order {
  final String id;

  /// Numero sequencial legivel, o que o cliente ve e fala no balcao.
  final int number;
  final OrderStatus status;
  final DeliveryMethod deliveryMethod;
  final PaymentMethod paymentMethod;

  /// `null` quando o pedido e de retirada.
  final Address? address;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String note;
  final DateTime createdAt;
  final List<OrderLineItem> items;

  const Order({
    required this.id,
    required this.number,
    required this.status,
    required this.deliveryMethod,
    required this.paymentMethod,
    this.address,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    this.note = '',
    required this.createdAt,
    this.items = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final endereco = json['endereco'];
    return Order(
      id: json['id'] as String,
      number: (json['numero'] as num?)?.toInt() ?? 0,
      status: OrderStatus.fromApi(json['status'] as String),
      deliveryMethod: DeliveryMethod.fromApi(json['tipoEntrega'] as String),
      paymentMethod: PaymentMethod.fromApi(json['formaPagamento'] as String),
      address: endereco is Map<String, dynamic>
          ? Address.fromJson(endereco)
          : null,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      deliveryFee: (json['taxaEntrega'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      note: json['observacao'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['criadoEm'] as String? ?? '') ??
          DateTime.now(),
      items: ((json['itens'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(OrderLineItem.fromJson)
          .toList(growable: false),
    );
  }

  int get itemsCount => items.fold(0, (sum, item) => sum + item.quantity);

  String get statusLabel => status.labelFor(deliveryMethod);

  /// Pedido em andamento — vale acompanhar (e fazer polling).
  bool get isActive => !status.isTerminal;

  /// PIX criado e ainda nao pago: da para (re)gerar o QR.
  bool get awaitsPixPayment =>
      paymentMethod == PaymentMethod.pix &&
      status == OrderStatus.awaitingPayment;

  /// Etapas mostradas no acompanhamento. Pedido PIX comeca uma etapa antes,
  /// esperando o pagamento.
  List<OrderStatus> get trackingSteps => [
    if (paymentMethod == PaymentMethod.pix) OrderStatus.awaitingPayment,
    OrderStatus.received,
    OrderStatus.preparing,
    OrderStatus.ready,
    OrderStatus.completed,
  ];

  /// Indice da etapa atual, ou `-1` se cancelado (fora da trilha).
  int get currentStepIndex =>
      status == OrderStatus.cancelled ? -1 : trackingSteps.indexOf(status);
}

/// `PedidoResumoResponse` — o que vem na listagem `GET /app/pedidos`. E um
/// payload menor que o [Order]: nao traz itens nem endereco.
class OrderSummary {
  final String id;
  final int number;
  final OrderStatus status;
  final DeliveryMethod deliveryMethod;
  final PaymentMethod paymentMethod;
  final String customerName;
  final double total;
  final int itemsCount;
  final DateTime createdAt;

  const OrderSummary({
    required this.id,
    required this.number,
    required this.status,
    required this.deliveryMethod,
    required this.paymentMethod,
    this.customerName = '',
    required this.total,
    required this.itemsCount,
    required this.createdAt,
  });

  factory OrderSummary.fromJson(Map<String, dynamic> json) => OrderSummary(
    id: json['id'] as String,
    number: (json['numero'] as num?)?.toInt() ?? 0,
    status: OrderStatus.fromApi(json['status'] as String),
    deliveryMethod: DeliveryMethod.fromApi(json['tipoEntrega'] as String),
    paymentMethod: PaymentMethod.fromApi(json['formaPagamento'] as String),
    customerName: json['nomeCliente'] as String? ?? '',
    total: (json['total'] as num?)?.toDouble() ?? 0,
    itemsCount: (json['quantidadeItens'] as num?)?.toInt() ?? 0,
    createdAt:
        DateTime.tryParse(json['criadoEm'] as String? ?? '') ?? DateTime.now(),
  );

  factory OrderSummary.fromOrder(Order order) => OrderSummary(
    id: order.id,
    number: order.number,
    status: order.status,
    deliveryMethod: order.deliveryMethod,
    paymentMethod: order.paymentMethod,
    total: order.total,
    itemsCount: order.itemsCount,
    createdAt: order.createdAt,
  );

  String get statusLabel => status.labelFor(deliveryMethod);

  bool get isActive => !status.isTerminal;
}
