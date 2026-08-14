import 'package:counter/models/settings.dart';
import 'package:counter/models/sorting_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Settings buildConfiguredSettings() {
    final Settings settings = Settings();
    settings.activateSounds = true;
    settings.activateVibrator = false;
    settings.counterCompactView = true;
    settings.keepScreenOn = true;
    settings.showTutorial = false;
    settings.counterSorting = SortingOptions.alphabeticalAsc;
    settings.folderSorting = SortingOptions.valueDesc;
    settings.lastOpenedTabIndex = 2;
    settings.synchronizationAccessToken = 'secret-token';
    settings.synchronizationApiUrl = 'https://example.invalid/api';
    settings.mailApiKey = 'key-123';
    settings.mailApiDomain = 'mg.example.invalid';
    settings.mailSupport = 'support@example.invalid';
    return settings;
  }

  group('toJsonWithoutCredentials', () {
    test('drops every credential field', () {
      // The export is written to the shared Downloads folder and users attach
      // it to support mails, so none of these may travel with it.
      final Map<String, dynamic> json = buildConfiguredSettings()
          .toJsonWithoutCredentials();

      for (final String field in Settings.credentialFields) {
        expect(
          json.containsKey(field),
          isFalse,
          reason: '$field must not be exported',
        );
      }
    });

    test('does not leak the secret values anywhere in the payload', () {
      final Map<String, dynamic> json = buildConfiguredSettings()
          .toJsonWithoutCredentials();

      final String serialized = json.toString();
      expect(serialized, isNot(contains('secret-token')));
      expect(serialized, isNot(contains('key-123')));
      expect(serialized, isNot(contains('mg.example.invalid')));
    });

    test('keeps every preference so an export still restores the setup', () {
      final Map<String, dynamic> json = buildConfiguredSettings()
          .toJsonWithoutCredentials();

      expect(json['activateSounds'], 1);
      expect(json['activateVibrator'], 0);
      expect(json['counterCompactView'], 1);
      expect(json['keepScreenOn'], 1);
      expect(json['showTutorial'], 0);
      expect(json['counterSorting'], SortingOptions.alphabeticalAsc.index);
      expect(json['folderSorting'], SortingOptions.valueDesc.index);
      expect(json['lastOpenedTabIndex'], 2);
    });

    test('leaves the full toJson untouched for internal use', () {
      // The database writer relies on toJson still carrying the credentials.
      final Map<String, dynamic> json = buildConfiguredSettings().toJson();

      expect(json['synchronizationAccessToken'], 'secret-token');
      expect(json['mailApiKey'], 'key-123');
    });
  });

  group('fromJson', () {
    test('reads an export that no longer carries credentials', () {
      final Map<String, dynamic> exported = buildConfiguredSettings()
          .toJsonWithoutCredentials();

      final Settings imported = Settings.fromJson(exported);

      expect(imported.activateSounds, isTrue);
      expect(imported.keepScreenOn, isTrue);
      expect(imported.counterSorting, SortingOptions.alphabeticalAsc);
      // Null rather than an empty string: settings_screen relies on ??= to keep
      // the credentials already stored on the device.
      expect(imported.synchronizationAccessToken, isNull);
      expect(imported.mailApiKey, isNull);
    });

    test('defaults showTutorial to true when the field is absent', () {
      final Settings imported = Settings.fromJson(<String, dynamic>{});

      expect(imported.showTutorial, isTrue);
      expect(imported.lastOpenedTabIndex, 0);
    });

    test('round-trips through toJson', () {
      final Settings original = buildConfiguredSettings();

      final Settings restored = Settings.fromJson(original.toJson());

      expect(
        restored.synchronizationAccessToken,
        original.synchronizationAccessToken,
      );
      expect(restored.mailApiKey, original.mailApiKey);
      expect(restored.folderSorting, original.folderSorting);
      expect(restored.lastOpenedTabIndex, original.lastOpenedTabIndex);
    });
  });

  group('copy', () {
    test('carries every field over', () {
      final Settings original = buildConfiguredSettings();

      final Settings copy = Settings.copy(original);

      expect(copy.synchronizationApiUrl, original.synchronizationApiUrl);
      expect(copy.mailSupport, original.mailSupport);
      expect(copy.showTutorial, original.showTutorial);
      expect(copy.lastOpenedTabIndex, original.lastOpenedTabIndex);
    });
  });
}
