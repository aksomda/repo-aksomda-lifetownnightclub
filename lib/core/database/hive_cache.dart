import 'package:hive/hive.dart';

class HiveJsonCache {
  final Box<String> box;
  HiveJsonCache(this.box);
  Future<void> save(String key, String json) => box.put(key, json);
  String? read(String key) => box.get(key);
  bool has(String key) => box.containsKey(key);
  Future<void> clear() => box.clear();
}
