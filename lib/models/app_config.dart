class AppConfig {
  static const String shareUrl =
      'https://play.google.com/store/apps/details?id=com.bdzapps.counter.counter';
  static const String developerEmail = 'boudamouzm@gmail.com';
  static const String appName = 'Counter++';

  /// Public privacy policy, the same URL declared in the Play Console listing.
  ///
  /// While this is empty the settings entry stays hidden: a visible row that
  /// does nothing when tapped is worse than no row at all.
  static const String privacyPolicyUrl = '';

  static bool get hasPrivacyPolicy => privacyPolicyUrl.isNotEmpty;
}
