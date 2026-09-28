import 'mind_card_store.dart';

/// Fixture identity is not authentication and never leaves this process.
enum DevPrincipal { guest, fixtureA, fixtureB }

class RecordScope {
  RecordScope._(this._issuer, this.principal, this.generation);
  final Object _issuer;
  final DevPrincipal principal;
  final int generation;
  final String profile = 'buddhist';
  final String environment = 'TEST_DATA_ONLY';
}

class DevIdentityProvider {
  final Object _issuer = Object();
  late RecordScope _current = RecordScope._(_issuer, DevPrincipal.guest, 0);
  RecordScope get current => _current;
  RecordScope switchTo(DevPrincipal principal) =>
      _current = RecordScope._(_issuer, principal, _current.generation + 1);
  void validate(RecordScope scope) {
    if (!identical(scope._issuer, _issuer) || !identical(scope, _current)) {
      throw StateError('STALE_OR_FOREIGN_SCOPE');
    }
  }
}

class DevCardRepository {
  DevCardRepository(this.identity);
  final DevIdentityProvider identity;
  final Map<DevPrincipal, List<MindCardReference>> _rows = {};
  List<MindCardReference> list(RecordScope scope) {
    identity.validate(scope);
    if (scope.principal == DevPrincipal.guest) {
      throw StateError('GUEST_ADAPTER_REQUIRED');
    }
    return List.unmodifiable(_rows[scope.principal] ?? []);
  }

  void save(RecordScope scope, MindCardReference reference) {
    identity.validate(scope);
    if (scope.principal == DevPrincipal.guest) {
      throw StateError('GUEST_ADAPTER_REQUIRED');
    }
    final rows = _rows.putIfAbsent(scope.principal, () => []);
    if (!rows.any((row) => row.scriptureId == reference.scriptureId)) {
      rows.insert(0, reference);
    }
  }
}
