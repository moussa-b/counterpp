import 'dart:convert';

import 'package:http/http.dart' as http;

/// Service to send emails via Mailgun
class MailService {
  // Mailgun configuration
  static const String _baseUrl = 'https://api.mailgun.net';

  // For EU domains, use: 'https://api.eu.mailgun.net'
  // static const String _baseUrl = 'https://api.eu.mailgun.net';

  /// Sends an email via Mailgun
  ///
  /// [apiKey]: Your Mailgun API key
  /// [domain]: Your Mailgun domain (e.g., "sandbox12345ed9800XXXXX97a1c91eYYYYY.mailgun.org")
  /// [from]: The sender email address (e.g., "Name <email@domain.com>")
  /// [to]: List of recipients
  /// [subject]: The email subject
  /// [text]: The email content as plain text
  /// [html]: (Optional) The email content as HTML
  static Future<void> sendEmail({
    required String apiKey,
    required String domain,
    required String from,
    required List<String> to,
    required String subject,
    String? text,
    String? html,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/v3/$domain/messages');

      // Basic Auth authentication (username: "api", password: API_KEY)
      final credentials = base64Encode(utf8.encode('api:$apiKey'));

      // Prepare multipart/form-data
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Basic $credentials'
        ..fields['from'] = from
        ..fields['subject'] = subject;

      // Add recipients
      for (final recipient in to) {
        request.fields['to'] = recipient;
      }

      // Add content
      if (text != null) {
        request.fields['text'] = text;
      }
      if (html != null) {
        request.fields['html'] = html;
      }

      // Send the request (fire and forget, we don't wait for or handle the response)
      request.send();
    } catch (e) {
      // Ignore errors if we're not interested in the response
      // If you want to log errors, uncomment the line below:
      // print('Error sending email: $e');
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
  static Future<void> sendSimpleMessage({
    required String apiKey,
    required String domain,
    required String recipientEmail,
    required String recipientName,
    required String subject,
    required String text,
  }) async {
    await sendEmail(
      apiKey: apiKey,
      domain: domain,
      from: 'Mailgun Sandbox <postmaster@$domain>',
      to: ['$recipientName <$recipientEmail>'],
      subject: subject,
      text: text,
    );
  }
}
