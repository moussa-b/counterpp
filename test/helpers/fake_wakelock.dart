import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';

/// Stands in for the wakelock plugin during widget tests.
///
/// `CounterWidget.getSettings()` awaits `WakelockPlus.enabled` before it can
/// load the counter, and that call goes through a pigeon channel with no
/// handler in a test binding. The future never resolves, so the widget sits on
/// its `LoadingIndicator` forever and `pumpAndSettle` times out on a spinner
/// that will never stop.
///
/// Installing this keeps the call local and instant. [enabled] tracks what the
/// widget asked for, so a test can assert that "keep screen on" reaches the
/// platform.
class FakeWakelock extends WakelockPlusPlatformInterface {
  bool enabledValue = false;

  /// Every toggle the widget requested, in order.
  final List<bool> toggles = <bool>[];

  @override
  Future<void> toggle({required bool enable}) async {
    toggles.add(enable);
    enabledValue = enable;
  }

  @override
  Future<bool> get enabled async => enabledValue;
}

/// Installs a [FakeWakelock] and returns it, so a test can read [toggles].
///
/// Call from `setUp` in any test that reaches `CounterWidget`.
FakeWakelock installFakeWakelock() {
  final FakeWakelock fake = FakeWakelock();
  WakelockPlusPlatformInterface.instance = fake;
  return fake;
}
