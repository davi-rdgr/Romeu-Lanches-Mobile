/// `EnderecoResponse` / `EnderecoRequest`.
///
/// Escopado ao cliente do token. A remocao e soft delete: some da listagem e
/// nao pode mais ser usada em pedidos.
class Address {
  /// Vazio quando o endereco ainda nao foi salvo.
  final String id;
  final String street;
  final String number;
  final String district;
  final String complement;
  final String reference;

  const Address({
    this.id = '',
    required this.street,
    required this.number,
    required this.district,
    this.complement = '',
    this.reference = '',
  });

  factory Address.fromJson(Map<String, dynamic> json) => Address(
    id: json['id'] as String? ?? '',
    street: json['rua'] as String? ?? '',
    number: json['numero'] as String? ?? '',
    district: json['bairro'] as String? ?? '',
    complement: json['complemento'] as String? ?? '',
    reference: json['referencia'] as String? ?? '',
  );

  Map<String, dynamic> toRequestJson() => {
    'rua': street.trim(),
    'numero': number.trim(),
    'bairro': district.trim(),
    'complemento': complement.trim(),
    'referencia': reference.trim(),
  };

  /// "Av. Brasil, 1200 - Centro"
  String get summary {
    final base = '$street, $number';
    return district.isEmpty ? base : '$base - $district';
  }

  /// "ap 302 - ao lado da praca"
  String get details =>
      [complement, reference].where((part) => part.isNotEmpty).join(' - ');
}
