import 'dart:convert';

/// Sessao do cliente logado. O backend nao tem endpoint de perfil, entao tudo o
/// que sabemos vem do login: o token, o `nome` da resposta e o CPF/telefone que
/// o proprio cliente digitou.
class Session {
  final String token;
  final String name;
  final String cpf;
  final String phone;

  /// `sub` do JWT — o id do cliente. Necessario para assinar o topico
  /// `/topic/cliente/{clienteId}` no WebSocket.
  final String? clienteId;

  /// `exp` do JWT (24h por padrao). Nao ha refresh token.
  final DateTime? expiresAt;

  const Session({
    required this.token,
    required this.name,
    required this.cpf,
    required this.phone,
    this.clienteId,
    this.expiresAt,
  });

  factory Session.fromLogin({
    required String token,
    required String name,
    required String cpf,
    required String phone,
  }) {
    final claims = _decodeClaims(token);
    final exp = claims?['exp'];
    return Session(
      token: token,
      name: name,
      cpf: cpf,
      phone: phone,
      clienteId: claims?['sub'] as String?,
      expiresAt: exp is int
          ? DateTime.fromMillisecondsSinceEpoch(exp * 1000)
          : null,
    );
  }

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  Map<String, dynamic> toJson() => {
    'token': token,
    'name': name,
    'cpf': cpf,
    'phone': phone,
  };

  factory Session.fromJson(Map<dynamic, dynamic> json) => Session.fromLogin(
    token: json['token'] as String,
    name: json['name'] as String? ?? '',
    cpf: json['cpf'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
  );

  static Map<String, dynamic>? _decodeClaims(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final decoded = jsonDecode(payload);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }
}
