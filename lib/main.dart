import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'features/notifications/data/notification_service.dart';
import 'firebase_options.dart';

import 'core/bootstrap/app_runtime_guard.dart';
import 'core/bootstrap/edible_bootstrap_root.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(
    edibleFirebaseMessagingBackgroundHandler,
  );
  AppRuntimeGuard.install();
  runApp(const EdibleBootstrapRoot());
}
