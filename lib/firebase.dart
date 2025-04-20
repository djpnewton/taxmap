import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:universal_platform/universal_platform.dart';

import 'firebase_options.dart';

Future<void> firebaseInit() async {
  // firebase only setup for web
  if (UniversalPlatform.isWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}

Future<void> firebaseLogEvent(
  String eventName, {
  Map<String, Object>? parameters,
}) async {
  if (!UniversalPlatform.isWeb) {
    return;
  }
  await FirebaseAnalytics.instance.logEvent(
    name: eventName,
    parameters: parameters,
  );
}

enum FirebaseContentType { country, taxFilterType }

Future<void> firebaseSelectContent(
  FirebaseContentType contentType,
  String id,
) async {
  if (!UniversalPlatform.isWeb) {
    return;
  }
  await FirebaseAnalytics.instance.logSelectContent(
    contentType: contentType.name,
    itemId: id,
  );
}
