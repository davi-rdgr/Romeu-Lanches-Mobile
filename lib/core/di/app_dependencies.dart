import 'package:http/http.dart' as http;
import 'package:romeu_lanches_mobile/core/di/addresses_full_dependencies.dart';
import 'package:romeu_lanches_mobile/core/di/auth_full_dependencies.dart';
import 'package:romeu_lanches_mobile/core/di/cart_full_dependencies.dart';
import 'package:romeu_lanches_mobile/core/di/catalog_full_dependencies.dart';
import 'package:romeu_lanches_mobile/core/di/orders_full_dependencies.dart';
import 'package:romeu_lanches_mobile/core/di/scaffold_full_dependencies.dart';
import 'package:romeu_lanches_mobile/core/di/store_full_dependencies.dart';
import 'package:romeu_lanches_mobile/core/network/api_client.dart';
import 'package:romeu_lanches_mobile/core/network/realtime_client.dart';
import 'package:romeu_lanches_mobile/features/auth/data/session_storage.dart';
import 'package:signals_flutter/signals_flutter.dart';

late final AppDependencies deps;

class AppDependencies {
  late final ApiClient api;
  late final RealtimeClient realtime;
  late final AuthFullDependencies authFullDependencies;
  late final ScaffoldFullDependencies scaffoldFullDependencies;
  late final StoreFullDependencies storeFullDependencies;
  late final CatalogFullDependencies catalogFullDependencies;
  late final CartFullDependencies cartFullDependencies;
  late final AddressesFullDependencies addressesFullDependencies;
  late final OrdersFullDependencies ordersFullDependencies;

  /// [httpClient] existe para os testes injetarem um client falso; em producao
  /// fica nulo e o [ApiClient] cria o proprio.
  AppDependencies(SessionStorage sessionStorage, {http.Client? httpClient}) {
    // As closures rodam a cada requisicao, entao podem apontar para o
    // authFullDependencies que e construido na linha seguinte.
    api = ApiClient(
      tokenProvider: () => authFullDependencies.auth.session.value?.token,
      onUnauthorized: () => authFullDependencies.auth.handleUnauthorized(),
      httpClient: httpClient,
    );
    authFullDependencies = AuthFullDependencies(api, sessionStorage);
    scaffoldFullDependencies = ScaffoldFullDependencies();
    storeFullDependencies = StoreFullDependencies(api);
    catalogFullDependencies = CatalogFullDependencies(api);
    cartFullDependencies = CartFullDependencies(
      catalogFullDependencies.catalog,
      storeFullDependencies.store,
    );
    addressesFullDependencies = AddressesFullDependencies(api);
    ordersFullDependencies = OrdersFullDependencies(api);
    realtime = RealtimeClient(
      tokenProvider: () => authFullDependencies.auth.session.value?.token,
    );

    effect(() {
      scaffoldFullDependencies.scaffold.setCartItemsCount(
        cartFullDependencies.cart.itemsCount.value,
      );
    });

    // Dados de `/app/**` seguem a sessao. Ao sair (logout ou 401) eles somem,
    // porque eram do cliente que saiu; o carrinho e mantido de proposito — da
    // para entrar de novo e seguir do mesmo ponto.
    effect(() {
      if (authFullDependencies.auth.isLoggedIn.value) {
        addressesFullDependencies.addresses.load();
        ordersFullDependencies.orders.load();
      } else {
        addressesFullDependencies.addresses.clear();
        ordersFullDependencies.orders.clear();
      }
    });

    // O canal em tempo real segue a sessao: o topico e
    // `/topic/cliente/{sub do JWT}` e o backend so deixa o proprio cliente
    // assinar. Sem `clienteId` (token que nao decodificou) fica so o polling.
    effect(() {
      final clienteId = authFullDependencies.auth.clienteId.value;
      if (clienteId == null) {
        realtime.disconnect();
      } else {
        realtime.connect(
          clienteId,
          onEvent: ordersFullDependencies.orders.applyRealtimeEvent,
        );
      }
    });
  }

  /// App voltou do background. O socket costuma morrer enquanto o processo esta
  /// suspenso e os dados envelhecem: reconecta e revalida o que muda sozinho no
  /// servidor (status dos pedidos e a loja estar aberta).
  void handleAppResumed() {
    realtime.reconnectIfNeeded();
    storeFullDependencies.store.refreshIsOpen();
    if (authFullDependencies.auth.isLoggedIn.value) {
      ordersFullDependencies.orders.load();
    }
  }

  static Future<AppDependencies> create({http.Client? httpClient}) async {
    final sessionStorage = await SessionStorage.open();
    return AppDependencies(sessionStorage, httpClient: httpClient);
  }
}
