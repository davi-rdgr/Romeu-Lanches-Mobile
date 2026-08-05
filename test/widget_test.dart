import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:romeu_lanches_mobile/core/di/app_dependencies.dart';
import 'package:romeu_lanches_mobile/main.dart';

/// Backend falso: o app carrega cardapio e dados da loja no boot, entao sem
/// isso o teste dependeria de um servidor rodando.
http.Client _fakeBackend() {
  return MockClient((request) async {
    final path = request.url.path;

    final body = switch (path) {
      '/public/cardapio' => {
        'categorias': [
          {
            'id': 'cat-1',
            'nome': 'Baurus',
            'ordem': 1,
            'produtos': [
              {
                'id': 'prod-1',
                'categoriaId': 'cat-1',
                'categoriaNome': 'Baurus',
                'nome': 'Bauru da Casa',
                'descricao': 'Pao, alcatra, queijo.',
                'preco': 33.0,
                'disponivel': true,
                'imagemUrl': null,
                'ordem': 1,
              },
            ],
          },
        ],
      },
      '/public/loja/status' => {'aberta': true},
      '/public/loja/info' => {
        'taxaEntrega': 8.0,
        'tempoEstimadoMin': 40,
        'aceitaPix': true,
        'aceitaCartao': true,
        'aceitaDinheiro': true,
      },
      '/public/loja/horarios' => [
        for (var day = 1; day <= 7; day++)
          {
            'diaSemana': day,
            'aberto': day != 1,
            'abertura': day == 1 ? null : '18:30',
            'fechamento': day == 1 ? null : '23:30',
          },
      ],
      _ => {'error': 'nao mapeado no teste: $path'},
    };

    return http.Response(
      jsonEncode(body),
      path.startsWith('/public') ? 200 : 404,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  });
}

void main() {
  setUpAll(() async {
    Hive.init('${Directory.systemTemp.path}/romeu_lanches_test');
    await initializeDateFormatting('pt_BR');
  });

  testWidgets('loads Romeu Lanches app', (WidgetTester tester) async {
    deps = await AppDependencies.create(httpClient: _fakeBackend());

    await tester.pumpWidget(const MyApp());

    // Splash: 2200ms ate trocar para o AppShell, mais a transicao de 400ms.
    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Cardapio'), findsOneWidget);
  });
}
