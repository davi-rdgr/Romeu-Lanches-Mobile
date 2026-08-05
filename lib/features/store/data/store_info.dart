import 'package:romeu_lanches_mobile/features/orders/data/order_enums.dart';

/// `LojaInfoResponse` — taxa, tempo estimado e formas de pagamento habilitadas.
///
/// Nao inclui `aberta`: isso vem de `/public/loja/status`. A tela de
/// confirmacao normalmente precisa dos dois.
class StoreInfo {
  final double deliveryFee;
  final int estimatedMinutes;
  final bool acceptsPix;
  final bool acceptsCard;
  final bool acceptsCash;

  const StoreInfo({
    required this.deliveryFee,
    required this.estimatedMinutes,
    required this.acceptsPix,
    required this.acceptsCard,
    required this.acceptsCash,
  });

  factory StoreInfo.fromJson(Map<String, dynamic> json) => StoreInfo(
    deliveryFee: (json['taxaEntrega'] as num?)?.toDouble() ?? 0,
    estimatedMinutes: (json['tempoEstimadoMin'] as num?)?.toInt() ?? 0,
    acceptsPix: json['aceitaPix'] as bool? ?? false,
    acceptsCard: json['aceitaCartao'] as bool? ?? false,
    acceptsCash: json['aceitaDinheiro'] as bool? ?? false,
  );

  /// Oferecer no seletor **apenas** as formas habilitadas: mandar uma forma
  /// desligada em `POST /app/pedidos` volta `400 Forma de pagamento nao aceita`.
  List<PaymentMethod> get availablePaymentMethods => [
    if (acceptsPix) PaymentMethod.pix,
    if (acceptsCard) PaymentMethod.card,
    if (acceptsCash) PaymentMethod.cash,
  ];

  bool accepts(PaymentMethod method) => switch (method) {
    PaymentMethod.pix => acceptsPix,
    PaymentMethod.card => acceptsCard,
    PaymentMethod.cash => acceptsCash,
  };
}
