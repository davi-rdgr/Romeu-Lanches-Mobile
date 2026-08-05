/// Erro vindo do backend. Cobre os tres formatos documentados na secao 9 da API:
///
/// 1. `{"error": "mensagem"}`
/// 2. `{"error": "Dados invalidos", "campos": {"nome": "must not be blank"}}`
/// 3. `{"code": "NAO_CADASTRADO"}`
class ApiException implements Exception {
  /// `0` quando a requisicao nem chegou ao servidor (sem rede, host errado).
  final int statusCode;
  final String message;
  final Map<String, String> fields;
  final String? code;

  const ApiException({
    required this.statusCode,
    required this.message,
    this.fields = const {},
    this.code,
  });

  const ApiException.network()
    : statusCode = 0,
      message = 'Nao foi possivel conectar. Verifique sua internet.',
      fields = const {},
      code = null;

  bool get isNetworkFailure => statusCode == 0;

  /// Token ausente, invalido ou expirado. Nao ha refresh token: refazer login.
  bool get isUnauthorized => statusCode == 401;

  /// CPF nao existe no cadastro — sinal para abrir a tela de cadastro.
  bool get isNotRegistered => code == 'NAO_CADASTRADO';

  /// Conflito de estado: loja fechada, produto indisponivel, transicao invalida.
  bool get isConflict => statusCode == 409;

  /// Mensagem pronta para exibir, juntando os erros de campo quando existirem.
  String get displayMessage {
    if (fields.isEmpty) return message;
    return '$message\n${fields.values.join('\n')}';
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
