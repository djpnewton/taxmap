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

FirebaseAnalytics firebaseInst() {
  // firebase only setup for web
  if (UniversalPlatform.isWeb) {
    return FirebaseAnalytics.instanceFor(
      app: Firebase.app(),
      webOptions: {
        'cookie_flags': 'max-age=7200;secure;samesite=none',
        'cookieFlags': 'max-age=7200;secure;samesite=none',
      },
    );
  }
  return FirebaseAnalytics.instance;
}

Future<void> firebaseLogEvent(
  String eventName, {
  Map<String, Object>? parameters,
}) async {
  if (!UniversalPlatform.isWeb) {
    return;
  }
  await firebaseInst().logEvent(name: eventName, parameters: parameters);
}

enum FirebaseContentType { country, taxFilterType }

Future<void> firebaseSelectContent(
  FirebaseContentType contentType,
  String id,
) async {
  if (!UniversalPlatform.isWeb) {
    return;
  }
  await firebaseInst().logSelectContent(
    contentType: contentType.name,
    itemId: id,
  );
}
