import 'dart:io';

import 'package:counter/utils/logging_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel pathProviderChannel = MethodChannel(
    'plugins.flutter.io/path_provider',
  );
  late Directory documentsDirectory;

  setUpAll(() async {
    documentsDirectory = await Directory.systemTemp.createTemp(
      'counterpp_logs_',
    );
    // path_provider has no platform implementation in a VM test; point its
    // method channel at a temp directory so the real file path is exercised.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (MethodCall call) async {
          if (call.method == 'getApplicationDocumentsDirectory') {
            return documentsDirectory.path;
          }
          return null;
        });
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    if (documentsDirectory.existsSync()) {
      await documentsDirectory.delete(recursive: true);
    }
  });

  setUp(() async {
    await LoggingService().clearLogs();
  });

  group('redactSensitiveHeaders', () {
    test('masks the value of every credential-bearing header', () {
      final Map<String, String> redacted =
          redactSensitiveHeaders(<String, String>{
            'Authorization': 'Bearer secret-token',
            'Proxy-Authorization': 'Basic abc',
            'Cookie': 'session=abc',
            'Content-Type': 'application/json',
          });

      expect(redacted['Authorization'], '***redacted***');
      expect(redacted['Proxy-Authorization'], '***redacted***');
      expect(redacted['Cookie'], '***redacted***');
      expect(redacted['Content-Type'], 'application/json');
    });

    test('matches header names case-insensitively', () {
      final Map<String, String> redacted = redactSensitiveHeaders(
        <String, String>{'authorization': 'Bearer secret-token'},
      );

      expect(redacted['authorization'], '***redacted***');
    });

    test('keeps the header names so the log still shows what was sent', () {
      final Map<String, String> redacted = redactSensitiveHeaders(
        <String, String>{'Authorization': 'Bearer secret-token'},
      );

      expect(redacted.keys, contains('Authorization'));
    });

    test('leaves the caller map untouched', () {
      final Map<String, String> original = <String, String>{
        'Authorization': 'Bearer secret-token',
      };

      redactSensitiveHeaders(original);

      expect(original['Authorization'], 'Bearer secret-token');
    });
  });

  group('logHttpFailure', () {
    test('never writes the bearer token to the log file', () async {
      // Regression: the whole header map was interpolated into the log, and the
      // developer logs screen renders that file as selectable text, so any
      // failed sync left a copyable access token on screen.
      await LoggingService().logHttpFailure(
        method: 'POST',
        url: Uri.parse('https://example.invalid/api/counters/synchronize'),
        statusCode: 500,
        requestHeaders: <String, String>{
          'Authorization': 'Bearer super-secret-token',
          'Content-Type': 'application/json',
        },
        requestBody: '[]',
        responseBody: 'boom',
      );

      final String logs = await LoggingService().readLogs();
      expect(logs, isNot(contains('super-secret-token')));
      expect(logs, contains('***redacted***'));
    });

    test(
      'still records the method, url and status so the entry is useful',
      () async {
        await LoggingService().logHttpFailure(
          method: 'DELETE',
          url: Uri.parse('https://example.invalid/api/counters/delete'),
          statusCode: 404,
          requestHeaders: <String, String>{'Authorization': 'Bearer t'},
        );

        final String logs = await LoggingService().readLogs();
        expect(logs, contains('HTTP DELETE'));
        expect(logs, contains('https://example.invalid/api/counters/delete'));
        expect(logs, contains('Status: 404'));
      },
    );

    test('appends rather than replacing previous entries', () async {
      await LoggingService().logMessage('first entry');
      await LoggingService().logMessage('second entry');

      final String logs = await LoggingService().readLogs();
      expect(logs, contains('first entry'));
      expect(logs, contains('second entry'));
    });
  });

  group('logMessage', () {
    test('records details, error and stack trace', () async {
      await LoggingService().logMessage(
        'Data import failed',
        details: <String, Object?>{'filePath': '/tmp/export.json'},
        error: StateError('bad payload'),
        stackTrace: StackTrace.current,
      );

      final String logs = await LoggingService().readLogs();
      expect(logs, contains('Data import failed'));
      expect(logs, contains('filePath: /tmp/export.json'));
      expect(logs, contains('bad payload'));
      expect(logs, contains('Stack trace:'));
    });

    test('clearLogs empties the file', () async {
      await LoggingService().logMessage('something');
      expect(await LoggingService().readLogs(), isNotEmpty);

      await LoggingService().clearLogs();

      expect(await LoggingService().readLogs(), isEmpty);
    });

    test(
      'does not try to send mail when no mail settings are provided',
      () async {
        // settings == null is the path taken by SynchronizationService; if this
        // ever attempted a real send it would throw a MissingPluginException.
        await LoggingService().logMessage(
          'no settings',
          error: StateError('x'),
        );

        expect(await LoggingService().readLogs(), contains('no settings'));
      },
    );
  });
}
