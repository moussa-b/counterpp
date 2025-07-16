import 'dart:async';

import 'package:counter/models/settings.dart';
import 'package:counter/providers/counter_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsNotifier extends AsyncNotifier<Settings> {
  SettingsNotifier(): super();

  @override
  FutureOr<Settings> build() {
    return ref.read(counterRepositoryProvider).getSettings(); // initialize data
  }

  Future<Settings> updateSettings(Settings settings) async {
    final Settings updatedSettings = await ref.read(counterRepositoryProvider).updateSettings(settings);
    update((Settings previousSettings) => updatedSettings);
    return updatedSettings;
  }
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, Settings>(() {
  return SettingsNotifier();
});
