import 'package:hive_flutter/hive_flutter.dart';

/// Persistent app preferences (separate box from the data cache, so cache
/// invalidation / clearAll never wipes these flags).
class PrefsService {
  static const String _boxName = 'app_prefs';
  static const String _legalAcceptedKey = 'legal_accepted_v1';
  static Box? _box;

  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  static bool get legalAccepted => _box?.get(_legalAcceptedKey) == true;

  static Future<void> setLegalAccepted() async {
    await _box?.put(_legalAcceptedKey, true);
  }
}
