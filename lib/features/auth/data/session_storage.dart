import 'package:hive_flutter/hive_flutter.dart';
import 'package:romeu_lanches_mobile/features/auth/data/session.dart';

/// Persiste a sessao entre aberturas do app.
class SessionStorage {
  static const _boxName = 'session';
  static const _key = 'current';

  final Box _box;

  const SessionStorage(this._box);

  static Future<SessionStorage> open() async =>
      SessionStorage(await Hive.openBox(_boxName));

  Session? read() {
    final raw = _box.get(_key);
    if (raw is! Map) return null;
    try {
      final session = Session.fromJson(raw);
      // Token de 24h sem refresh: se ja venceu, nao adianta carregar.
      if (session.isExpired) {
        _box.delete(_key);
        return null;
      }
      return session;
    } catch (_) {
      _box.delete(_key);
      return null;
    }
  }

  Future<void> write(Session session) => _box.put(_key, session.toJson());

  Future<void> clear() => _box.delete(_key);
}
