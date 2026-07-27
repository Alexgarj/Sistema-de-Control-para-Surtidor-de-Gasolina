import 'package:flutter/foundation.dart';

abstract class DatabaseAdapter {
  Future<List<Map<String, dynamic>>> getSurtidores();
  Future<void> insertSurtidor(Map<String, dynamic> data);
  Future<void> updateSurtidor(int id, Map<String, dynamic> data);
  Future<void> deleteSurtidor(int id);

  // Stream para cambios en tiempo real
  Stream<List<Map<String, dynamic>>> streamSurtidores();
}
