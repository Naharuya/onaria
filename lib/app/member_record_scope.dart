import 'package:flutter/foundation.dart';

/// Verified server identity only. The legacy device keys are never inferred
/// to belong to the first account that logs in.
class MemberRecordScope extends ChangeNotifier {
  static final instance = MemberRecordScope();
  int? _memberId;
  bool _locked = false;
  bool _deleting = false;
  int _generation = 0;
  int? get memberId => _memberId;
  bool get locked => _locked || _deleting;
  int get generation => _generation;

  void lock() => _change(null, true);
  void signedOut() => _change(null, false);
  void verified(int memberId) {
    if (memberId < 1) throw ArgumentError('Invalid verified member');
    _change(memberId, false);
  }

  void _change(int? id, bool locked) {
    if (_memberId == id && _locked == locked) return;
    _deleting = false;
    _memberId = id;
    _locked = locked;
    _generation++;
    notifyListeners();
  }

  int beginRecordDeletion() {
    if (locked) throw StateError('Records unavailable');
    _deleting = true;
    return ++_generation;
  }

  void requireDeletion(int generation) {
    if (!_deleting || generation != _generation)
      throw StateError('Account changed');
  }

  void finishRecordDeletion(int generation) {
    if (!_deleting || generation != _generation) return;
    _deleting = false;
    _generation++;
    notifyListeners();
  }

  RecordAccess capture() {
    return RecordAccess(this, _generation, _memberId);
  }
}

class RecordAccess {
  RecordAccess(this.scope, this.generation, this.memberId);
  final MemberRecordScope scope;
  final int generation;
  final int? memberId;
  bool get current => generation == scope.generation && !scope.locked;
  String key(String legacyKey) =>
      'onaria.records.v2.${memberId == null ? 'guest' : 'member.$memberId'}.$legacyKey';
  void requireCurrent() {
    if (!current) throw StateError('Account changed during record operation');
  }
}
