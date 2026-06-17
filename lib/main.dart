import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/diary_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/task_provider.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'services/secure_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();

  // Shared singletons.
  final storage = SecureStorageService();
  final db = DatabaseService();
  final authService = AuthService(storage: storage);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(auth: authService, db: db)..init(),
        ),
        ChangeNotifierProvider(create: (_) => DiaryProvider(db)),
        ChangeNotifierProvider(create: (_) => TaskProvider(db)),
        ChangeNotifierProvider(create: (_) => SettingsProvider(storage)..load()),
      ],
      child: const MindLogApp(),
    ),
  );
}
