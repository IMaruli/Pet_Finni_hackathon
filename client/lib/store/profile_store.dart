import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'snapshot.dart';

abstract interface class ProfileStore {
  /// `null` — новый игрок, либо снимок был битый (тогда он удалён).
  Future<GameSnapshot?> load();
  Future<void> save(GameSnapshot snapshot);
  Future<void> clear();
}

GameSnapshot? _decode(String? raw) {
  if (raw == null) return null;
  try {
    return GameSnapshot.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  } catch (_) {
    return null;
  }
}

final class SharedPrefsProfileStore implements ProfileStore {
  static const key = 'finni.snapshot';

  @override
  Future<GameSnapshot?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    final snapshot = _decode(raw);
    if (raw != null && snapshot == null) await prefs.remove(key);
    return snapshot;
  }

  @override
  Future<void> save(GameSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(snapshot.toJson()));
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}

final class MemoryProfileStore implements ProfileStore {
  String? raw;

  @override
  Future<GameSnapshot?> load() async => _decode(raw);

  @override
  Future<void> save(GameSnapshot snapshot) async => raw = jsonEncode(snapshot.toJson());

  @override
  Future<void> clear() async => raw = null;
}
