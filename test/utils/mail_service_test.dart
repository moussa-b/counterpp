import 'package:counter/utils/mail_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<http.Request> requests;

  http.Client stubClient({int status = 200}) {
    requests = <http.Request>[];
    return MockClient((http.Request request) async {
      requests.add(request);
      return http.Response('{"id":"<msg>"}', status);
    });
  }

  test('sends every recipient, not just the last one', () async {
    // Regression: the recipients were assigned in a loop over a single
    // multipart field, so each one overwrote the previous and only the last
    // address ever received the mail. The developer address, listed first,
    // never got a single error report.
    final http.Client client = stubClient();

    final bool sent = await MailService.sendEmail(
      apiKey: 'key-123',
      domain: 'mg.example.invalid',
      from: 'Counter++ <postmaster@mg.example.invalid>',
      to: <String>['dev@example.invalid', 'support@example.invalid'],
      subject: 'Counter++ - Error',
      text: 'boom',
      client: client,
    );

    expect(sent, isTrue);
    expect(requests, hasLength(1));
    expect(
      requests.single.body,
      contains('dev@example.invalid,support@example.invalid'),
    );
  });

  test('waits for the request instead of firing and forgetting', () async {
    // The previous implementation never awaited send(), so the caller's await
    // returned before anything left the device.
    bool handlerCompleted = false;
    final http.Client client = MockClient((http.Request request) async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      handlerCompleted = true;
      return http.Response('ok', 200);
    });

    await MailService.sendEmail(
      apiKey: 'key-123',
      domain: 'mg.example.invalid',
      from: 'Counter++ <postmaster@mg.example.invalid>',
      to: <String>['dev@example.invalid'],
      subject: 'subject',
      text: 'body',
      client: client,
    );

    expect(handlerCompleted, isTrue);
  });

  test('targets the Mailgun messages endpoint with basic auth', () async {
    final http.Client client = stubClient();

    await MailService.sendEmail(
      apiKey: 'key-123',
      domain: 'mg.example.invalid',
      from: 'Counter++ <postmaster@mg.example.invalid>',
      to: <String>['dev@example.invalid'],
      subject: 'subject',
      text: 'body',
      client: client,
    );

    expect(
      requests.single.url.toString(),
      'https://api.eu.mailgun.net/v3/mg.example.invalid/messages',
    );
    // base64('api:key-123')
    expect(requests.single.headers['Authorization'], 'Basic YXBpOmtleS0xMjM=');
  });

  test(
    'reports failure on an error status rather than claiming success',
    () async {
      final http.Client client = stubClient(status: 401);

      final bool sent = await MailService.sendEmail(
        apiKey: 'wrong',
        domain: 'mg.example.invalid',
        from: 'Counter++ <postmaster@mg.example.invalid>',
        to: <String>['dev@example.invalid'],
        subject: 'subject',
        text: 'body',
        client: client,
      );

      expect(sent, isFalse);
    },
  );

  test('reports failure on a transport error without throwing', () async {
    final http.Client client = MockClient((http.Request request) async {
      throw http.ClientException('connection refused');
    });

    final bool sent = await MailService.sendEmail(
      apiKey: 'key-123',
      domain: 'mg.example.invalid',
      from: 'Counter++ <postmaster@mg.example.invalid>',
      to: <String>['dev@example.invalid'],
      subject: 'subject',
      text: 'body',
      client: client,
    );

    expect(sent, isFalse);
  });

  test('refuses to send with no recipient', () async {
    final http.Client client = stubClient();

    final bool sent = await MailService.sendEmail(
      apiKey: 'key-123',
      domain: 'mg.example.invalid',
      from: 'Counter++ <postmaster@mg.example.invalid>',
      to: const <String>[],
      subject: 'subject',
      text: 'body',
      client: client,
    );

    expect(sent, isFalse);
    expect(requests, isEmpty);
  });
}
