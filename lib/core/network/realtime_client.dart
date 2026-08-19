import 'dart:convert';

import 'package:romeu_lanches_mobile/core/config/app_config.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

/// `tipo` do envelope do evento (secao 8 da API).
enum RealtimeEventType {
  orderCreated('PEDIDO_CRIADO'),
  statusUpdated('STATUS_ATUALIZADO'),

  /// Tipo que este app ainda nao conhece. O backend pode publicar eventos
  /// novos; ignorar e seguro porque o dado ja esta persistido e o polling
  /// eventualmente traz o estado certo.
  unknown('');

  const RealtimeEventType(this.apiValue);

  final String apiValue;

  static RealtimeEventType fromApi(String? value) => values.firstWhere(
    (type) => type.apiValue == value,
    orElse: () => RealtimeEventType.unknown,
  );
}

/// `{ "tipo": "...", "dado": { ... } }`.
///
/// No canal do cliente o `dado` e sempre um `PedidoResponse` completo — no
/// canal do admin seria o resumo, mas o app do cliente nao assina aquele.
class RealtimeEvent {
  final RealtimeEventType type;
  final Map<String, dynamic> data;

  const RealtimeEvent({required this.type, required this.data});

  /// `null` quando o corpo nao e o envelope esperado — evento estranho nao
  /// derruba a conexao.
  static RealtimeEvent? tryParse(String? body) {
    if (body == null || body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) return null;
      final data = decoded['dado'];
      if (data is! Map<String, dynamic>) return null;
      return RealtimeEvent(
        type: RealtimeEventType.fromApi(decoded['tipo'] as String?),
        data: data,
      );
    } catch (_) {
      return null;
    }
  }
}

typedef RealtimeEventHandler = void Function(RealtimeEvent event);

/// Canal em tempo real do cliente: STOMP sobre SockJS em `/ws`.
///
/// O envio dos eventos no backend e **best-effort e pos-commit**: se um evento
/// se perder, o dado ja esta gravado. Por isso isto aqui nunca e a unica fonte
/// de verdade — o polling do [OrdersController] continua ligado como fallback.
class RealtimeClient {
  /// Token da sessao, lido a cada conexao. Vai no header **nativo do STOMP** do
  /// frame CONNECT: sem ele (ou invalido) o backend derruba a conexao.
  final String? Function() tokenProvider;

  RealtimeClient({required this.tokenProvider});

  StompClient? _client;
  String? _clienteId;
  RealtimeEventHandler? _onEvent;

  bool get isConnected => _client?.connected ?? false;

  /// Assina `/topic/cliente/{clienteId}` — um `ROLE_CLIENTE` so pode assinar o
  /// proprio canal, e `clienteId` tem que ser o `sub` do JWT. Chamar de novo
  /// com o mesmo id nao reconecta.
  void connect(String clienteId, {required RealtimeEventHandler onEvent}) {
    if (_clienteId == clienteId && _client != null) {
      _onEvent = onEvent;
      return;
    }
    disconnect();
    _clienteId = clienteId;
    _onEvent = onEvent;
    _start();
  }

  /// Logout ou 401: o canal era do cliente que saiu.
  void disconnect() {
    _client?.deactivate();
    _client = null;
    _clienteId = null;
    _onEvent = null;
  }

  /// O socket morre quando o sistema suspende o app. O `StompClient` tem retry
  /// proprio, mas na volta do background vale forcar para nao esperar o timer.
  void reconnectIfNeeded() {
    if (_clienteId == null || isConnected) return;
    _client?.deactivate();
    _start();
  }

  void _start() {
    final token = tokenProvider();
    final clienteId = _clienteId;
    if (token == null || clienteId == null) return;

    _client = StompClient(
      config: StompConfig.sockJS(
        url: AppConfig.websocketUrl,
        // A autenticacao acontece no CONNECT do STOMP, nao no handshake HTTP.
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        reconnectDelay: AppConfig.realtimeReconnectDelay,
        onConnect: (_) => _subscribe(clienteId),
      ),
    )..activate();
  }

  void _subscribe(String clienteId) {
    // Reassinar a cada CONNECT: o reconnect refaz a sessao SockJS e as
    // assinaturas antigas morrem com ela.
    _client?.subscribe(
      destination: '/topic/cliente/$clienteId',
      callback: (frame) {
        final event = RealtimeEvent.tryParse(frame.body);
        if (event != null) _onEvent?.call(event);
      },
    );
  }
}
