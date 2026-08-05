// Enums do pedido, espelhando os do backend. `apiValue` e exatamente a string
// que a API aceita e devolve — sempre em MAIUSCULAS.

/// `TipoEntrega`.
enum DeliveryMethod {
  delivery('ENTREGA', 'Entrega'),
  pickup('RETIRADA', 'Retirada');

  const DeliveryMethod(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static DeliveryMethod fromApi(String value) => values.firstWhere(
    (method) => method.apiValue == value,
    orElse: () => DeliveryMethod.delivery,
  );
}

/// `FormaPagamento`. Somente PIX tem gateway (Mercado Pago); cartao e dinheiro
/// sao pagos na entrega ou na retirada.
enum PaymentMethod {
  pix('PIX', 'Pix'),
  card('CARTAO', 'Cartao'),
  cash('DINHEIRO', 'Dinheiro');

  const PaymentMethod(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static PaymentMethod fromApi(String value) => values.firstWhere(
    (method) => method.apiValue == value,
    orElse: () => PaymentMethod.cash,
  );
}
