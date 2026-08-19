/// Endereco do backend. O default e producao; para apontar para o Spring local
/// sobrescreva no build/run:
/// `flutter run --dart-define=API_BASE_URL=http://192.168.0.10:8080`
/// (no emulador Android use `http://10.0.2.2:8080` — la `localhost` e o proprio
/// emulador, nao a maquina que roda o Spring).
class AppConfig {
  static const _fromEnvironment = String.fromEnvironment('API_BASE_URL');

  static const productionBaseUrl = 'https://romeu-backend-2ms6.onrender.com';

  static String get baseUrl {
    if (_fromEnvironment.isNotEmpty) return _fromEnvironment;
    return productionBaseUrl;
  }

  /// Endpoint STOMP/SockJS, na mesma origem da API. O `StompConfig.sockJS`
  /// converte o esquema (`http` -> `ws`, `https` -> `wss`) e completa o caminho
  /// do transporte sozinho.
  static String get websocketUrl => '$baseUrl/ws';

  /// Intervalo do polling de acompanhamento do pedido. Continua valendo mesmo
  /// com o WebSocket ligado: o envio dos eventos e best-effort.
  static const orderPollingInterval = Duration(seconds: 10);

  /// Espera entre tentativas de reconexao do WebSocket.
  static const realtimeReconnectDelay = Duration(seconds: 5);

  static const requestTimeout = Duration(seconds: 20);
}
