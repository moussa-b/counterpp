import 'dart:convert';

import 'package:counter/models/count.dart';
import 'package:counter/models/counter.dart';
import 'package:counter/models/folder.dart';
import 'package:counter/utils/synchronization_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String apiUrl = 'https://example.invalid/api';
  const String token = 'secret-token';

  late List<http.Request> requests;

  /// Installs a stub client that records every request and answers with
  /// [status] / [body].
  void stubClient({int status = 200, String body = '{"status":true}'}) {
    requests = <http.Request>[];
    SynchronizationService().client = MockClient((http.Request request) async {
      requests.add(request);
      return http.Response(body, status);
    });
  }

  setUp(() {
    SynchronizationService().resetApiUrl();
    stubClient();
  });

  tearDown(() {
    SynchronizationService().resetApiUrl();
  });

  group('configuration', () {
    test('is not initialized until a url and a token are both set', () {
      expect(SynchronizationService().isInitialized, isFalse);

      expect(
        SynchronizationService().setApiUrl(
          apiUrl: apiUrl,
          apiAccessToken: token,
        ),
        isTrue,
      );

      expect(SynchronizationService().isInitialized, isTrue);
    });

    test(
      'rejects a url with no scheme and keeps the previous configuration',
      () {
        SynchronizationService().setApiUrl(
          apiUrl: apiUrl,
          apiAccessToken: token,
        );

        final bool accepted = SynchronizationService().setApiUrl(
          apiUrl: 'example.invalid/api',
          apiAccessToken: token,
        );

        expect(accepted, isFalse);
        // Still pointing at the previous, valid endpoint rather than a broken one.
        expect(SynchronizationService().isInitialized, isTrue);
      },
    );

    test('rejects an empty token', () {
      expect(
        SynchronizationService().setApiUrl(apiUrl: apiUrl, apiAccessToken: ''),
        isFalse,
      );
      expect(SynchronizationService().isInitialized, isFalse);
    });

    test('resetApiUrl clears the configuration', () {
      SynchronizationService().setApiUrl(apiUrl: apiUrl, apiAccessToken: token);

      SynchronizationService().resetApiUrl();

      expect(SynchronizationService().isInitialized, isFalse);
    });

    test('isValidUrl accepts absolute urls and rejects the rest', () {
      expect(
        SynchronizationService.isValidUrl('https://example.invalid'),
        isTrue,
      );
      expect(
        SynchronizationService.isValidUrl('http://example.invalid/api'),
        isTrue,
      );
      expect(SynchronizationService.isValidUrl('example.invalid'), isFalse);
      expect(SynchronizationService.isValidUrl('/api'), isFalse);
      expect(SynchronizationService.isValidUrl(''), isFalse);
    });
  });

  group('when synchronization is disabled', () {
    test('every endpoint returns null without touching the network', () async {
      expect(
        await SynchronizationService().synchronizeFolders(<Folder>[]),
        isNull,
      );
      expect(
        await SynchronizationService().synchronizeCounters(<Counter>[]),
        isNull,
      );
      expect(
        await SynchronizationService().synchronizeDeletedFolders(<int>[]),
        isNull,
      );
      expect(
        await SynchronizationService().synchronizeDeletedCounters(<int>[]),
        isNull,
      );
      expect(
        await SynchronizationService().synchronizeCountersCount(<Count>[]),
        isNull,
      );
      expect(await SynchronizationService().recoverData(), isNull);

      expect(requests, isEmpty);
    });
  });

  group('when synchronization is enabled', () {
    setUp(() {
      SynchronizationService().setApiUrl(apiUrl: apiUrl, apiAccessToken: token);
    });

    test(
      'sends counters to the counters endpoint with a bearer token',
      () async {
        final Counter counter = Counter(id: 2, name: 'Verses', counterCount: 7);

        final http.Response? response = await SynchronizationService()
            .synchronizeCounters(<Counter>[counter]);

        expect(response?.statusCode, 200);
        expect(requests, hasLength(1));
        expect(requests.single.method, 'POST');
        expect(requests.single.url.toString(), '$apiUrl/counters/synchronize');
        expect(requests.single.headers['Authorization'], 'Bearer $token');
        final List<dynamic> sent = jsonDecode(requests.single.body);
        expect(sent.single['name'], 'Verses');
        expect(sent.single['counterCount'], 7);
      },
    );

    test('sends folders to the folders endpoint', () async {
      await SynchronizationService().synchronizeFolders(<Folder>[
        Folder(id: 2, name: 'Work'),
      ]);

      expect(requests.single.url.toString(), '$apiUrl/folders/synchronize');
    });

    test('sends deletions as DELETE requests carrying the ids', () async {
      await SynchronizationService().synchronizeDeletedCounters(<int>[4, 5]);

      expect(requests.single.method, 'DELETE');
      expect(requests.single.url.toString(), '$apiUrl/counters/delete');
      expect(jsonDecode(requests.single.body), <int>[4, 5]);
    });

    test('sends counts to the count endpoint', () async {
      await SynchronizationService().synchronizeCountersCount(<Count>[
        Count(counterId: 2, count: 9),
      ]);

      expect(
        requests.single.url.toString(),
        '$apiUrl/counters/count/synchronize',
      );
      final List<dynamic> sent = jsonDecode(requests.single.body);
      expect(sent.single['counterId'], 2);
      expect(sent.single['count'], 9);
    });

    test('recoverData parses the payload into folders and counters', () async {
      stubClient(
        body: jsonEncode(<String, dynamic>{
          'folders': <Map<String, dynamic>>[
            <String, dynamic>{'id': 2, 'name': 'Work'},
          ],
          'counters': <Map<String, dynamic>>[
            <String, dynamic>{'id': 3, 'name': 'Verses', 'counterCount': 4},
          ],
        }),
      );

      final recovered = await SynchronizationService().recoverData();

      expect(requests.single.method, 'GET');
      expect(requests.single.url.toString(), '$apiUrl/users/recover');
      expect(recovered?.folders?.single.name, 'Work');
      expect(recovered?.counters?.single.name, 'Verses');
    });

    test('throws on an error status so the caller can report it', () async {
      stubClient(status: 401, body: 'unauthorized');

      expect(
        () => SynchronizationService().synchronizeCounters(<Counter>[
          Counter(id: 2),
        ]),
        throwsA(isA<Exception>()),
      );
    });

    test('swallows an error status when the caller opted out', () async {
      stubClient(status: 500, body: 'boom');

      final http.Response? response = await SynchronizationService().post(
        '$apiUrl/counters/synchronize',
        body: <int>[],
        ignoreErrors: true,
      );

      expect(response, isNull);
    });

    test('rethrows a transport failure', () async {
      SynchronizationService().client = MockClient((
        http.Request request,
      ) async {
        throw http.ClientException('connection refused');
      });

      expect(
        () => SynchronizationService().synchronizeFolders(<Folder>[
          Folder(id: 2),
        ]),
        throwsA(isA<http.ClientException>()),
      );
    });
  });
}
