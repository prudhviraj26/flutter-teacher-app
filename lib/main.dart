import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/app_state.dart';
import 'app.dart';
import 'services/notification_navigation_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationNavigationService.initialize();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: const TeacherApp(),
    ),
  );
}
