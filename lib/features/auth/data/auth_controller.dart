import 'package:romeu_lanches_mobile/features/auth/data/auth_repository.dart';
import 'package:romeu_lanches_mobile/features/auth/data/session.dart';
import 'package:romeu_lanches_mobile/features/auth/data/session_storage.dart';
import 'package:signals_flutter/signals_flutter.dart';

class AuthController {
  final AuthRepository _repository;
  final SessionStorage _storage;

  AuthController(this._repository, this._storage) {
    session.value = _storage.read();
  }

  final session = signal<Session?>(null);
  final isSubmitting = signal(false);

  late final isLoggedIn = computed(() => session.value != null);
  late final userName = computed(() => session.value?.name ?? '');
  late final clienteId = computed(() => session.value?.clienteId);

  Future<void> login({required String cpf, required String phone}) =>
      _run(() => _repository.login(cpf: cpf, phone: phone));

  Future<void> register({
    required String cpf,
    required String name,
    required String phone,
  }) => _run(() => _repository.register(cpf: cpf, name: name, phone: phone));

  Future<void> _run(Future<Session> Function() request) async {
    isSubmitting.value = true;
    try {
      final result = await request();
      session.value = result;
      await _storage.write(result);
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> logout() async {
    session.value = null;
    await _storage.clear();
  }

  /// Chamado pelo ApiClient em qualquer 401. Nao ha refresh token: a sessao
  /// morreu e o cliente precisa entrar de novo. O carrinho e preservado.
  void handleUnauthorized() {
    session.value = null;
    _storage.clear();
  }

  void dispose() {
    session.dispose();
    isSubmitting.dispose();
    isLoggedIn.dispose();
    userName.dispose();
    clienteId.dispose();
  }
}
