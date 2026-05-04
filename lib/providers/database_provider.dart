import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';

final databaseProvider = FutureProvider<void>((ref) async {
  await DatabaseService.database;
});