import 'package:hive_flutter/hive_flutter.dart';

import '../models/saved_item.dart';

/// Local persistence for saved routes & stops using Hive.
class StorageService {
  static const _boxName = 'saved_items';
  late Box _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  List<SavedItem> all() {
    return _box.values
        .map((e) => SavedItem.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
  }

  bool isSaved(String id) => _box.containsKey(id);

  Future<void> toggle(SavedItem item) async {
    if (_box.containsKey(item.id)) {
      await _box.delete(item.id);
    } else {
      await _box.put(item.id, item.toMap());
    }
  }

  Future<void> remove(String id) => _box.delete(id);
}
