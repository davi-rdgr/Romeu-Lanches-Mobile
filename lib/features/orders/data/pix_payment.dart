/// `StatusPagamento`.
enum PaymentStatus {
  pending('PENDENTE'),
  approved('APROVADO'),
  refused('RECUSADO'),
  expired('EXPIRADO'),
  cancelled('CANCELADO');

  const PaymentStatus(this.apiValue);

  final String apiValue;

  static PaymentStatus fromApi(String value) => values.firstWhere(
    (status) => status.apiValue == value,
    orElse: () => PaymentStatus.pending,
  );
}

/// `PagamentoResponse` — a cobranca PIX gerada no Mercado Pago.
///
/// O app **nunca** confirma o pagamento: a confirmacao chega pelo webhook e o
/// pedido passa de `AGUARDANDO_PAGAMENTO` para `NOVO`. Aqui so exibimos o QR e
/// esperamos.
class PixPayment {
  /// Codigo copia e cola.
  final String copyPasteCode;

  /// PNG em base64, **sem** o prefixo `data:`.
  final String qrBase64;

  /// Vence em 30 minutos. Um job do backend varre a cada 5 min e cancela o
  /// pedido quando o PIX expira.
  final DateTime? expiresAt;
  final double amount;
  final PaymentStatus status;

  const PixPayment({
    required this.copyPasteCode,
    required this.qrBase64,
    this.expiresAt,
    required this.amount,
    required this.status,
  });

  factory PixPayment.fromJson(Map<String, dynamic> json) => PixPayment(
    copyPasteCode: json['pixCopiaCola'] as String? ?? '',
    qrBase64: json['pixQrBase64'] as String? ?? '',
    expiresAt: DateTime.tryParse(json['expiraEm'] as String? ?? ''),
    amount: (json['valor'] as num?)?.toDouble() ?? 0,
    status: PaymentStatus.fromApi(json['status'] as String? ?? 'PENDENTE'),
  );

  Duration get remaining {
    final deadline = expiresAt;
    if (deadline == null) return Duration.zero;
    final left = deadline.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  bool get isExpired => remaining == Duration.zero;
}
