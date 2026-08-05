import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:romeu_lanches_mobile/core/config/app_config.dart';
import 'package:romeu_lanches_mobile/core/network/api_exception.dart';

/// Cliente HTTP do app. Anexa o Bearer token quando existe, decodifica o JSON
/// e converte qualquer resposta de erro em [ApiException].
class ApiClient {
  final http.Client _http;

  /// Token atual da sessao, ou `null` quando o cliente nao esta logado.
  final String? Function() tokenProvider;

  /// Chamado quando o backend responde 401 — a sessao morreu e precisa ser
  /// refeita (nao existe refresh token na API).
  final void Function() onUnauthorized;

  ApiClient({
    required this.tokenProvider,
    required this.onUnauthorized,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  Future<dynamic> get(String path, {bool authenticated = false}) =>
      _send('GET', path, authenticated: authenticated);

  Future<dynamic> post(String path, {Object? body, bool authenticated = true}) =>
      _send('POST', path, body: body, authenticated: authenticated);

  Future<dynamic> put(String path, {Object? body}) =>
      _send('PUT', path, body: body, authenticated: true);

  Future<dynamic> patch(String path, {Object? body}) =>
      _send('PATCH', path, body: body, authenticated: true);

  Future<dynamic> delete(String path) =>
      _send('DELETE', path, authenticated: true);

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    required bool authenticated,
  }) async {
    final request = http.Request(method, Uri.parse('${AppConfig.baseUrl}$path'))
      ..headers['Accept'] = 'application/json';

    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    if (authenticated) {
      final token = tokenProvider();
      if (token == null) {
        throw const ApiException(
          statusCode: 401,
          message: 'Sessao expirada. Entre novamente.',
        );
      }
      request.headers['Authorization'] = 'Bearer $token';
    }

    final http.Response response;
    try {
      final streamed = await _http
          .send(request)
          .timeout(AppConfig.requestTimeout);
      response = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw const ApiException.network();
    } catch (_) {
      throw const ApiException.network();
    }

    if (response.statusCode == 401) {
      onUnauthorized();
      throw _parseError(response);
    }
    if (response.statusCode >= 400) {
      throw _parseError(response);
    }

    // 204 (DELETE de endereco) e corpos vazios nao tem JSON para decodificar.
    if (response.statusCode == 204 || response.bodyBytes.isEmpty) return null;

    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Resposta invalida do servidor.',
      );
    }
  }

  ApiException _parseError(http.Response response) {
    // 403 do Spring nao usa o JSON da secao 9 — o corpo pode nem ser JSON.
    Map<String, dynamic>? json;
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) json = decoded;
    } catch (_) {
      json = null;
    }

    final fields = <String, String>{};
    final campos = json?['campos'];
    if (campos is Map) {
      for (final entry in campos.entries) {
        fields[entry.key.toString()] = entry.value.toString();
      }
    }

    final code = json?['code'] as String?;
    final error = json?['error'] as String?;

    return ApiException(
      statusCode: response.statusCode,
      message: error ?? _fallbackMessage(response.statusCode, code),
      fields: fields,
      code: code,
    );
  }

  String _fallbackMessage(int statusCode, String? code) {
    if (code == 'NAO_CADASTRADO') return 'CPF nao cadastrado.';
    return switch (statusCode) {
      401 => 'Sessao expirada. Entre novamente.',
      403 => 'Voce nao tem permissao para essa acao.',
      404 => 'Nao encontrado.',
      >= 500 => 'O servidor falhou. Tente novamente em instantes.',
      _ => 'Nao foi possivel completar a operacao.',
    };
  }

  void dispose() => _http.close();
}
