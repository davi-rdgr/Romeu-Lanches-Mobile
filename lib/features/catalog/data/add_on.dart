/// Adicional (`AdicionalResponse`).
///
/// O vinculo no backend e adicional <-> **categoria**, nao adicional <-> produto:
/// um adicional so pode entrar num item se estiver vinculado a categoria daquele
/// produto. Por isso os adicionais de um item vem sempre de
/// `/public/produtos/{id}/adicionais`, nunca da lista geral.
class AddOn {
  final String id;
  final String name;
  final double price;
  final bool active;

  const AddOn({
    required this.id,
    required this.name,
    required this.price,
    this.active = true,
  });

  factory AddOn.fromJson(Map<String, dynamic> json) => AddOn(
    id: json['id'] as String,
    name: json['nome'] as String,
    price: (json['preco'] as num).toDouble(),
    active: json['ativo'] as bool? ?? true,
  );
}
