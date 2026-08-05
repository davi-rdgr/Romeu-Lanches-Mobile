import 'package:romeu_lanches_mobile/core/network/api_client.dart';
import 'package:romeu_lanches_mobile/features/auth/data/auth_controller.dart';
import 'package:romeu_lanches_mobile/features/auth/data/auth_repository.dart';
import 'package:romeu_lanches_mobile/features/auth/data/session_storage.dart';

class AuthFullDependencies {
  late final AuthRepository repository;
  late final AuthController auth;

  AuthFullDependencies(ApiClient api, SessionStorage storage) {
    repository = AuthRepository(api);
    auth = AuthController(repository, storage);
  }
}
