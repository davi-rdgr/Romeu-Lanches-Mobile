import 'package:romeu_lanches_mobile/core/network/api_client.dart';
import 'package:romeu_lanches_mobile/features/auth/data/session.dart';
import 'package:romeu_lanches_mobile/features/auth/utils/cpf_validator.dart';

/// Login do cliente e CPF + telefone — nao ha senha nem e-mail.
class AuthRepository {
  final ApiClient _api;

  const AuthRepository(this._api);

  /// Lanca `ApiException` com `isNotRegistered == true` quando o CPF nao existe:
  /// o sinal para abrir a tela de cadastro.
  Future<Session> login({required String cpf, required String phone}) async {
    final json = await _api.post(
      '/auth/cliente/login',
      authenticated: false,
      body: {'cpf': onlyDigits(cpf), 'telefone': onlyDigits(phone)},
    );
    return _sessionFrom(json, cpf: cpf, phone: phone);
  }

  /// O cadastro ja devolve token — nao precisa logar depois.
  Future<Session> register({
    required String cpf,
    required String name,
    required String phone,
  }) async {
    final json = await _api.post(
      '/auth/cliente/register',
      authenticated: false,
      body: {
        'cpf': onlyDigits(cpf),
        'nome': name.trim(),
        'telefone': onlyDigits(phone),
      },
    );
    return _sessionFrom(json, cpf: cpf, phone: phone);
  }

  Session _sessionFrom(
    dynamic json, {
    required String cpf,
    required String phone,
  }) {
    final map = json as Map<String, dynamic>;
    return Session.fromLogin(
      token: map['token'] as String,
      name: map['nome'] as String? ?? '',
      cpf: onlyDigits(cpf),
      phone: onlyDigits(phone),
    );
  }
}
