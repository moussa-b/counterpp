import 'dart:io';

class AppConfig {
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.bdzapps.counter.counter';

  /// App Store listing, built from the app's Apple ID in App Store Connect.
  static const String appStoreUrl = 'https://apps.apple.com/app/id6826520493';

  static const String developerEmail = 'boudamouzm@gmail.com';
  static const String appName = 'Counter++';

  /// Public privacy policy, the same URL declared in the Play Console and
  /// App Store Connect listings.
  static const String privacyPolicyUrl = 'https://bdzapps.com/counter/privacy/';

  static bool get hasPrivacyPolicy => privacyPolicyUrl.isNotEmpty;

  /// Store link the share entry sends. Apple rejects an iOS app that points
  /// users to Google Play, so each platform shares its own store.
  static String get shareUrl => Platform.isIOS ? appStoreUrl : playStoreUrl;

  /// While the platform has no store URL yet the share entry stays hidden.
  static bool get hasShareUrl => shareUrl.isNotEmpty;
}
