import 'dart:convert';

import 'package:http/http.dart' as http;

/// Service to send emails via Mailgun
class MailService {
  // Mailgun configuration
  static const String _baseUrl = 'https://api.eu.mailgun.net';

  // For EU domains, use: 'https://api.eu.mailgun.net'
  // static const String _baseUrl = 'https://api.eu.mailgun.net';

  /// Sends an email via Mailgun
  ///
  /// [apiKey]: Your Mailgun API key
  /// [domain]: Your Mailgun domain (e.g., "sandbox12345ed9800XXXXX97a1c91eYYYYY.mailgun.org")
  /// [from]: The sender email address (e.g., `Name <email@domain.com>`)
  /// [to]: List of recipients
  /// [subject]: The email subject
  /// [text]: The email content as plain text
  /// [html]: (Optional) The email content as HTML
  /// [client]: (Optional) HTTP client override, used by tests
  /// Returns true when Mailgun accepted the message.
  ///
  /// Mail delivery is best-effort diagnostics, so failures are swallowed rather
  /// than propagated, but the caller gets a boolean instead of a lie.
  static Future<bool> sendEmail({
    required String apiKey,
    required String domain,
    required String from,
    required List<String> to,
    required String subject,
    String? text,
    String? html,
    http.Client? client,
  }) async {
    if (to.isEmpty) {
      return false;
    }
    final http.Client httpClient = client ?? http.Client();
    try {
      final uri = Uri.parse('$_baseUrl/v3/$domain/messages');

      // Basic Auth authentication (username: "api", password: API_KEY)
      final credentials = base64Encode(utf8.encode('api:$apiKey'));

      // Prepare multipart/form-data
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Basic $credentials'
        ..fields['from'] = from
        // Mailgun takes every recipient in a single comma-separated field;
        // assigning in a loop would keep only the last one.
        ..fields['to'] = to.join(',')
        ..fields['subject'] = subject;

      // Add content
      if (text != null) {
        request.fields['text'] = text;
      }
      if (html != null) {
        request.fields['html'] = html;
      }

      final http.StreamedResponse response = await httpClient.send(request);
      // Drain the body so the connection can be reused or closed cleanly.
      await response.stream.drain<void>();
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      return false;
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  /// Sends a simple email with default sandbox parameters
  ///
  /// [apiKey]: Your Mailgun API key
  /// [domain]: Your Mailgun domain (e.g., "sandbox94ed980031d9408f897a1c91e06f328d.mailgun.org")
  /// [recipientEmail]: The recipient's email address
  /// [recipientName]: The recipient's name
  /// [subject]: The email subject
  /// [text]: The email content as plain text
  static Future<bool> sendSimpleMessage({
    required String apiKey,
    required String domain,
    required String recipientEmail,
    required String recipientName,
    required String subject,
    required String text,
  }) async {
    return sendEmail(
      apiKey: apiKey,
      domain: domain,
      from: 'Mailgun Sandbox <postmaster@$domain>',
      to: ['$recipientName <$recipientEmail>'],
      subject: subject,
      text: text,
    );
  }
}
