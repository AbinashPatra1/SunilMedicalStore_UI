import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/app.dart';
import 'package:sunil_medical_store/firebase_options.dart';

/// Runs when a push notification arrives while the app is backgrounded or
/// terminated. Android already shows the system tray notification on its
/// own for a `notification` + `data` payload (see
/// `docs/API_ENDPOINTS.md` §Push notifications) — this handler exists only
/// because `firebase_messaging` requires one to be registered; there's
/// nothing extra to do here today. Must be a top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const ProviderScope(child: MyApp()));
}
