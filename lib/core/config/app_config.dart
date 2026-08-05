import 'package:flutter/foundation.dart';

/// Endereco do backend. Sobrescreva com:
/// `flutter run --dart-define=API_BASE_URL=http://192.168.0.10:8080`
///
/// O default muda por plataforma porque `localhost` dentro do emulador Android
/// aponta para o proprio emulador, nao para a maquina que roda o Spring.
class AppConfig {
  static const _fromEnvironment = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_fromEnvironment.isNotEmpty) return _fromEnvironment;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  /// Intervalo do polling de acompanhamento do pedido.
  static const orderPollingInterval = Duration(seconds: 10);

  static const requestTimeout = Duration(seconds: 20);
}
